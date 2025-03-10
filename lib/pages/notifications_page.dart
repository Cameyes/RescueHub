import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/service/language_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Stream<QuerySnapshot> notificationsStream;

  Map<String, bool> reviewedVolunteers = {};

  @override
  void initState() {
    super.initState();
    notificationsStream = FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: widget.userId)
        //.orderBy("timestamp", descending: true)
        .snapshots();
  }

  Future<bool> _hasUserReviewedVolunteer(String volunteerId, String userId) async {
  try {
    // First get the volunteer document by userId
    final volunteersQuery = await FirebaseFirestore.instance
        .collection('volunteer')
        .where('userId', isEqualTo: volunteerId)
        .limit(1)
        .get();
    
    if (volunteersQuery.docs.isEmpty) {
      return false;
    }
    
    // Get the first matching volunteer document
    final volunteerDoc = volunteersQuery.docs.first;
    
    // Check if there's a review by the current user
    final reviewDocs = await volunteerDoc.reference
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
        
    return reviewDocs.docs.isNotEmpty;
  } catch (e) {
    debugPrint('Error checking review status: $e');
    return false;
  }
}
  Future<Map<String, dynamic>> _getTrackingInfo(String origin, String destination) async {
  try {
    final apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc';
    final url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin'
        '&destination=$destination'
        '&mode=driving'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final route = data['routes'][0]['legs'][0];
        return {
          'distance': route['distance']['text'],
          'duration': route['duration']['text'],
        };
         }
    }
    throw Exception('Failed to fetch route information');
  } catch (e) {
    print('Error getting tracking info: $e');
    return {
      'distance': 'Unknown',
      'duration': 'Unknown',
    };
  }
}

  Future<void> _launchTrackingMap(String origin, String destination) async {
  final url = 'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$destination'
      '&travelmode=driving';
      
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw Exception('Could not launch map');
  }
}

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing notification: $e')),
      );
    }
  }

  Widget _buildNotificationContent(Map<String, dynamic> notification) {
    
    

    // Special handling for volunteer request notifications
    if (notification['type'] == 'volunteer_request') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(notification['message']),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _handleVolunteerResponse(notification['requestId'], false),
                child: const Text('Decline'),
              ),
              ElevatedButton(
                onPressed: () => _handleVolunteerResponse(notification['requestId'], true),
                child: const Text('Accept'),
              ),
               ],
          ),
        ],
      );
    }

     // Handle OTP verification for volunteer
  else if (notification['type'] == 'shelter_approved_verify') {
    final TextEditingController otpController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification['title'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(notification['message']),
        const SizedBox(height: 12),
         // Tracking info
        FutureBuilder<Map<String, dynamic>>(
          future: _getTrackingInfo(
            notification['coordinates'],
            notification['targetCoordinates']
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ETA: ${snapshot.data!['duration']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.directions_car, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Distance: ${snapshot.data!['distance']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _launchTrackingMap(
                      notification['coordinates'],
                      notification['targetCoordinates']
                    ),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Track Requester'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // OTP verification section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Requester',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter verification code',
                  border: OutlineInputBorder(),
                  hintText: '4-digit code',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
               const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _verifyOTP(
                    otpController.text,
                    notification['shelterId'],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Verify Code'),
                ),
              ),
            ],
          ),
           ),
      ],
    );
  }

  // Handle OTP display for requester
  else if (notification['type'] == 'otp_notification') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification['title'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'Your Verification Code',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notification['verificationCode'],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Show this code to your volunteer when they arrive',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }




    else if (notification['type'] == 'shelter_approved') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification['title'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(notification['message']),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _getTrackingInfo(
            notification['coordinates'], 
            notification['targetCoordinates']
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ETA: ${snapshot.data!['duration']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.directions_car, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Distance: ${snapshot.data!['distance']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _launchTrackingMap(
                      notification['coordinates'],
                      notification['targetCoordinates']
                    ),
                     icon: const Icon(Icons.location_on),
                    label: const Text('Track Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Add this else if block in the _buildNotificationContent method
else if (notification['type'] == 'volunteer_pickup_confirmed') {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        notification['title'],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(notification['message']),
      const SizedBox(height: 12),
      FutureBuilder<Map<String, dynamic>>(
        future: _getTrackingInfo(
          notification['coordinates'],
          notification['targetCoordinates']
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ${snapshot.data!['duration']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.directions_car, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Distance: ${snapshot.data!['distance']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchTrackingMap(
                          notification['coordinates'],
                          notification['targetCoordinates']
                        ),
                        icon: const Icon(Icons.location_on),
                        label: const Text('Track Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            // Decode address for the notification
                            final decodedAddress = await _getDecodedAddress(notification['targetCoordinates']);
                            
                           
                            
                            // Send completion notification to requester
                            await FirebaseFirestore.instance.collection('notifications').add({
                              'userId': notification['requesterId'],
                              'title': 'Destination Reached',
                              'message': 'You have been volunteered safely to ${notification['shelterName']}, $decodedAddress',
                              'type': 'volunteer_completed',
                              'volunteerId': notification['volunteerId'],
                              'requesterId': notification['requesterId'],
                              'shelterName': notification['shelterName'],
                              'coordinates': notification['coordinates'],
                              'targetCoordinates': notification['targetCoordinates'],
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                            // Remove current notification
                            if (notification['notificationId'] != null) {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notification['notificationId'])
                                  .delete();
                            }

                            // Show success toast
                            Fluttertoast.showToast(
                              msg: "Destination reached successfully!",
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                              gravity: ToastGravity.BOTTOM,
                              toastLength: Toast.LENGTH_LONG,
                            );

                            
                          } catch (e) {
                            print('Error marking destination reached: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error updating status. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Reached Destination'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

else if (notification['type'] == 'volunteer_completed') {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        notification['title'],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(notification['message']),
      const SizedBox(height: 16),
      // Only show review button if this is the requester's notification
      if (widget.userId == notification['requesterId'])
        FutureBuilder<bool>(
          future: _hasUserReviewedVolunteer(
            notification['volunteerId'],
            widget.userId
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final hasReviewed = snapshot.data ?? false;

             if (hasReviewed) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'You have already reviewed this volunteer',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }
             return ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _buildReviewDialog(
                    context,
                    notification['volunteerId']
                  ),
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('Rate Your Volunteer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 36),
                ),
            );
          },
        ),
    ],
  );
}



  
    // Regular notification display
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification['title'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(notification['message']),
      ],
    );
  }

  Future<void> _handleVolunteerResponse(String requestId, bool accepted) async {
    try {
      // Update the volunteer request status
      await FirebaseFirestore.instance
          .collection('volunteerRequests')
          .doc(requestId)
          .update({
        'status': accepted ? 'accepted' : 'declined',
        'responseTime': FieldValue.serverTimestamp(),
      });

      // Delete the notification
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('requestId', isEqualTo: requestId)
          .get();
          for (var doc in notifications.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted 
            ? 'You have accepted the request' 
            : 'You have declined the request'
          ),
        ),
      );
    } catch (e) {
      print('Error handling volunteer response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error processing your response. Please try again.'),
        ),
      );
    }
  }

  Future<String> _getDecodedAddress(String coordinates) async {
  try {
    final coords = coordinates.split(',');
    double lat = double.parse(coords[0].trim());
    double lng = double.parse(coords[1].trim());
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      return "${place.subLocality}, ${place.locality}";
    }
    return "Unknown location";
  } catch (e) {
    return "Location unavailable";
  }
}

Future<void> _removeExistingNotifications(String requesterId, String volunteerId) async {
  final batch = FirebaseFirestore.instance.batch();
  
  final requesterNotifications = await FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: requesterId)
      .get();
      
  final volunteerNotifications = await FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: volunteerId)
      .get();

  for (var doc in [...requesterNotifications.docs, ...volunteerNotifications.docs]) {
    batch.delete(doc.reference);
  }

  await batch.commit();
}

Future<void> _sendUpdatedNotifications(
  Map<String, dynamic> shelterData,
  String volunteerName,
  String requesterName,
  String shelterName,
  String decodedAddress
) async {
  // Send notification to requester
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': shelterData['requesterDetails']['userId'],
    'title': 'Volunteer Assigned',
    'message': 'You are now volunteered by $volunteerName to $shelterName, $decodedAddress',
    'type': 'volunteer_assigned',
    'volunteerId': shelterData['volunteerDetails']['userId'], // Add this
    'requesterId': shelterData['requesterDetails']['userId'], // Add this
    'timestamp': FieldValue.serverTimestamp(),
  });

  // Send notification to volunteer
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': shelterData['volunteerDetails']['userId'],
    'title': 'Requester Pickup Confirmed',
    'message': 'You have picked up $requesterName and are dropping at $shelterName, $decodedAddress',
    'type': 'volunteer_pickup_confirmed',
    'coordinates': shelterData['requesterDetails']['coordinates'],
    'targetCoordinates': shelterData['donorDetails']['coordinates'],
    'shelterId': shelterData['shelterDetails']['shelterId'],
    'volunteerId': shelterData['volunteerDetails']['userId'], // Add this
    'requesterId': shelterData['requesterDetails']['userId'], // Add this
    'shelterName': shelterName, // Add this
    'timestamp': FieldValue.serverTimestamp(),
  });
}

