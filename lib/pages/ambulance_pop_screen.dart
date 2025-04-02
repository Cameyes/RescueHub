import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AmbulancePopScreen extends StatefulWidget {
   final DocumentSnapshot ambulanceData;
  const AmbulancePopScreen({super.key,required this.ambulanceData});

  @override
  State<AmbulancePopScreen> createState() => _AmbulancePopScreenState();
}

class _AmbulancePopScreenState extends State<AmbulancePopScreen> {

  String address = "Loading...";
  final TextEditingController _reviewController = TextEditingController();
  int selectedRating = 5;

    @override
  void initState() {
    super.initState();
    _getAddress();
  }

  Future<double> _calculateDistance(String location1, String location2) async {
  try {
    // Parse the coordinates
    List<String> coords1 = location1.split(',');
    List<String> coords2 = location2.split(',');
    
    double lat1 = double.parse(coords1[0].trim());
    double lng1 = double.parse(coords1[1].trim());
    double lat2 = double.parse(coords2[0].trim());
    double lng2 = double.parse(coords2[1].trim());

    // Google Maps Directions API request
    String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc';
    String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$lat1,$lng1'
        '&destination=$lat2,$lng2'
        '&mode=driving'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      
      if (data['status'] != 'OK') {
        throw Exception('Directions API error: ${data['status']}');
      }

      if (data['routes'].isEmpty) {
        throw Exception('No route found');
      }

      // Get the distance in meters and convert to kilometers
      var route = data['routes'][0]['legs'][0];
      var distanceInMeters = route['distance']['value'];
      return distanceInMeters / 1000.0; // Convert to kilometers
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode}');
    }
  } catch (e) {
    print('Error calculating distance: $e');
    return 0.0;
  }
}
  
  Future<void> _getAddress() async {
    try {
      final coords = widget.ambulanceData["Address"].toString().split(',');
      if (coords.length != 2) {
        setState(() {
          address = "Invalid coordinates";
        });
        return;
      }

      double lat = double.parse(coords[0].trim());
      double lng = double.parse(coords[1].trim());

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          address = "${place.street}, ${place.subLocality}, "
              "${place.locality}, ${place.postalCode}";
        });
      }
    } catch (e) {
      setState(() {
        address = "Could not fetch address";
      });
    }
  }


  Widget _buildInfoRow(String label, String value, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAmbulanceBooking(BuildContext context, DocumentSnapshot ambulanceData) async {
  try {
    // Get current user details
    final currentUser = FirebaseAuth.instance.currentUser;
    final userProfile = await FirebaseFirestore.instance
        .collection('Profile')
        .doc(currentUser?.uid)
        .get();

    // Get first available ambulance driver
    final driversSnapshot = await FirebaseFirestore.instance
        .collection('ambulance')
        .where('status', isEqualTo: 'active')
        .get();

    if (driversSnapshot.docs.isEmpty) {
      throw Exception('No ambulance drivers available');
    }

    // Create booking data
    final bookingData = {
      'ambulanceDetails': {
        'driverId': ambulanceData['id'],
        'driverName': ambulanceData['name'],
        'licenseType': ambulanceData['lictype'],
        'experience': ambulanceData['experience'],
        'ambAvailability': ambulanceData['ambAvail'],
        'coordinates': ambulanceData['Address'],
        'description':ambulanceData['description'],
        'licence': ambulanceData['licencePDF'],
      },
      'requesterDetails': {
        'userId': currentUser?.uid,
        'name': userProfile['Name'],
        'contact': userProfile['Contact'],
        'coordinates': userProfile['location'],
        'profileImage': userProfile['Image'] ?? '',
        'age': userProfile['Age'],
        'gender': userProfile['Gender'],
        'Address': userProfile['Address'],
      },
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'district': ambulanceData['location'],
      'emergencyType': 'medical', // You can add more types if needed
      'distance':ambulanceData['distance'],
    };

    // Show waiting toast
    Fluttertoast.showToast(
      msg: "Requesting ambulance service...",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );

    // Start ambulance driver request process
    bool driverFound = await _requestAmbulanceDriver(
      bookingData, 
      driversSnapshot.docs, 
      0
    );

    if (!driverFound) {

      //Reset Driver Status if no Driver Accepts
      await FirebaseFirestore.instance
          .collection('ambulance')
          .doc(ambulanceData.id)
          .update({'status': 'active'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ambulance drivers available at the moment. Please try again later.')),
      );
      return;
    }
    
    // If driver accepts, show success message
    Fluttertoast.showToast(
      msg: "Ambulance service has been requested",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );

    //Update Driver Status to booked
    await FirebaseFirestore.instance
        .collection('ambulance')
        .doc(ambulanceData.id)
        .update({'status': 'booked'});

    // Add to adminAmbulanceDetails
    await FirebaseFirestore.instance
        .collection('adminAmbulanceDetails')
        .add(bookingData);

    // Add notification
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': currentUser!.uid,
      'title': 'Ambulance Request Pending',
      'message': 'Your ambulance request is waiting for ${ambulanceData['location']} Coordinator approval.',
      'timestamp': Timestamp.now(),
      'status': 'pending',
      'type': 'shelter_booking',
      'sound': 'notification_sound.mp3', // Add sound effect
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ambulance request sent successfully')),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

Future<bool> _requestAmbulanceDriver(Map<String, dynamic> bookingData, List<DocumentSnapshot> drivers, int currentIndex) async {
  if (currentIndex >= drivers.length) {
    return false; // No more drivers to try
  }

  DocumentSnapshot driverDoc = drivers[currentIndex];
  final driverId = driverDoc['userId'];

  // Calculate distance between driver and requester
  String requesterName = bookingData['requesterDetails']['name'];
  String driverLocation = driverDoc['Address'];
  String requesterLocation = bookingData['requesterDetails']['coordinates'];
  double distance = await _calculateDistance(driverLocation, requesterLocation);

  // Create driver request notification
  final requestRef = await FirebaseFirestore.instance
      .collection('ambulanceRequests')
      .add({
    'driverId': driverId,
    'requesterId': bookingData['requesterDetails']['userId'],
    'requesterName': bookingData['requesterDetails']['name'],
    'requesterContact': bookingData['requesterDetails']['contact'],
    'requesterAddress': bookingData['requesterDetails']['Address'],
    'distance': distance,
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
    'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 2))),
    'bookingData': bookingData,
  });

  // Send notification to driver with sound
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': driverId,
    'title': 'New Ambulance Service Request',
    'message': 'A person named $requesterName needs ambulance service',
    'type': 'ambulance_request',
    'requestId': requestRef.id,
    'timestamp': FieldValue.serverTimestamp(),
    'expiresIn': 2, // minutes
    'sound': 'emergency_sound.mp3', // Add emergency sound
  });

  // Wait for driver response
  try {
    bool accepted = await _waitForDriverResponse(requestRef.id);
    if (accepted) {
      // Update booking data with driver info
      bookingData['driverDetails'] = {
        'userId': driverId,
        'name': driverDoc['name'],
        'contact': driverDoc['contact'],
        'address': driverDoc['Address'],
        'experience': driverDoc['experience'],
        'licenseType': driverDoc['lictype'],
        'profileImage': driverDoc['profileImage'],
        'Gender':driverDoc['gender'],
        'Age':driverDoc['age'],
        'Contact':driverDoc['contact'],
      };

      // Notify requester
      await _notifyRequester(
        bookingData['requesterDetails']['userId'],
        bookingData['ambulanceDetails']['driverName'],
        bookingData['district'],
      );

      // Notify driver
      await _notifyDriver(
        driverId,
        bookingData['requesterDetails']['name'],
        bookingData['district']
      );

      return true;
    } else {
      // Try next driver
      return await _requestAmbulanceDriver(bookingData, drivers, currentIndex + 1);
    }
  } catch (e) {
    print('Error in ambulance request: $e');
    return false;
  }
}

Future<void> _notifyRequester(String requesterId, String driverName, String location) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': requesterId,
    'title': 'Ambulance Driver Assigned',
    'message': 'Driver $driverName has accepted your request and is waiting for $location Coordinator approval.',
    'timestamp': FieldValue.serverTimestamp(),
    'type': 'ambulance_driver_assigned',
  });
}

