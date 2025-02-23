import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
                                  .collection('ambulance')
                                  .doc(widget.ambulanceData.id)
                                  .collection('reviews')
                                  .orderBy('timestamp', descending: true)
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
                                      future: Future.wait([
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(review['userId'])
                                            .get(),
                                        FirebaseFirestore.instance
                                            .collection('Profile')
                                            .doc(review['userId'])
                                            .get(),
                                      ]),
                                      builder: (context, AsyncSnapshot<List<DocumentSnapshot>> userSnapshot) {
                                        if (!userSnapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        final userData = userSnapshot.data![0].data() as Map<String, dynamic>;
                                        final profileData = userSnapshot.data![1].data() as Map<String, dynamic>?;
                                        
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundImage: profileData != null && profileData['Image'] != null
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
                                                        userData['name'] ?? 'Unknown User',
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
                                      .collection('ambulance')
                                      .doc(widget.ambulanceData.id)
                                      .collection('reviews')
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
                                      .collection('ambulance')
                                      .doc(widget.ambulanceData.id)
                                      .collection('reviews')
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