Widget _buildReviewDialog(BuildContext context, String volunteerId) {
  int rating = 5;
  final reviewController = TextEditingController();

  return AlertDialog(
    title: const Text('Rate Your Volunteer'),
    content: StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                labelText: 'Write your review (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        );
      },
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Skip'),
      ),
      ElevatedButton(
        onPressed: () async {
           try {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) throw Exception('No user logged in');

            //debugPrint(currentUser.uid);

             // Query for the volunteer document where userId equals currentUser.uid
              final volunteersQuery = await FirebaseFirestore.instance
                  .collection('volunteer')
                  .where('userId', isEqualTo: currentUser.uid)
                  .limit(1)
                  .get();
            
                    if (volunteersQuery.docs.isEmpty) {
              throw Exception('Volunteer document not found');
            }

            // Get the first matching volunteer document
            final volunteerDoc = volunteersQuery.docs.first;
            final volunteerRef = volunteerDoc.reference;

            // Add review as subcollection under the volunteer document
            await volunteerRef
                .collection('reviews')
                .doc() // Firestore will generate a unique ID
                .set({
                  'rating': rating,
                  'reviewText': reviewController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                  'userId': currentUser.uid,
                  'reviewerName': currentUser.displayName ?? 'Anonymous',
                });

            if (context.mounted) {
              Navigator.pop(context);

              setState(() {
                reviewedVolunteers[volunteerId] = true;
              });
              Fluttertoast.showToast(
                msg: "Review submitted successfully!",
                backgroundColor: Colors.green,
                textColor: Colors.white,
                gravity: ToastGravity.BOTTOM,
              );
            }
          } catch (e) {
            print('Error submitting review: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error submitting review: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: const Text('Submit'),
      ),
    ],
  );
}

  Future<void> _verifyOTP(String enteredOTP, String shelterId) async {
  try {
    final verificationDoc = await FirebaseFirestore.instance
        .collection('shelterVerification')
        .doc(shelterId)
        .get();

    if (!verificationDoc.exists) {
      throw Exception('Verification data not found');
    }

    final data = verificationDoc.data()!;
    final correctOTP = data['otp'] as String;

    if (enteredOTP == correctOTP) {
      // Get shelter and volunteer details
      final shelterSnapshot = await FirebaseFirestore.instance
          .collection('adminShelterDetails')
          .doc(shelterId)
          .get();

          final shelterData = shelterSnapshot.data()!;
      final volunteerName = shelterData['volunteerDetails']['name'];
      final requesterName = shelterData['requesterDetails']['name'];
      final shelterName = shelterData['shelterDetails']['houseName'];
      final shelterCoords = shelterData['donorDetails']['coordinates'];

      // Get decoded shelter address
      final decodedAddress = await _getDecodedAddress(shelterCoords);

      // Update verification status
      await verificationDoc.reference.update({
        'verified': true,
        'verificationTime': FieldValue.serverTimestamp(),
      });

      // Remove existing notifications for both parties
      await _removeExistingNotifications(
        shelterData['requesterDetails']['userId'],
        shelterData['volunteerDetails']['userId']
      );

      // Send new notifications
      await _sendUpdatedNotifications(
        shelterData,
        volunteerName,
        requesterName,
        shelterName,
        decodedAddress
      );

      // Show success toast
      Fluttertoast.showToast(
        msg: "Verification successful!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_LONG,
      );

    }

    else {
      // Increment attempt counter
      await verificationDoc.reference.update({
        'attempts': FieldValue.increment(1),
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect code. Please try again.')),
      );
    }
  } catch (e) {
    print('Error verifying OTP: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error verifying code. Please try again.')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        title: Center(
          child: Text(
            languageProvider.translations['notifications'] ?? "Notifications",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: themeProvider.isDarkMode 
          ? Colors.grey.shade800 
          : const Color.fromARGB(255, 170, 245, 245),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                languageProvider.translations['notifyempty'] ?? "You have no new notifications!",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Dismissible(
                  key: Key(notificationId),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteNotification(notificationId);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                          ? Colors.grey.shade700 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildNotificationContent(notification),
                  ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}