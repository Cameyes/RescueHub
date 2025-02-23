import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/add_ambulance_details.dart';
import 'package:food_delivery_app/pages/ambulance_pop_screen.dart';
import 'package:food_delivery_app/pages/edit_ambulance_details.dart';
import 'package:food_delivery_app/pages/map_screen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AmbulancePage extends StatefulWidget {

  final String userId;
  final String location;

  const AmbulancePage({super.key,required this.userId, required this.location});

  @override
  State<AmbulancePage> createState() => _AmbulancePageState();
}

class _AmbulancePageState extends State<AmbulancePage> with SingleTickerProviderStateMixin {

   Stream? ambulanceStream;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    fetchAmbulance();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_blinkController);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> fetchAmbulance() async {
    ambulanceStream = FirebaseFirestore.instance
        .collection("ambulance")
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
            Expanded(child:allAmbulanceDetails() ),
        ],
       ),
       floatingActionButton: FloatingActionButton(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAmbulanceDetails(
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


  Widget allAmbulanceDetails() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return StreamBuilder(
      stream: ambulanceStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(child: Text("No Ambulances Available"));
        }

        // Convert snapshot data to list for sorting
        List<DocumentSnapshot> ambulances = snapshot.data.docs;

        // Sort ambulances based on availability
        ambulances.sort((a, b) {
          bool isActiveA = a["status"] == "active";
          bool isActiveB = b["status"] == "active";
          bool isAvailableA = isActiveA && (a["availability"]["type"] == "Full Time" || isCurrentlyAvailable(a["availability"]));
          bool isAvailableB = isActiveB && (b["availability"]["type"] == "Full Time" || isCurrentlyAvailable(b["availability"]));

          // Check if all ambulances are available
          bool allAvailable = ambulances.every((ambulance) {
            bool isActive = ambulance["status"] == "active";
            return isActive && (ambulance["availability"]["type"] == "Full Time" || 
                   isCurrentlyAvailable(ambulance["availability"]));
          });

          // If all ambulances are available, sort by creation time
          if (allAvailable) {
            Timestamp createdAtA = a["lastUpdated"] is Timestamp 
    ? a["lastUpdated"] 
    : Timestamp.now();

Timestamp createdAtB = b["lastUpdated"] is Timestamp 
    ? b["lastUpdated"] 
    : Timestamp.now();

return createdAtA.compareTo(createdAtB);
          }

          // Otherwise, sort available (green) ambulances first
          if (isAvailableA && !isAvailableB) return -1;
          if (!isAvailableA && isAvailableB) return 1;

          // If neither is available, sort by creation time
          return (a["createdAt"] as Timestamp)
              .compareTo(b["createdAt"] as Timestamp);
        });

        return ListView.builder(
          itemCount: ambulances.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = ambulances[index];
            //List<String> skills = List<String>.from(ds["skills"]);
            bool isActive = ds["status"] == "active";
            bool isAvailable = isCurrentlyAvailable(ds["availability"]);

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
                            path: ds["contact"],  // Make sure you're using "contact" instead of "phone" if that's your field name
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
                        height: 230,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode 
                            ? (isActive && (ds["availability"]["type"] == "Full Time" || isAvailable))
                                ? Colors.grey[600]  // Available in dark mode
                                : Colors.grey[800]  // Unavailable in dark mode
                            : (isActive && (ds["availability"]["type"] == "Full Time" || isAvailable))
                                ? const Color(0xFFDEEDFC)  // Available in light mode
                                : Colors.grey[300],
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
                                    Text(
                                      ds["name"],
                                      style: TextStyle(
                                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    //const SizedBox(height: 8),
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
                                              String addressString = ds['Address'];
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
                                            height: 24,
                                            width: 70,
                                            decoration: BoxDecoration(
                                              color: themeProvider.isDarkMode?
                                              Colors.grey[600]
                                              :ds["lictype"]=="Heavy"?
                                              Colors.red
                                              :Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                ds["lictype"],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 40,),
                                          Container(
                                            height: 24,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: themeProvider.isDarkMode?
                                              Colors.grey[600]
                                              :Colors.deepOrange,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "${ds["experience"]} Years",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                    ),
                                    const SizedBox(height: 10,),
                                    //const Spacer(),
                                    //Adding Review viewing section
                                    FutureBuilder(
                                              future: FirebaseFirestore.instance
                                              .collection('ambulance')
                                              .doc(ds.id)
                                              .collection('reviews')
                                              .get(), 
                                              builder: (
                                                context,
                                                AsyncSnapshot<QuerySnapshot>
                                                reviewSnapshot){
                                                  if(reviewSnapshot.connectionState==ConnectionState.waiting){
                                                    return const Text(
                                                      "Loading...",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                      ),
                                                    );
                                                  }

                                                  if(reviewSnapshot.hasData){
                                                    final reviews=reviewSnapshot.data!.docs;
                                                    if(reviews.isEmpty){
                                                      return Text(
                                                        "(No Reviews)",
                                                        style: TextStyle(
                                                          color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                                          fontSize: 16,
                                                        ),
                                                      );
                                                    }
                                                    
                                                    
                                                  double avgRating = reviews
                                                          .map((doc) =>
                                                              doc['rating'] as int)
                                                          .reduce((a, b) => a + b) /
                                                      reviews.length;

                                                      return Row(
                                                        children: [
                                                          Text(
                                                            avgRating.toStringAsFixed(1),
                                                            style:  TextStyle(
                                                             color:themeProvider.isDarkMode?Colors.white: Colors.orange,
                                                             fontSize: 16,
                                                             fontWeight: FontWeight.bold,                  
                                                            ),
                                                          ),
                                                          const SizedBox(width: 5,),
                                                          Row(
                                                            children: List.generate(5, (index){
                                                              if(index <avgRating.floor())
                                                              {
                                                                return  Icon(Icons.star,color:themeProvider.isDarkMode?Colors.white: Colors.orange,size: 16,);                                                        
                                                              }
                                                              else if (index < avgRating && avgRating - index >= 0.5) {
                                                                return  Icon(Icons.star_half, color: themeProvider.isDarkMode?Colors.white: Colors.orange, size: 16);
                                                              } 
                                                              else {
                                                                  return const Icon(Icons.star_border, color: Colors.grey, size: 16);
                                                                }
                                                            })
                                                          ),
                                                          Text("(${reviews.length})",
                                                          style: TextStyle(
                                                            color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                                            fontSize: 16,
                                                          ),),
                                                        ],             
                                                      );

                                                  }

                                                    return Text(
                                                      "(No Reviews)",
                                                      style: TextStyle(
                                                        color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                                        fontSize: 16,
                                                      ),
                                                    );       
                                                }),
                                                const SizedBox(height: 9,),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: ds["availability"]["type"] == 'Full time'
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
                                                ds["availability"]["type"] == 'Full Time'
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
                                                      builder: (context) => EditAmbulanceDetails(
                                                        userId: widget.userId,
                                                        ambulanceId: ds.id,
                                                        ambulanceData: ds.data() as Map<String, dynamic>,
                                                        //location: widget.location,
                                                      )
                                                    )
                                                  );
                                                },
                                              ),
                                            ),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 7,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ds["ambAvail"]=="Own Vehicle"?
                                        Icon(FontAwesomeIcons.truckMedical,size: 12,):
                                        Icon(FontAwesomeIcons.hospital),
                                        const SizedBox(width: 10,),
                                        Text("${ds["ambAvail"]}",
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode?Colors.white:Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),)
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        bool isActive = ds["status"] == "active";
                        bool isAvailable = isActive && (ds["availability"]["type"] == "Full Time" || isCurrentlyAvailable(ds["availability"]));
                        
                        if (isAvailable) {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => AmbulancePopScreen(ambulanceData: ds)
                            )
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Driver Unavailable"),
                                content: const Text("This ambulance is currently not available for service."),
                                actions: [
                                  TextButton(
                                    child: const Text("Okay"),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                          );
                        }
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
                              ? (ds["availability"]["type"] == "Full Time" || isCurrentlyAvailable(ds["availability"]))
                                  ? Colors.green 
                                  : Colors.red
                              : Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: (isActive && (ds["availability"]["type"] == "Full Time" || isCurrentlyAvailable(ds["availability"]))) 
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
}