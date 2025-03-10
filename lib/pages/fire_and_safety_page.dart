import 'dart:convert';
import 'package:food_delivery_app/pages/edit_fire_and_safety_details.dart';
import 'package:food_delivery_app/pages/fire_and_safety_pop_screen.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/add_fire_and_safety_details.dart';
import 'package:food_delivery_app/pages/map_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FireAndSafetyPage extends StatefulWidget {
  final String userId;
  final String location;
  const FireAndSafetyPage({super.key, required this.userId, required this.location});

  @override
  State<FireAndSafetyPage> createState() => _FireAndSafetyPageState();
}

class _FireAndSafetyPageState extends State<FireAndSafetyPage> with SingleTickerProviderStateMixin {
  Stream? fireAndsafetyStream;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    fireAndsafetyStream = FirebaseFirestore.instance
        .collection("fireAndsafety")
        .where("Location", isEqualTo: widget.location)
        .snapshots();

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_blinkController);

    setState(() {});
  }

  bool isCurrentlyAvailable(Map<String, dynamic> availability) {
    if (availability["type"] == 'Full time') {
      return true;
    }

    if (availability["fromTime"] == null || availability["toTime"] == null) {
      return false;
    }

    final now = TimeOfDay.now();

    String fromTimeStr = availability["fromTime"].toString();
    String toTimeStr = availability["toTime"].toString();

    try {
      List<String> fromParts = fromTimeStr.split(" ");
      List<String> fromTimeParts = fromParts[0].split(":");
      bool fromIsAM = fromParts[1].toUpperCase() == "AM";

      List<String> toParts = toTimeStr.split(" ");
      List<String> toTimeParts = toParts[0].split(":");
      bool toIsAM = toParts[1].toUpperCase() == "AM";

      int fromHour = int.parse(fromTimeParts[0]);
      int fromMinute = int.parse(fromTimeParts[1]);
      int toHour = int.parse(toTimeParts[0]);
      int toMinute = int.parse(toTimeParts[1]);

      if (!fromIsAM && fromHour != 12) fromHour += 12;
      if (fromIsAM && fromHour == 12) fromHour = 0;
      if (!toIsAM && toHour != 12) toHour += 12;
      if (toIsAM && toHour == 12) toHour = 0;

      int currentMinutes = now.hour * 60 + now.minute;
      int fromMinutes = fromHour * 60 + fromMinute;
      int toMinutes = toHour * 60 + toMinute;

      if (toMinutes > fromMinutes) {
        return currentMinutes >= fromMinutes && currentMinutes <= toMinutes;
      } else {
        return currentMinutes >= fromMinutes || currentMinutes <= toMinutes;
      }
    } catch (e) {
      print('Error parsing time: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      body: Column(
        children: [
          Expanded(child: allFireAndSafetyDetails()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFireAndSafetyDetails(userId: widget.userId, location: widget.location),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget allFireAndSafetyDetails() {
    final lightModeColors = [
      Colors.blue[100],
      Colors.green[100],
      Colors.orange[100],
      Colors.purple[100],
      Colors.teal[100],
    ];

    final themeProvider = Provider.of<ThemeProvider>(context);
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("fireAndsafety")
          .where("Location", isEqualTo: widget.location)
          .snapshots(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(child: Text("No Fire & Safety Services Available"));
        }

        List<DocumentSnapshot> facilities = snapshot.data.docs;

        return ListView.builder(
          itemCount: facilities.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = facilities[index];
            bool isActive = ds["status"] == "active";
            bool isAvailable = isCurrentlyAvailable(ds["availability"]);

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Slidable(
                    key: ValueKey(ds.id), // Add a unique key for each Slidable
                    startActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.25,
                      children: [
                        CustomSlidableAction(
                          backgroundColor: Colors.green,
                          onPressed: (context) async {
                            final Uri phoneUri = Uri(
                              scheme: 'tel',
                              path: ds["contact"],
                            );
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            }
                          },
                          child: const Icon(Icons.phone, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                    endActionPane: ds["userId"] == widget.userId
                        ? ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.25,
                            children: [
                              CustomSlidableAction(
                                backgroundColor: themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.red,
                                onPressed: (context) async {
                                  final ambulanceId = ds.id;
                                  final confirmation = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm Deletion"),
                                        content: const Text("Are you sure you want to delete this ambulance entry?"),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () => Navigator.of(context).pop(false),
                                          ),
                                          TextButton(
                                            child: const Text("Delete"),
                                            onPressed: () => Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmation == true) {
                                    try {
                                      await FirebaseFirestore.instance.collection("ambulance").doc(ambulanceId).delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Ambulance Details deleted successfully")),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error deleting Ambulance Detail: $e")),
                                      );
                                    }
                                  }
                                },
                                child: Icon(
                                  Icons.delete,
                                  color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          )
                        : null,
                    child: Stack(
                      children: [
                        GestureDetector(
                          child: Container(
                            height: 247,
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? (isActive && isAvailable ? Colors.grey[800]: Colors.grey[800])
                                  : (isActive && isAvailable ? const Color(0xFFDEEDFC) : const Color(0xFFDEEDFC)),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(ds["profileImage"], fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ds["name"],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  "Age: ${ds["age"]}",
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: ds["gender"] == "Male" ? Colors.blue : Colors.pink,
                                                    borderRadius: BorderRadius.circular(15),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  child: Text(
                                                    ds["gender"],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              child: Container(
                                                height: 40,
                                                width: 40,
                                                decoration: BoxDecoration(
                                                  color: themeProvider.isDarkMode ? Colors.grey.shade800 : const Color.fromARGB(255, 62, 64, 231),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.directions,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                              onTap: () async {
                                                try {
                                                  String addressString = ds['address'];
                                                  List<String> latLng = addressString.split(',');
                                                  double shelterLat = double.parse(latLng[0].trim());
                                                  double shelterLng = double.parse(latLng[1].trim());
                          
                                                  DocumentSnapshot userProfile = await FirebaseFirestore.instance
                                                      .collection("Profile")
                                                      .doc(widget.userId)
                                                      .get();
                                                  String locationString = userProfile["location"];
                                                  List<String> userlatLng = locationString.split(',');
                                                  double locationLat = double.parse(userlatLng[0].trim());
                                                  double locationLng = double.parse(userlatLng[1].trim());
                          
                                                  String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc';
                                                  String url = 'https://maps.googleapis.com/maps/api/directions/json'
                                                      '?origin=$locationLat,$locationLng'
                                                      '&destination=$shelterLat,$shelterLng'
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
                          
                                                    var route = data['routes'][0]['legs'][0];
                                                    var distanceInMeters = route['distance']['value'];
                                                    var distanceText = route['distance']['text'];
                                                    var durationText = route['duration']['text'];
                                                    var distanceInKm = distanceInMeters / 1000.0;
                                                    String encodedPoints = data['routes'][0]['overview_polyline']['points'];
                          
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => MapScreen(
                                                          shelterLat: shelterLat,
                                                          shelterLng: shelterLng,
                                                          userLat: locationLat,
                                                          userLng: locationLng,
                                                          distance: distanceInKm,
                                                          distanceText: distanceText,
                                                          durationText: durationText,
                                                          encodedPolyline: encodedPoints,
                                                          shelterId: ds["id"],
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    throw Exception('Failed to fetch directions: ${response.statusCode}');
                                                  }
                                                } catch (e) {
                                                  print('Error: $e');
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Failed to get directions: ${e.toString()}')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  ds["facilityType"],
                                                  style: const TextStyle(
                                                    color: Colors.deepOrange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 30),
                                              Container(
                                                width: 100,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(255, 1, 155, 6).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "${ds["experience"]} Years",
                                                    style: TextStyle(
                                                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.medical_services, size: 16),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: SizedBox(
                                                height: 32,
                                                child: ListView.builder(
                                                  scrollDirection: Axis.horizontal,
                                                  itemCount: (ds["services"] as List).length,
                                                  itemBuilder: (context, serviceIndex) {
                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        right: serviceIndex != (ds["services"] as List).length - 1 ? 6.0 : 0,
                                                      ),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: themeProvider.isDarkMode
                                                              ? Colors.grey[700]
                                                              : lightModeColors[serviceIndex % lightModeColors.length],
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        child: Text(
                                                          (ds["services"] as List)[serviceIndex],
                                                          style: TextStyle(
                                                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 7),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.construction, size: 16),
                                            const SizedBox(width: 4),
                                            Text("${_countEquipment(ds["equipment"])} Equipment"),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: ds["availability"]["type"] == '24/7'
                                                    ? Colors.green.withOpacity(0.2)
                                                    : (themeProvider.isDarkMode
                                                        ? Colors.grey[700]
                                                        : Colors.white.withOpacity(0.7)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 16,
                                                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    ds["availability"]["type"] == '24/7'
                                                        ? "Always Available"
                                                        : "${ds["availability"]["fromTime"] ?? ''} - ${ds["availability"]["toTime"] ?? ''}",
                                                    style: TextStyle(
                                                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (ds["userId"] == widget.userId)
                                              Container(
                                                height: 40,
                                                width: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color: themeProvider.isDarkMode ? Colors.black : Colors.black,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => EditFireAndSafetyDetails(
                                                            userId: widget.userId,
                                                            fireAndsafetyId: ds.id,
                                                            fireAndSafetyDetails: ds.data() as Map<String, dynamic>,
                                                            location: widget.location,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              )
                                          ],
                                        ),
                                        const Spacer(),
                                        // Contact Info
                                      ],
                                    ),
                                  ),
                                  
                                ),
                                
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>FireAndSafetyPopScreen(fireAndSafetyData: ds)));
                          },
                        ),
                        Positioned(
                    top: 12,
                    right: 12,
                    child: FadeTransition(
                      opacity: _blinkAnimation,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? (ds["availability"]["type"] == "24/7" || isCurrentlyAvailable(ds["availability"]))
                                  ? Colors.green
                                  : Colors.red
                              : Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: (isActive &&
                                      (ds["availability"]["type"] == "24/7" || isCurrentlyAvailable(ds["availability"])))
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.red.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                      ],
                    ),
                    
                  ),
            );
          },
        );
      },
    );
  }

  int _countEquipment(Map<String, dynamic> equipment) {
    int count = 0;
    equipment.forEach((key, value) {
      if (value is List) count += value.length;
    });
    return count;
  }
}