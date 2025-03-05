import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

class FireAndSafetyPopScreen extends StatefulWidget {
  final DocumentSnapshot fireAndSafetyData;
  const FireAndSafetyPopScreen({super.key, required this.fireAndSafetyData});

  @override
  State<FireAndSafetyPopScreen> createState() => _FireAndSafetyPopScreenState();
}

class _FireAndSafetyPopScreenState extends State<FireAndSafetyPopScreen> {
  String address = "Loading...";

  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  Future<void> _getAddress() async {
    try {
      final coords = widget.fireAndSafetyData["address"].toString().split(',');
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

  Widget _buildEquipmentCard(String title, List<dynamic> items, Color backgroundColor, ThemeProvider themeProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForEquipmentType(title),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: backgroundColor, width: 1),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  )
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForEquipmentType(String type) {
    switch (type) {
      case 'Basic Equipment':
        return Icons.settings;
      case 'Vehicles':
        return Icons.directions_car;
      case 'Specialized Equipment':
        return Icons.construction;
      default:
        return Icons.category;
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
        title: Text(
          "Fire & Safety Worker Profile",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.white,
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
                  tag: 'fireandsafety_${widget.fireAndSafetyData.id}',
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
                      child: widget.fireAndSafetyData["profileImage"].isNotEmpty
                          ? (widget.fireAndSafetyData["profileImage"].startsWith('/data')
                              ? Image.file(
                                  File(widget.fireAndSafetyData["profileImage"][0]),
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  widget.fireAndSafetyData["profileImage"],
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
                  const SizedBox(height: 30),
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
                          Text(
                            widget.fireAndSafetyData["name"],
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow("Age", "${widget.fireAndSafetyData["age"]} years", themeProvider),
                          _buildInfoRow("Location", address, themeProvider),
                          _buildInfoRow(
                            "Joined",
                            "${widget.fireAndSafetyData["createdAt"]["date"]} at ${widget.fireAndSafetyData["createdAt"]["time"]}",
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            "I am working in ${widget.fireAndSafetyData["Servicename"]} which is a ${widget.fireAndSafetyData["facilityType"]} with ${widget.fireAndSafetyData["experience"]} years of Experience.",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                        widget.fireAndSafetyData["description"],
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
                      "Available Equipment",
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Equipment Cards
                  GridView.count(
                    crossAxisCount: 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    children: [
                      _buildEquipmentCard(
                        "Basic Equipment", 
                        widget.fireAndSafetyData["equipment"]["Basic Equipment"],
                        Colors.green,
                        themeProvider
                      ),
                      _buildEquipmentCard(
                        "Vehicles", 
                        widget.fireAndSafetyData["equipment"]["Vehicles"],
                        const Color.fromARGB(255, 220, 5, 180),
                        themeProvider
                      ),
                      _buildEquipmentCard(
                        "Specialized Equipment", 
                        widget.fireAndSafetyData["equipment"]["Specialized Equipment"],
                        Colors.orange,
                        themeProvider
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.blue,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            "Request Help",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      // Logic for requesting help from Fire & Safety Workers
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}