import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/add_blood_donor_details.dart';
import 'package:food_delivery_app/pages/blood_donor_pop_screen.dart';
import 'package:food_delivery_app/pages/edit_blood_donor_details.dart';
import 'package:food_delivery_app/pages/map_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class BloodDonorPage extends StatefulWidget {
  final String userId;
  final String location;


  const BloodDonorPage({super.key,required this.userId,required this.location});

  @override
  State<BloodDonorPage> createState() => _BloodDonorPageState();
}

class _BloodDonorPageState extends State<BloodDonorPage> with SingleTickerProviderStateMixin {

  Stream? bloodDonorStream;
  

  @override
  void initState() {
    super.initState();
    fetchbloodDonors();
    
  }


   Future<void> fetchbloodDonors() async {
    bloodDonorStream = FirebaseFirestore.instance
        .collection("bloodDonor")
        .where("location", isEqualTo: widget.location)
        .snapshots();
    setState(() {});
  }

  bool isCurrentlyAvailable(Map<String, dynamic> availability) {
    // If Full time, always return true
    if (availability["type"] == 'Full time') {
      return true;
    }
    
    // Check if fromTime and toTime exist and are not null
    if (availability["fromTime"] == null || availability["toTime"] == null) {
      return false;
    }

    final now = TimeOfDay.now();
    
    // Safely parse the time strings
    String fromTimeStr = availability["fromTime"].toString();
    String toTimeStr = availability["toTime"].toString();

    try {
      // Parse hours and minutes, handling AM/PM
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

      // Convert to 24-hour format
      if (!fromIsAM && fromHour != 12) fromHour += 12;
      if (fromIsAM && fromHour == 12) fromHour = 0;
      if (!toIsAM && toHour != 12) toHour += 12;
      if (toIsAM && toHour == 12) toHour = 0;

      // Convert all times to minutes for comparison
      int currentMinutes = now.hour * 60 + now.minute;
      int fromMinutes = fromHour * 60 + fromMinute;
      int toMinutes = toHour * 60 + toMinute;

      if (toMinutes > fromMinutes) {
        // Normal time range (e.g., 9:00 AM to 5:00 PM)
        return currentMinutes >= fromMinutes && currentMinutes <= toMinutes;
      } else {
        // Overnight time range (e.g., 10:00 PM to 6:00 AM)
        return currentMinutes >= fromMinutes || currentMinutes <= toMinutes;
      }
    } catch (e) {
      print('Error parsing time: $e');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      body: Column(
        children: [
          Expanded(child: allbloodDonorDetails()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddBloodDonorDetails(
                Loc: widget.location,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget allbloodDonorDetails(){
    final themeProvider = Provider.of<ThemeProvider>(context);
    return StreamBuilder(
      stream: bloodDonorStream, 
       builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(child: Text("No Blood Donors Available"));
        }

        // Convert snapshot data to list for sorting
        List<DocumentSnapshot> bloodDonor = snapshot.data.docs;

        

        return ListView.builder(
          itemCount: bloodDonor.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = bloodDonor[index];
            //List<String> skills = List<String>.from(ds["skills"]);
           

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Slidable(
                 startActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.25,
                    children: [
                      CustomSlidableAction(
                        backgroundColor: Colors.green,
                        onPressed: (context) async {
                          final Uri phoneUri = Uri(
                            scheme: 'tel',
                            path: ds["emergencyContact"]["phone"],  // Make sure you're using "contact" instead of "phone" if that's your field name
                          );
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Could not launch phone dialer"),
                              ),
                            );
                          }
                        },
                            child: const Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 30,
                            ),
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
                              final donorId = ds.id;
                              final confirmation = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirm Deletion"),
                                    content: const Text("Are you sure you want to delete this med assistant entry?"),
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
                                  await FirebaseFirestore.instance.collection("bloodDonor").doc(donorId).delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Medical Assistant Details deleted successfully")),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error deleting Medical Assistant Detail: $e")),
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
                        height: 220,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode 
                                ?Colors.grey[600] 
                                : const Color(0xFFDEEDFC) , // Available in light mode
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
                                  border: Border.all(
                                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.blue[200]!,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: ds["profileImage"] != null && ds["profileImage"].trim().isNotEmpty
                                      ? Image.network(
                                          ds["profileImage"],
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.blue[200],
                                        ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ds["name"],
                                              style: TextStyle(
                                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5,),
                                            Row(
                                              children: [
                                                Text(
                                              "Age: ${ds["age"]}",
                                              style: TextStyle(
                                                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
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
                                            )
                                          ],
                                        ),
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text("${ds["bloodGroup"]}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                                width: 110,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: Colors.purple,
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: Center(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                      child: Text(
                                                        "${ds["donationFrequency"]}",
                                                        style: TextStyle(
                                                          color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
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
                                              color: themeProvider.isDarkMode?Colors.grey.shade800: const Color.fromARGB(255, 62, 64, 231),
                                              borderRadius: BorderRadius.circular(12)
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
                                    const SizedBox(height: 5),
                                      Row(
                                        children: [
                                           Container(
                                              decoration: BoxDecoration(
                                                color:  const Color.fromARGB(255, 175, 3, 60),
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              child: Text(
                                                ds["donationType"],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 30,),
                                            Container(
                                              width: 60,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color:themeProvider.isDarkMode?Colors.grey[800] :const Color.fromARGB(255, 229, 111, 102),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "${ds["weight"]} kg",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,    
                                                  ),
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    const SizedBox(height: 5,),
                                    //const Spacer(),
                                    
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: ds["availability"]["type"] == 'Full time'
                                                ? Colors.green.withOpacity(0.2)
                                                : (themeProvider.isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.white.withOpacity(0.7)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text("${ds["availability"]["status"]}")
                                            ],
                                          ),
                                        ),
                                        if(ds["userId"] == widget.userId)
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
                                                      builder: (context) => EditBloodDonorDetails(
                                                        userId: widget.userId,
                                                        donorId: ds.id,
                                                        bloodDonorData: ds.data() as Map<String, dynamic>,
                                                        location: widget.location,
                                                      )
                                                    )
                                                  );
                                                },
                                              ),
                                            ),
                                          )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => BloodDonorPopScreen(bloodDonorData: ds,)
                                        )
                                      );
                       },
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
}