Future<void> _notifyDriver(String driverId, String requesterName, String location) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': driverId,
    'title': 'Request Pending Approval',
    'message': 'You have accepted to help $requesterName. You will be notified once the request is approved by $location Coordinator.',
    'timestamp': FieldValue.serverTimestamp(),
    'type': 'ambulance_pending_approval',
    'sound': 'notification_sound.mp3',
  });
}

Future<bool> _waitForDriverResponse(String requestId) async {
  try {
    // Wait for up to 2 minutes for driver response
    DateTime expiry = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(expiry)) {
      DocumentSnapshot request = await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .doc(requestId)
          .get();

      if (!request.exists) return false;
      
      String status = request['status'];
      if (status == 'accepted') return true;
      if (status == 'rejected') return false;

      await Future.delayed(const Duration(seconds: 5));
    }
    return false;
  } catch (e) {
    print('Error waiting for driver response: $e');
    return false;
  }
}




  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final cardColor = themeProvider.isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[850] : Colors.blue,
        title:  Text(
          "Ambulance Driver Profile",
          style: TextStyle(
            color: themeProvider.isDarkMode?Colors.white:Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.blue,
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: Hero(
                  tag: 'ambulance_${widget.ambulanceData.id}',
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.ambulanceData["profileImage"].isNotEmpty
                          ? (widget.ambulanceData["profileImage"].startsWith('/data')
                              ? Image.file(
                                  File(widget.ambulanceData["profileImage"][0]),
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  widget.ambulanceData["profileImage"],
                                  fit: BoxFit.cover,
                                ))
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30,),
                  Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius:  BorderRadius.circular(12),
                    ),
                    child: Padding(padding:  const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.ambulanceData["name"],
                          style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow("Age", "${widget.ambulanceData["age"]} years", themeProvider),
                            _buildInfoRow("Location", address, themeProvider),
                            _buildInfoRow(
                              "Joined",
                              "${widget.ambulanceData["createdAt"]["date"]} at ${widget.ambulanceData["createdAt"]["time"]}",
                              themeProvider,
                            ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 80,
                    child: Card(
                      color: cardColor,
                      elevation: 2,
                      child: Center(
                        child: Text(
                          " I have ${widget.ambulanceData["ambAvail"]} and  a ${widget.ambulanceData["lictype"]} Licence with ${widget.ambulanceData["experience"]} years \n of Experience",
                          style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "About",
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.ambulanceData["description"],
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Reviews",
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection('Profile')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .collection('ambulanceReviews')
                                  .where('userId', isEqualTo:FirebaseAuth.instance.currentUser?.uid)
                                  //.orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      "No reviews yet",
                                      style: TextStyle(
                                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.docs.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final review = snapshot.data!.docs[index];
                                    return FutureBuilder(
                                      future: FirebaseFirestore.instance
                                            .collection('Profile')
                                            .doc(review['userId'])
                                            .get(),
                                       
                                      builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                                        if (!userSnapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        final profileData = userSnapshot.data!.data() as Map<String, dynamic>;
                                        
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundImage: profileData['Image'] != null
                                                      ? NetworkImage(profileData['Image'])
                                                      : const AssetImage('lib/images/default_profile.png')
                                                          as ImageProvider,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        profileData['Name'] ?? 'Unknown User',
                                                        style: TextStyle(
                                                          color: themeProvider.isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          ...List.generate(
                                                            5,
                                                            (starIndex) => Icon(
                                                              starIndex < review['rating']
                                                                  ? Icons.star
                                                                  : Icons.star_border,
                                                              color: starIndex < review['rating']
                                                                  ? Colors.amber
                                                                  : Colors.grey,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            DateFormat.yMMMd().add_jm().format(
                                                                (review['timestamp'] as Timestamp)
                                                                    .toDate()),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: themeProvider.isDarkMode
                                                                  ? Colors.white70
                                                                  : Colors.black54,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              review['reviewText'],
                                              style: TextStyle(
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Write a Review",
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: List.generate(
                                5,(index) => IconButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedRating = index + 1;
                                    });
                                  },
                                  icon: Icon(
                                    index < selectedRating ? Icons.star : Icons.star_border,
                                    color: index < selectedRating ? Colors.amber : Colors.grey,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _reviewController,
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: "Share your experience",
                                labelStyle: TextStyle(
                                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.isDarkMode ? Colors.white24 : Colors.black12,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.isDarkMode ? Colors.blue : Colors.blue,
                                  ),
                                ),
                                filled: true,
                                fillColor: themeProvider.isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.grey[100],
                              ),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            // Replace the existing ElevatedButton with this:
                            SizedBox(
                              height: 40,
                              width: 70,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_reviewController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Review Cannot be Empty")),
                                    );
                                    return;
                                  }
                                  final currentUser = FirebaseAuth.instance.currentUser!;
                                  final existingReview = await FirebaseFirestore.instance
                                      .collection('Profile')
                                      .doc(currentUser.uid)
                                      .collection('ambulanceReviews')
                                      .where('userId', isEqualTo: currentUser.uid)
                                      .get();
                              
                                  if (existingReview.docs.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("You can Only Submit One Review")),
                                    );
                                    return;
                                  }
                              
                                  final reviewData = {
                                    'reviewText': _reviewController.text.trim(),
                                    'rating': selectedRating,
                                    'userId': FirebaseAuth.instance.currentUser?.uid,
                                    'timestamp': Timestamp.now(),
                                  };
                              
                                  await FirebaseFirestore.instance
                                      .collection('Profile')
                                      .doc(FirebaseAuth.instance.currentUser?.uid)
                                      .collection('ambulanceReviews')
                                      .add(reviewData);
                              
                                  _reviewController.clear();
                                  setState(() {
                                    selectedRating = 5;
                                  });
                              
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Review added successfully!")),
                                  );
                                },
                                child: Text(
                                  "Submit Review",
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    GestureDetector(
                              child: Container(
                                height:50,
                                width:double.infinity,
                                decoration:BoxDecoration(
                                  color:themeProvider.isDarkMode?Colors.grey[600]:Colors.blue,
                                  borderRadius:BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Text(
                                    "Request Help",
                                    style: TextStyle(
                                      color: themeProvider.isDarkMode?Colors.white:Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              onTap: (){
                                //Logic for requesting help from Ambulance Drivers
                                _handleAmbulanceBooking(context, widget.ambulanceData);
                              },
                            )
                ],
              ),
              )
          ],
        ),
      ),
    );
  }
}