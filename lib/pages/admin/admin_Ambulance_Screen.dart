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

class AdminAmbulanceScreen extends StatefulWidget {
  final String userId;
  final String location;
  const AdminAmbulanceScreen({super.key, required this.userId, required this.location});

  @override
  State<AdminAmbulanceScreen> createState() => _AdminAmbulanceScreenState();
}

class _AdminAmbulanceScreenState extends State<AdminAmbulanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<String> hiddenItems = {};
  Set<String> expandedItems = {};
  Map<String, String> addressCache = {};

  String _generateOTP() {
    Random random = Random();
    return (1000 + random.nextInt(9000)).toString(); // Generates number between 1000-9999
  }

  Future<void> _handleApproval(Map<String, dynamic> bookingData, String bookingId) async {
    try {
      // Generate OTP
      final String otp = _generateOTP();

      // Store OTP in Firestore
      await FirebaseFirestore.instance
          .collection('ambulanceVerification')
          .doc(bookingId)
          .set({
        'otp': otp,
        'verified': false,
        'attempts': 0,
        'requesterId': bookingData['requesterDetails']['userId'],
        'driverId': bookingData['driverDetails']['userId'],
      });

      // Update driver status to busy
      await FirebaseFirestore.instance
          .collection('drivers')
          .where('userId', isEqualTo: bookingData['driverDetails']['userId'])
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'currentStat': 'busy',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Delete existing chats
final chatQuery = await FirebaseFirestore.instance
    .collection('chats')
    .where('participants', arrayContainsAny: [
      bookingData['driverDetails']['userId'],
      bookingData['requesterDetails']['userId']
    ])
    .get();

    final batch = FirebaseFirestore.instance.batch();

    // Delete chat documents and their messages
for (var chatDoc in chatQuery.docs) {
  final messagesQuery = await chatDoc.reference
      .collection('messages')
      .get();
      
  for (var messageDoc in messagesQuery.docs) {
    batch.delete(messageDoc.reference);
  }
  
  batch.delete(chatDoc.reference);
}

await batch.commit();


      // Send notification to requester
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': bookingData['requesterDetails']['userId'],
        'title': 'Ambulance Request Approved - Your Verification Code',
        'message': 'Your ambulance request has been approved. Show this code to your driver when they arrive.',
        'verificationCode': otp,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'shelter_approved_with_otp',
        'coordinates': bookingData['requesterDetails']['coordinates'],
        'targetCoordinates': bookingData['driverDetails']['address']
      });

      // Send separate OTP notification to requester
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': bookingData['requesterDetails']['userId'],
        'title': 'Verification Code',
        'message': 'Your verification code is: $otp. Share this with your driver when they arrive.',
        'verificationCode': otp,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'otp_notification'
      });

      // Send notification to driver
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': bookingData['driverDetails']['userId'],
        'title': 'Ambulance Request Approved - Verify Requester',
        'message': 'The coordinator has approved ambulance request for ${bookingData['requesterDetails']['name']}. Ask for their verification code when you meet them.',
        'timestamp': FieldValue.serverTimestamp(),
        'requesterId': bookingData['requesterDetails']['userId'],
        'requesterName': bookingData['requesterDetails']['name'],
        'type': 'ambulance_approved_verify',
        'ambulanceId': bookingId,
        'coordinates': bookingData['requesterDetails']['coordinates'],
        'targetCoordinates': bookingData['driverDetails']['address'],
      });

      // Send notification to requester
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': bookingData['requesterDetails']['userId'],
        'title': 'Ambulance Request Approved',
        'message': 'Your ambulance request has been approved. You can now use the ambulance. Click below to track Driver',
        'timestamp': FieldValue.serverTimestamp(),
        'driverId': bookingData['driverDetails']['userId'],
        'driverName': bookingData['driverDetails']['name'],
        'type': 'ambulance_approved',
        'coordinates': bookingData['requesterDetails']['coordinates'],
        'targetCoordinates': bookingData['driverDetails']['address']
      });

      // Remove the request from adminAmbulanceDetails
      await FirebaseFirestore.instance
          .collection('adminAmbulanceDetails')
          .doc(bookingId)
          .update({
        'status': 'approved',
        'approvalTime': FieldValue.serverTimestamp(),
        'approvedBy': widget.userId,
      });

      // Hide the item from the UI
      setState(() {
        hiddenItems.add(bookingId);
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
      'title': 'Ambulance Approval Update',
      'message': '$currentAdminName has approved Ambulance request at $formattedTime\nRequester: ${bookingData['requesterDetails']['name']}\nDriver: ${bookingData['driverDetails']['name']}',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'admin_shelter_approval',
      'shelterId': bookingData['driverDetails']['userId'],
      'approvedBy': widget.userId,
      'location': widget.location
    });
  }
}
  }

  Future<void> _handleRejection(Map<String, dynamic> bookingData, String bookingId) async {
    try {
      // Update driver status to free
      await FirebaseFirestore.instance
          .collection('drivers')
          .where('userId', isEqualTo: bookingData['driverDetails']['userId'])
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
        'userId': bookingData['requesterDetails']['userId'],
        'title': 'Ambulance Request Rejected',
        'message': 'Your ambulance request has been rejected by ${widget.location} Coordinator.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'shelter_rejected'
      });

      // Send notification to driver
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': bookingData['driverDetails']['userId'],
        'title': 'Ambulance Request Rejected',
        'message': 'The ambulance request for ${bookingData['requesterDetails']['name']} has been rejected by the coordinator.',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'shelter_rejected'
      });

      // Remove the request from adminAmbulanceDetails
      await FirebaseFirestore.instance
          .collection('adminAmbulanceDetails')
          .doc(bookingId)
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

  Widget _buildMapView(Map<String, dynamic> bookingData) {
    return FutureBuilder<Set<Polyline>>(
      future: _getRoutePolyline(bookingData),
      builder: (context, snapshot) {
        final requesterCoords = bookingData['requesterDetails']['coordinates'].toString().split(',');
        final driverCoords = bookingData['driverDetails']['address'].toString().split(',');

        final requesterLatLng = LatLng(
          double.parse(requesterCoords[0].trim()),
          double.parse(requesterCoords[1].trim())
        );
        final driverLatLng = LatLng(
          double.parse(driverCoords[0].trim()),
          double.parse(driverCoords[1].trim())
        );

        // Calculate the bounds that include both markers
        final double south = min(requesterLatLng.latitude, driverLatLng.latitude);
        final double north = max(requesterLatLng.latitude, driverLatLng.latitude);
        final double west = min(requesterLatLng.longitude, driverLatLng.longitude);
        final double east = max(requesterLatLng.longitude, driverLatLng.longitude);

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
                  (requesterLatLng.latitude + driverLatLng.latitude) / 2,
                  (requesterLatLng.longitude + driverLatLng.longitude) / 2,
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
                  markerId: const MarkerId('driver'),
                  position: driverLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(title: 'Driver Location'),
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

// Replace the existing _buildLicenseViewer method with this:
Widget _buildLicenseViewer(String licenseUrl,String drivername) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color.fromARGB(255, 69, 63, 249)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.file_copy, 
              color: const Color.fromARGB(255, 69, 63, 249),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              "$drivername's Document",
              style: TextStyle(
                color: const Color.fromARGB(255, 69, 63, 249),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchPDF(context, licenseUrl),
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text(
                  'View License',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: const Color.fromARGB(255, 69, 63, 249),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Add this method to handle PDF launching
Future<void> _launchPDF(BuildContext context, String pdfUrl) async {
  try {
    final Uri url = Uri.parse(pdfUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url, 
        mode: LaunchMode.externalApplication
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the license document'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  Future<Set<Polyline>> _getRoutePolyline(Map<String, dynamic> bookingData) async {
    final requesterCoords = bookingData['requesterDetails']['coordinates'].toString().split(',');
    final driverCoords = bookingData['driverDetails']['address'].toString().split(',');

    final requesterLatLng = LatLng(
      double.parse(requesterCoords[0].trim()),
      double.parse(requesterCoords[1].trim())
    );

    final driverLatLng = LatLng(
      double.parse(driverCoords[0].trim()),
      double.parse(driverCoords[1].trim())
    );
    try {
      String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc';
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${requesterLatLng.latitude},${requesterLatLng.longitude}'
          '&destination=${driverLatLng.latitude},${driverLatLng.longitude}'
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
          points: [requesterLatLng, driverLatLng],
          color: Colors.blue,
          width: 5,
        ),
      };
    }
  }

  void toggleExpand(String bookingId) {
    setState(() {
      if (expandedItems.contains(bookingId)) {
        expandedItems.remove(bookingId);
      } else {
        expandedItems.add(bookingId);
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
            .collection('adminAmbulanceDetails')
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
            return const Center(child: Text('No ambulance data found for this location'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bookingData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var bookingId = snapshot.data!.docs[index].id;
              bool isExpanded = expandedItems.contains(bookingId);

              if (hiddenItems.contains(bookingId)) {
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
                                    child: Center(
                                      child: Text(
                                        "${bookingData['ambulanceDetails']['ambAvailability']} ",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          "${bookingData['ambulanceDetails']['licenseType']} Licence",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                  onTap: () => toggleExpand(bookingId),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  bookingData['ambulanceDetails']['driverName'] ?? 'Unknown Driver',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                        "Driven by : ",
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
                                                bookingData['driverDetails']['name'] ?? '',
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
                                                                  "Driver Details",
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
                                                              child: (bookingData['driverDetails']['profileImage'] != null &&
                                                                          bookingData['driverDetails']['profileImage'].toString().trim().isNotEmpty)
                                                                      ? ClipOval(
                                                                          child: Image.network(
                                                                            bookingData['driverDetails']['profileImage'],
                                                                            fit: BoxFit.cover,
                                                                            loadingBuilder: (context, child, loadingProgress) {
                                                                              if (loadingProgress == null) return child;
                                                                              return Center(
                                                                                child: CircularProgressIndicator(
                                                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                                          ? loadingProgress.cumulativeBytesLoaded /                                                                                              loadingProgress.expectedTotalBytes!
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
                                                              bookingData['driverDetails']['name'] ?? 'Unknown Driver',
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
                                                                          value: "${bookingData['driverDetails']['Age'].toString()} Years",
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        height: 30,
                                                                        width: 4,
                                                                        color: Colors.grey.withOpacity(0.3),
                                                                      ),
                                                                      Expanded(
                                                                        child: _buildInfoItem(
                                                                          icon: bookingData['driverDetails']['Gender'] == "Male"
                                                                              ? Icons.male
                                                                              : Icons.female,
                                                                          label: "Gender",
                                                                          value: bookingData['driverDetails']['Gender'] ?? 'Not specified',
                                                                          valueColor: bookingData['driverDetails']['Gender'] == "Male"
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
                                                                      future: _getAddress_new(bookingData['driverDetails']['address']),
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

                                                                 // Update the contact section in _buildInfoItem for driver details dialog
// Replace the existing contact _buildInfoItem with this:

// Contact with phone icon and clickable number
_buildInfoItem(
  icon: Icons.phone,
  label: "Contact",
  isFullWidth: true,
  child: GestureDetector(
    onTap: () async {
      final phoneNumber = bookingData['driverDetails']['contact'];
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
    child: Text(
      bookingData['driverDetails']['contact'] ?? 'No contact info',
      style: const TextStyle(
        color: Colors.green,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
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
                                                bookingData['requesterDetails']['name'] ?? '',
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
                                                              child: (bookingData['requesterDetails']['profileImage'] != null &&
                                                                          bookingData['requesterDetails']['profileImage'].toString().trim().isNotEmpty)
                                                                      ? ClipOval(
                                                                          child: Image.network(
                                                                            bookingData['requesterDetails']['profileImage'],
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
                                                              bookingData['requesterDetails']['name'] ?? 'Unknown Requester',
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
                                                                          value: "${bookingData['requesterDetails']['age'].toString()} Years",
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        height: 30,
                                                                        width: 4,
                                                                        color: Colors.grey.withOpacity(0.3),
                                                                      ),
                                                                      Expanded(
                                                                        child: _buildInfoItem(
                                                                          icon: bookingData['requesterDetails']['gender'] == "Male"
                                                                              ? Icons.male
                                                                              : Icons.female,
                                                                          label: "Gender",
                                                                          value: bookingData['requesterDetails']['gender'] ?? 'Not specified',
                                                                          valueColor: bookingData['requesterDetails']['gender'] == "Male"
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
                                                                      future: _getAddress_new(bookingData['requesterDetails']['coordinates']),
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
                                                                    value: bookingData['requesterDetails']['contact'] ?? 'No contact info',
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
                                Text("Emergency Type : ",
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
                                    color: const Color.fromARGB(255, 37, 133, 2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                child:Center(child:Text(
                                  bookingData['emergencyType'],
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
                                    bookingData['createdAt'] is Timestamp
                                        ? DateFormat('MMM dd, yyyy').format((bookingData['createdAt'] as Timestamp).toDate())
                                        : bookingData['createdAt'].toString(),
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
                                      child: Text("${bookingData['distance']} km",
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
                                    FutureBuilder<String>(                                      future: _getAddress(bookingData['requesterDetails']['coordinates']),
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
                                      future: _getAddress(bookingData['driverDetails']['address']),
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
                              _buildMapView(bookingData),
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
                                bookingData['ambulanceDetails']['description'],
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 69, 63, 249),
                                  fontSize: 16,
                                )
                              ),
                              const SizedBox(height: 10),
                              Text("License",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 69, 63, 249),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                              // License PDF Viewer
                              _buildLicenseViewer(bookingData['ambulanceDetails']['licence'],bookingData['driverDetails']['name']),
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
                                      onPressed: () => _handleApproval(bookingData, bookingId),
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
                                      onPressed: () => _handleRejection(bookingData, bookingId),
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
