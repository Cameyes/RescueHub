import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminFoodScreen extends StatefulWidget {
  final String userId;
  final String location;
  const AdminFoodScreen({super.key, required this.userId, required this.location});

  @override
  State<AdminFoodScreen> createState() => _AdminFoodScreenState();
}

class _AdminFoodScreenState extends State<AdminFoodScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<String> hiddenItems = {};
  Set<String> expandedItems = {};
  Map<String, String> addressCache = {};

  String _generateOTP() {
    Random random = Random();
    return (1000 + random.nextInt(9000)).toString(); // Generates number between 1000-9999
  }

  Future<void> _handleApproval(Map<String, dynamic> foodData, String foodId) async {
    try {
      // Generate OTP
      final String otp = _generateOTP();

      // Store OTP in Firestore
      await FirebaseFirestore.instance
          .collection('foodVerification')
          .doc(foodId)
          .set({
        'otp': otp,
        'verified': false,
        'attempts': 0,
        'requesterId': foodData['requesterDetails']['userId'],
        'volunteerId': foodData['volunteerDetails']['userId'],
      });

      // Update volunteer status to busy
      await FirebaseFirestore.instance
          .collection('volunteer')
          .where('userId', isEqualTo: foodData['volunteerDetails']['userId'])
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'currentStat': 'busy',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Send notification to requester
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': foodData['requesterDetails']['userId'],
        'title': 'Food Request Approved - Your Verification Code',
        'message': 'Your food request has been approved. Show this code to your volunteer when they arrive.',
        'verificationCode': otp,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'shelter_approved_with_otp',
        'coordinates': foodData['requesterDetails']['coordinates'],
        'targetCoordinates': foodData['volunteerDetails']['address']
      });

       // Send separate OTP notification to requester
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': foodData['requesterDetails']['userId'],
      'title': 'Verification Code',
      'message': 'Your verification code is: $otp. Share this with your volunteer when they arrive.',
      'verificationCode': otp,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'otp_notification'
    });


      // Send notification to volunteer
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': foodData['volunteerDetails']['userId'],
        'title': 'Food Request Approved - Verify Requester',
        'message': 'The coordinator has approved food request for ${foodData['requesterDetails']['name']}. Ask for their verification code when you meet them.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'food_approved_verify',
        'foodId': foodId,
        'coordinates': foodData['requesterDetails']['coordinates'],
        'targetCoordinates': foodData['donorDetails']['coordinates'],
      });

      // Send notification to donor
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': foodData['donorDetails']['userId'],
        'title': 'Food Booking Approved',
        'message': 'Your food ${foodData['foodDetails']['foodName']} has been booked by ${foodData['requesterDetails']['name']}.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'shelter_approved_donor'
      });

  // Send notification to requester
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': foodData['requesterDetails']['userId'],
      'title': 'Food Request Approved',
      'message': 'Your shelter request has been approved. You can now have ${foodData['foodDetails']['foodName']}.Click below to track Volunteer',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'shelter_approved',
      'coordinates':foodData['requesterDetails']['coordinates'],
      'targetCoordinates':foodData['volunteerDetails']['address']
    });

      // Remove the request from adminFoodDetails
      await FirebaseFirestore.instance
          .collection('adminFoodDetails')
          .doc(foodId)
          .update({
        'status': 'approved',
        'approvalTime': FieldValue.serverTimestamp(),
        'approvedBy': widget.userId,
      });

      // Hide the item from the UI
      setState(() {
        hiddenItems.add(foodId);
      });

      // Show success toast
      Fluttertoast.showToast(
        msg: "Approval has been sent to all corresponding persons",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print('Error in approval process: $e');
      Fluttertoast.showToast(
        msg: "Error processing approval",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }

  // Send notifications to all admins in the same location
final adminsSnapshot = await FirebaseFirestore.instance
    .collection('adminDetails')
    .where('location', isEqualTo: widget.location)  // Filter by location
    .get();

// Get the current admin's name
final currentAdminDoc = await FirebaseFirestore.instance
    .collection('adminDetails')
    .doc(widget.userId)
    .get();
final currentAdminName = currentAdminDoc.data()?['name'] ?? 'An admin';

// Get current time
final now = DateTime.now();
final formattedTime = DateFormat('HH:mm').format(now);

// Send notification to each admin in the location
for (var adminDoc in adminsSnapshot.docs) {
  // Skip sending notification to the admin who approved
  if (adminDoc.id != widget.userId) {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': adminDoc.id,  // Send to each admin's ID
      'title': 'Food Approval Update',
      'message': '$currentAdminName has approved food distribution request at $formattedTime\nRequester: ${foodData['requesterDetails']['name']}\nDonor: ${foodData['donorDetails']['name']}',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'admin_shelter_approval',
      'shelterId': foodId,
      'approvedBy': widget.userId,
      'location': widget.location
    });
  }
}

  }

  Future<void> _handleRejection(Map<String, dynamic> foodData, String foodId) async {
    try {
      // Update volunteer status to free
      await FirebaseFirestore.instance
          .collection('volunteer')
          .where('userId', isEqualTo: foodData['volunteerDetails']['userId'])
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'currentStat': 'free',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Send notification to requester
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': foodData['requesterDetails']['userId'],
        'title': 'Food Request Rejected',
        'message': 'Your food request has been rejected by ${widget.location} Coordinator.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'shelter_rejected'
      });

      // Send notification to volunteer
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': foodData['volunteerDetails']['userId'],
        'title': 'Food Request Rejected',
        'message': 'The food request for ${foodData['requesterDetails']['name']} has been rejected by the coordinator.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'shelter_rejected'
      });

      // Remove the request from adminFoodDetails
      await FirebaseFirestore.instance
          .collection('adminFoodDetails')
          .doc(foodId)
          .delete();

      // Show rejection toast
      Fluttertoast.showToast(
        msg: "The request has been rejected and informed to requested parties",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print('Error in rejection process: $e');
      Fluttertoast.showToast(
        msg: "Error processing rejection",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<String> _getAddress(String coordinates) async {
    if (addressCache.containsKey(coordinates)) {
      return addressCache[coordinates]!;
    }

    try {
      final coords = coordinates.split(',');
      if (coords.length != 2) return "Invalid coordinates";

      double lat = double.parse(coords[0].trim());
      double lng = double.parse(coords[1].trim());
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = " ${place.subLocality}, ${place.locality}";
        addressCache[coordinates] = address;
        return address;
      }
      return "Address not found";
    } catch (e) {
      return "Could not fetch address";
    }
  }

  Future<String> _getAddress_new(String coordinates) async {
    if (addressCache.containsKey(coordinates)) {
      return addressCache[coordinates]!;
    }

    try {
      final coords = coordinates.split(',');
      if (coords.length != 2) return "Invalid coordinates";

      double lat = double.parse(coords[0].trim());
      double lng = double.parse(coords[1].trim());
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = " ${place.subLocality}";
        addressCache[coordinates] = address;
        return address;
      }
      return "Address not found";
    } catch (e) {
      return "Could not fetch address";
    }
  }

  Widget _buildMapView(Map<String, dynamic> foodData) {
    return FutureBuilder<Set<Polyline>>(
      future: _getRoutePolyline(foodData),
      builder: (context, snapshot) {
        final requesterCoords = foodData['requesterDetails']['coordinates'].toString().split(',');
        final donorCoords = foodData['donorDetails']['coordinates'].toString().split(',');

        final requesterLatLng = LatLng(
          double.parse(requesterCoords[0].trim()),
          double.parse(requesterCoords[1].trim())
        );
        final donorLatLng = LatLng(
          double.parse(donorCoords[0].trim()),
          double.parse(donorCoords[1].trim())
        );

        // Calculate the bounds that include both markers
        final double south = min(requesterLatLng.latitude, donorLatLng.latitude);
        final double north = max(requesterLatLng.latitude, donorLatLng.latitude);
        final double west = min(requesterLatLng.longitude, donorLatLng.longitude);
        final double east = max(requesterLatLng.longitude, donorLatLng.longitude);

        // Add padding to the bounds
        final LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(south - 0.05, west - 0.05),
          northeast: LatLng(north + 0.05, east + 0.05),
        );

        return Container(
          height: 250,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (requesterLatLng.latitude + donorLatLng.latitude) / 2,
                  (requesterLatLng.longitude + donorLatLng.longitude) / 2,
                ),
                zoom: 11, // Default zoom level
              ),
              onMapCreated: (GoogleMapController controller) {
                // Zoom to fit both markers when map is created
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 50), // 50 is padding
                );
              },
              markers: {
                Marker(
                  markerId: const MarkerId('requester'),
                  position: requesterLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  infoWindow: const InfoWindow(title: 'Requester Location'),
                ),
                Marker(
                  markerId: const MarkerId('donor'),
                  position: donorLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(title: 'Donor Location'),
                ),
              },
              polylines: snapshot.data ?? {},
            ),
          ),
        );
      }
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    Widget? child,
    bool isFullWidth = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              child ?? Text(
                value ?? "",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
                maxLines: isFullWidth ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Set<Polyline>> _getRoutePolyline(Map<String, dynamic> foodData) async {
    final requesterCoords = foodData['requesterDetails']['coordinates'].toString().split(',');
    final donorCoords = foodData['donorDetails']['coordinates'].toString().split(',');

    final requesterLatLng = LatLng(
      double.parse(requesterCoords[0].trim()),
      double.parse(requesterCoords[1].trim())
    );

    final donorLatLng = LatLng(
      double.parse(donorCoords[0].trim()),
      double.parse(donorCoords[1].trim())
    );
    try {
      String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc';
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${requesterLatLng.latitude},${requesterLatLng.longitude}'
          '&destination=${donorLatLng.latitude},${donorLatLng.longitude}'
          '&mode=driving'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          String encodedPoints = data['routes'][0]['overview_polyline']['points'];
          List<LatLng> points = _decodePolyline(encodedPoints);
          return {
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: Colors.blue,
              width: 5,
            ),
          };
        }
      }
      throw Exception('Failed to fetch directions');
    } catch (e) {
      print('Error getting route: $e');
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [requesterLatLng, donorLatLng],
          color: Colors.blue,
          width: 5,
        ),
      };
    }
  }

  void toggleExpand(String foodId) {
    setState(() {
      if (expandedItems.contains(foodId)) {
        expandedItems.remove(foodId);
      } else {
        expandedItems.add(foodId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('adminFoodDetails')
            .where('district', isEqualTo: widget.location)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No food data found for this location'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var foodData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var foodId = snapshot.data!.docs[index].id;
              bool isExpanded = expandedItems.contains(foodId);

              if (hiddenItems.contains(foodId)) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(isExpanded ? 0 : 12),
                          bottomRight: Radius.circular(isExpanded ? 0 : 12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 30,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${foodData['foodDetails']['fit']} Persons",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        foodData['foodDetails']['type'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ),
                                GestureDetector(
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isExpanded
                                            ? FontAwesomeIcons.chevronUp
                                            : FontAwesomeIcons.chevronDown,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  onTap: () => toggleExpand(foodId),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  foodData['foodDetails']['foodName'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Add reviews section
                                Builder(
                                  builder: (context) {
                                    final reviews = List<Map<String, dynamic>>.from(
                                        foodData['foodDetails']['reviews'] ?? []);

                                    if (reviews.isEmpty) {
                                      return Text(
                                        "(No Reviews)",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      );
                                    }
                                    double avgRating = reviews
                                        .map((review) => review['rating'] as int)
                                        .reduce((a, b) => a + b) /
                                        reviews.length;

                                    return Row(
                                      children: [
                                        Text(
                                          avgRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Row(
                                          children: List.generate(5, (index) {
                                            if (index < avgRating.floor()) {
                                              return const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              );
                                            } else if (index < avgRating &&
                                                avgRating - index >= 0.5) {
                                              return const Icon(
                                                Icons.star_half,
                                                color: Colors.amber,
                                                size: 16,
                                              );
                                            } else {
                                              return const Icon(
                                                Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              );
                                            }
                                          }),
                                        ),
                                        Text(
                                          " (${reviews.length})",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Posted by : ",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 1, 56, 101),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                foodData['donorDetails']['name'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              child: Icon(
                                                Icons.info,
                                                color: Colors.white,
                                              ),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return Dialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      elevation: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(20),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(20),
                                                          color: Colors.white,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey.withOpacity(0.2),
                                                              spreadRadius: 2,
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 3),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            // Header with title
                                                            Row(
                                                              children: [
                                                                const Icon(Icons.person_pin, color: Colors.blue, size: 24),
                                                                const SizedBox(width: 10),
                                                                const Text(
                                                                  "Donor Details",
                                                                  style: TextStyle(
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.blue,
                                                                  ),
                                                                ),
                                                                const Spacer(),
                                                                IconButton(
                                                                  icon: const Icon(Icons.close, color: Colors.grey),
                                                                  onPressed: () => Navigator.of(context).pop(),
                                                                ),
                                                              ],
                                                            ),
                                                            const Divider(thickness: 1),
                                                            const SizedBox(height: 16),

                                                            // Profile image
                                                            Container(
                                                              width: 120,
                                                              height: 120,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors.blue.withOpacity(0.3),
                                                                    spreadRadius: 2,
                                                                    blurRadius: 10,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: (foodData['donorDetails']['profileImage'] != null &&
                                                                          foodData['donorDetails']['profileImage'].toString().trim().isNotEmpty)
                                                                      ? ClipOval(
                                                                          child: Image.network(
                                                                            foodData['donorDetails']['profileImage'],
                                                                            fit: BoxFit.cover,
                                                                            loadingBuilder: (context, child, loadingProgress) {
                                                                              if (loadingProgress == null) return child;
                                                                              return Center(
                                                                                child: CircularProgressIndicator(
                                                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                                              loadingProgress.expectedTotalBytes!
                                                                                          : null,
                                                                                ),
                                                                              );
                                                                            },
                                                                            errorBuilder: (context, error, stackTrace) =>
                                                                                Container(
                                                                                  color: Colors.blue.withOpacity(0.1),
                                                                                  child: const Icon(Icons.person, size: 80, color: Colors.blue),
                                                                                ),
                                                                          ),
                                                                        )
                                                                      : Container(
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.blue.withOpacity(0.1),
                                                                            shape: BoxShape.circle,
                                                                          ),
                                                                          child: const Icon(Icons.person, color: Colors.blue, size: 70),
                                                                        ),
                                                            ),
                                                            const SizedBox(height: 16),

                                                            // Name
                                                            Text(
                                                              foodData['donorDetails']['name'] ?? 'Unknown Donor',
                                                              style: const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 20),

                                                            // Details cards
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                                              child: Column(
                                                                children: [
                                                                  // Age and Gender row
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: _buildInfoItem(
                                                                          icon: Icons.calendar_today,
                                                                          label: "Age",
                                                                          value: "${foodData['donorDetails']['age'].toString()} Years",
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        height: 30,
                                                                        width: 4,
                                                                        color: Colors.grey.withOpacity(0.3),
                                                                      ),
                                                                      Expanded(
                                                                        child: _buildInfoItem(
                                                                          icon: foodData['donorDetails']['gender'] == "Male"
                                                                              ? Icons.male
                                                                              : Icons.female,
                                                                          label: "Gender",
                                                                          value: foodData['donorDetails']['gender'] ?? 'Not specified',
                                                                          valueColor: foodData['donorDetails']['gender'] == "Male"
                                                                              ? Colors.blue
                                                                              : Colors.pink,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                  const Divider(color: Colors.grey, height: 1),
                                                                  const SizedBox(height: 16),

                                                                  // Location
                                                                  _buildInfoItem(
                                                                    icon: Icons.location_on,
                                                                    label: "Location",
                                                                    isFullWidth: true,
                                                                    child: FutureBuilder<String>(
                                                                      future: _getAddress_new(foodData['donorDetails']['coordinates']),
                                                                      builder: (context, snapshot) {
                                                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                                                          return const Text(
                                                                            "Loading location...",
                                                                            style: TextStyle(
                                                                              color: Colors.black87,
                                                                              fontSize: 16,
                                                                            ),
                                                                          );
                                                                        }
                                                                        if (snapshot.hasError) {
                                                                          return const Text(
                                                                            "Location unavailable",
                                                                            style: TextStyle(
                                                                              color: Colors.red,
                                                                              fontSize: 16,
                                                                            ),
                                                                          );
                                                                        }
                                                                        return Text(
                                                                          snapshot.data ?? "Address not available",
                                                                          style: const TextStyle(
                                                                            color: Colors.black87,
                                                                            fontSize: 16,
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 16),

                                                                  // Contact
                                                                  _buildInfoItem(
                                                                    icon: Icons.phone,
                                                                    label: "Contact",
                                                                    value: foodData['donorDetails']['contact'] ?? 'No contact info',
                                                                    isFullWidth: true,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            Text("  "),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Text("|",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Row(
                                    children: [
                                      Text(
                                        "Requested by : ",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 1, 56, 101),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                foodData['requesterDetails']['name'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              child: Icon(
                                                Icons.info,
                                                color: Colors.white,
                                              ),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return Dialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      elevation: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(20),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(20),
                                                          color: Colors.white,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey.withOpacity(0.2),
                                                              spreadRadius: 2,
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 3),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            // Header with title
                                                            Row(
                                                              children: [
                                                                const Icon(Icons.person_pin, color: Colors.blue, size: 24),
                                                                const SizedBox(width: 10),
                                                                const Text(
                                                                  "Requester Details",
                                                                  style: TextStyle(
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.blue,
                                                                  ),
                                                                ),
                                                                const Spacer(),
                                                                IconButton(
                                                                  icon: const Icon(Icons.close, color: Colors.grey),
                                                                  onPressed: () => Navigator.of(context).pop(),
                                                                ),
                                                              ],
                                                            ),
                                                            const Divider(thickness: 1),
                                                            const SizedBox(height: 16),

                                                            // Profile image
                                                            Container(
                                                              width: 120,
                                                              height: 120,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors.blue.withOpacity(0.3),
                                                                    spreadRadius: 2,
                                                                    blurRadius: 10,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: (foodData['requesterDetails']['profileImage'] != null &&
                                                                          foodData['requesterDetails']['profileImage'].toString().trim().isNotEmpty)
                                                                      ? ClipOval(
                                                                          child: Image.network(
                                                                            foodData['requesterDetails']['profileImage'],
                                                                            fit: BoxFit.cover,
                                                                            loadingBuilder: (context, child, loadingProgress) {
                                                                              if (loadingProgress == null) return child;
                                                                              return Center(
                                                                                child: CircularProgressIndicator(
                                                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                                              loadingProgress.expectedTotalBytes!
                                                                                          : null,
                                                                                ),
                                                                              );
                                                                            },
                                                                            errorBuilder: (context, error, stackTrace) =>
                                                                                Container(
                                                                                  color: Colors.blue.withOpacity(0.1),
                                                                                  child: const Icon(Icons.person, size: 80, color: Colors.blue),
                                                                                ),
                                                                          ),
                                                                        )
                                                                      : Container(
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.blue.withOpacity(0.1),
                                                                            shape: BoxShape.circle,
                                                                          ),
                                                                          child: const Icon(Icons.person, color: Colors.blue, size: 70),
                                                                        ),
                                                            ),
                                                            const SizedBox(height: 16),

                                                            // Name
                                                            Text(
                                                              foodData['requesterDetails']['name'] ?? 'Unknown Requester',
                                                              style: const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 20),

                                                            // Details cards
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                                              child: Column(
                                                                children: [
                                                                  // Age and Gender row
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: _buildInfoItem(
                                                                          icon: Icons.calendar_today,
                                                                          label: "Age",
                                                                          value: "${foodData['requesterDetails']['age'].toString()} Years",
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        height: 30,
                                                                        width: 4,
                                                                        color: Colors.grey.withOpacity(0.3),
                                                                      ),
                                                                      Expanded(
                                                                        child: _buildInfoItem(
                                                                          icon: foodData['requesterDetails']['gender'] == "Male"
                                                                              ? Icons.male
                                                                              : Icons.female,
                                                                          label: "Gender",
                                                                          value: foodData['requesterDetails']['gender'] ?? 'Not specified',
                                                                          valueColor: foodData['requesterDetails']['gender'] == "Male"
                                                                              ? Colors.blue
                                                                              : Colors.pink,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                  const Divider(color: Colors.grey, height: 1),
                                                                  const SizedBox(height: 16),

                                                                  // Location
                                                                  _buildInfoItem(
                                                                    icon: Icons.location_on,
                                                                    label: "Location",
                                                                    isFullWidth: true,
                                                                    child: FutureBuilder<String>(
                                                                      future: _getAddress_new(foodData['requesterDetails']['coordinates']),
                                                                      builder: (context, snapshot) {
                                                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                                                          return const Text(
                                                                            "Loading location...",
                                                                            style: TextStyle(
                                                                              color: Colors.black87,
                                                                              fontSize: 16,
                                                                            ),
                                                                          );
                                                                        }
                                                                        if (snapshot.hasError) {
                                                                          return const Text(
                                                                            "Location unavailable",
                                                                            style: TextStyle(
                                                                              color: Colors.red,
                                                                              fontSize: 16,
                                                                            ),
                                                                          );
                                                                        }
                                                                        return Text(
                                                                          snapshot.data ?? "Address not available",
                                                                          style: const TextStyle(
                                                                            color: Colors.black87,
                                                                            fontSize: 16,
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 16),

                                                                  // Contact
                                                                  _buildInfoItem(
                                                                    icon: Icons.phone,
                                                                    label: "Contact",
                                                                    value: foodData['requesterDetails']['contact'] ?? 'No contact info',
                                                                    isFullWidth: true,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            Text("  "),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text("Expiry Date : ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  width:120,
                                  decoration:BoxDecoration(
                                    color: const Color.fromARGB(255, 1, 56, 101),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                child:Center(child:Text(
                                  foodData['foodDetails']['expiryDate'] is Timestamp
                                      ? DateFormat('MMM dd, yyyy').format((foodData['foodDetails']['expiryDate'] as Timestamp).toDate())
                                      : foodData['foodDetails']['expiryDate'].toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),))
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Created On : ",
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 69, 63, 249),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    foodData['foodDetails']['date'] is Timestamp
                                        ? DateFormat('MMM dd, yyyy').format((foodData['foodDetails']['date'] as Timestamp).toDate())
                                        : foodData['foodDetails']['date'].toString(),
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 39, 39, 39),
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text("Location",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 69, 63, 249),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Text("Distance : ",
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 69, 63, 249),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    height: 33,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("${foodData['distance']} km",
                                        style: TextStyle(
                                          color: const Color.fromARGB(255, 69, 63, 249),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FutureBuilder<String>(
                                      future: _getAddress(foodData['requesterDetails']['coordinates']),
                                      builder: (context, snapshot) {
                                        return Container(
                                          height: 33,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              ' ${snapshot.data ?? "Loading..."}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color.fromARGB(255, 69, 63, 249),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    FutureBuilder<String>(
                                      future: _getAddress(foodData['donorDetails']['coordinates']),
                                      builder: (context, snapshot) {
                                        return Container(
                                          height: 33,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              ' ${snapshot.data ?? "Loading..."}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color.fromARGB(255, 69, 63, 249),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text("Volunteer  ",
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 69, 63, 249),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "${foodData['volunteerDetails']['name']}"
                                          )
                                        ),
                                        Text("|",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "${foodData['volunteerDetails']['contact']}"
                                          ),
                                        ),
                                        Text("  "),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: GestureDetector(
                                      child: Icon(
                                        Icons.info,
                                        color: Colors.white,
                                      ),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(20),
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.2),
                                                      spreadRadius: 2,
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Header with title
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.volunteer_activism, color: Colors.green, size: 24),
                                                        const SizedBox(width: 10),
                                                        const Text(
                                                          "Volunteer Details",
                                                          style: TextStyle(
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        IconButton(
                                                          icon: const Icon(Icons.close, color: Colors.grey),
                                                          onPressed: () => Navigator.of(context).pop(),
                                                        ),
                                                      ],
                                                    ),
                                                    const Divider(thickness: 1),
                                                    const SizedBox(height: 16),

                                                    // Profile image
                                                    Container(
                                                      width: 120,
                                                      height: 120,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green.withOpacity(0.3),
                                                            spreadRadius: 2,
                                                            blurRadius: 10,
                                                          ),
                                                        ],
                                                      ),
                                                      child: (foodData['volunteerDetails']['profileImage'] != null &&
                                                              foodData['volunteerDetails']['profileImage'].toString().trim().isNotEmpty)
                                                          ? ClipOval(
                                                              child: Image.network(
                                                                foodData['volunteerDetails']['profileImage'],
                                                                fit: BoxFit.cover,
                                                                loadingBuilder: (context, child, loadingProgress) {
                                                                  if (loadingProgress == null) return child;
                                                                  return Center(
                                                                    child: CircularProgressIndicator(
                                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                                      value: loadingProgress.expectedTotalBytes != null
                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                            loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                    ),
                                                                  );
                                                                },
                                                                errorBuilder: (context, error, stackTrace) =>
                                                                    Container(
                                                                      color: Colors.green.withOpacity(0.1),
                                                                      child: const Icon(Icons.person, size: 80, color: Colors.green),
                                                                    ),
                                                              ),
                                                            )
                                                          : Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors.green.withOpacity(0.1),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: const Icon(Icons.person, color: Colors.green, size: 70),
                                                            ),
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Name
                                                    Text(
                                                      foodData['volunteerDetails']['name'] ?? 'Unknown Volunteer',
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),

                                                    // Availability badge
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(color: Colors.green, width: 1),
                                                      ),
                                                      child: Text(
                                                        foodData['volunteerDetails']['availability']['type'] ?? 'Not specified',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),

                                                    // Details cards
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                                      child: Column(
                                                        children: [
                                                          // Age and Gender row
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: _buildInfoItem(
                                                                  icon: Icons.calendar_today,
                                                                  label: "Age",
                                                                  value: "${foodData['volunteerDetails']['age'].toString()} Years",
                                                                ),
                                                              ),
                                                              Container(
                                                                height: 30,
                                                                width: 4,
                                                                color: Colors.grey.withOpacity(0.3),
                                                              ),
                                                              Expanded(
                                                                child: _buildInfoItem(
                                                                  icon: foodData['volunteerDetails']['gender'] == "Male"
                                                                      ? Icons.male
                                                                      : Icons.female,
                                                                  label: "Gender",
                                                                  value: foodData['volunteerDetails']['gender'] ?? 'Not specified',
                                                                  valueColor: foodData['volunteerDetails']['gender'] == "Male"
                                                                      ? Colors.blue
                                                                      : Colors.pink,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 16),
                                                          const Divider(color: Colors.grey, height: 1),
                                                          const SizedBox(height: 16),

                                                          // Address
                                                          _buildInfoItem(
                                                            icon: Icons.location_on,
                                                            label: "Location",
                                                            isFullWidth: true,
                                                            child: FutureBuilder<String>(
                                                              future: _getAddress_new(foodData['volunteerDetails']['address']),
                                                              builder: (context, snapshot) {
                                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                                  return const Text(
                                                                    "Loading location...",
                                                                    style: TextStyle(
                                                                      color: Colors.black87,
                                                                      fontSize: 16,
                                                                    ),
                                                                  );
                                                                }
                                                                if (snapshot.hasError) {
                                                                  return const Text(
                                                                    "Location unavailable",
                                                                    style: TextStyle(
                                                                      color: Colors.red,
                                                                      fontSize: 16,
                                                                    ),
                                                                  );
                                                                }
                                                                return Text(
                                                                  snapshot.data ?? "Address not available",
                                                                  style: const TextStyle(
                                                                    color: Colors.black87,
                                                                    fontSize: 16,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(height: 16),

                                                          // Contact
                                                          _buildInfoItem(
                                                            icon: Icons.phone,
                                                            label: "Contact",
                                                            value: foodData['volunteerDetails']['contact'] ?? 'No contact info',
                                                            isFullWidth: true,
                                                          ),
                                                          const SizedBox(height: 16),

                                                          // Email
                                                          _buildInfoItem(
                                                            icon: Icons.email,
                                                            label: "Email",
                                                            value: foodData['volunteerDetails']['email'] ?? 'No email provided',
                                                            isFullWidth: true,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),

                                                    // Action buttons
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            onPressed: () => Navigator.of(context).pop(),
                                                            style: OutlinedButton.styleFrom(
                                                              side: const BorderSide(color: Colors.green),
                                                              foregroundColor: Colors.green,
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                            child: const Text("Close", style: TextStyle(fontSize: 16)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              // Add contact functionality here
                                                              final contact = foodData['volunteerDetails']['contact'];
                                                              if (contact != null && contact.isNotEmpty) {
                                                                // Implement call or message functionality
                                                                launchUrl(Uri.parse('tel:$contact'));
                                                              }
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green,
                                                              foregroundColor: Colors.white,
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                            child: const Text("Contact", style: TextStyle(fontSize: 16)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildMapView(foodData),
                              const SizedBox(height: 10),
                              Text("Description",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 69, 63, 249),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                foodData['foodDetails']['description'],
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 69, 63, 249),
                                  fontSize: 16,
                                )
                              ),
                              const SizedBox(height: 10),
                              Text("Photos",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 69, 63, 249),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                              // Images in row
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                                          borderRadius: BorderRadius.circular(12)
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: foodData['foodDetails']["images"][0].isNotEmpty
                                              ? (foodData['foodDetails']["images"][0].startsWith('data')
                                                  ? Image.file(
                                                      File(foodData['foodDetails']["images"][0]),
                                                      fit: BoxFit.fill,
                                                      width: 100,
                                                      height: 100,
                                                    )
                                                  : Image.network(
                                                      foodData['foodDetails']["images"][0],
                                                      fit: BoxFit.fill,
                                                      width: 100,
                                                      height: 100,
                                                    ))
                                              : const Icon(
                                                  Icons.image,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                                          borderRadius: BorderRadius.circular(12)
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: foodData['foodDetails']["images"][1].isNotEmpty
                                              ? (foodData['foodDetails']["images"][1].startsWith('data')
                                                  ? Image.file(
                                                      File(foodData['foodDetails']["images"][1]),
                                                      fit: BoxFit.fill,
                                                      width: 100,
                                                      height: 100,
                                                    )
                                                  : Image.network(
                                                      foodData['foodDetails']["images"][1],
                                                      fit: BoxFit.fill,
                                                      width: 100,
                                                      height: 100,
                                                    ))
                                              : const Icon(
                                                  Icons.image,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 40,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: const Color.fromARGB(255, 69, 63, 249)),
                                    ),
                                    child: MaterialButton(
                                      onPressed: () => _handleApproval(foodData, foodId),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("Approve",
                                            style: TextStyle(
                                              color: const Color.fromARGB(255, 69, 63, 249),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Icon(
                                            Icons.done,
                                            color: const Color.fromARGB(255, 69, 63, 249),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 40,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: const Color.fromARGB(255, 69, 63, 249)),
                                    ),
                                    child: MaterialButton(
                                      onPressed: () => _handleRejection(foodData, foodId),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("Cancel",
                                            style: TextStyle(
                                              color: const Color.fromARGB(255, 69, 63, 249),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Icon(
                                            Icons.close,
                                            color: const Color.fromARGB(255, 69, 63, 249),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}