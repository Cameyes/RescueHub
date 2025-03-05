import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

class BloodDonorPopScreen extends StatefulWidget {
  final DocumentSnapshot bloodDonorData;
  const BloodDonorPopScreen({super.key, required this.bloodDonorData});

  @override
  State<BloodDonorPopScreen> createState() => _BloodDonorPopScreenState();
}

class _BloodDonorPopScreenState extends State<BloodDonorPopScreen> {
  String address = "Loading...";
  int selectedRating = 5;

  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  Future<void> _getAddress() async {
    try {
      final coords = widget.bloodDonorData["address"].toString().split(',');
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
        title: const Text(
          "Blood Donor Profile",
          style: TextStyle(
            color: Colors.white,
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
                  tag: 'donor_${widget.bloodDonorData.id}',
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
                      child: widget.bloodDonorData["profileImage"].isNotEmpty
                          ? Image.network(
                              widget.bloodDonorData["profileImage"],
                              fit: BoxFit.cover,
                            )
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
                            widget.bloodDonorData["name"],
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow("Age", "${widget.bloodDonorData["age"]} years", themeProvider),
                          _buildInfoRow("Blood Group", widget.bloodDonorData["bloodGroup"], themeProvider),
                          _buildInfoRow("Location", address, themeProvider),
                          _buildInfoRow(
                            "Joined",
                            "${widget.bloodDonorData["createdAt"]["date"]} at ${widget.bloodDonorData["createdAt"]["time"]}",
                            themeProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: cardColor,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Donation Information",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow("Donation Type", widget.bloodDonorData["donationType"], themeProvider),
                          _buildInfoRow("Donation Frequency", widget.bloodDonorData["donationFrequency"], themeProvider),
                          if (widget.bloodDonorData["lastDonationDate"] != "")
                            _buildInfoRow(
                              "Last Donation",
                              widget.bloodDonorData["lastDonationDate"],
                              themeProvider,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: cardColor,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Availability",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            "Status",
                            widget.bloodDonorData["availability"]["status"],
                            themeProvider,
                          ),
                          if (widget.bloodDonorData["availability"]["timeSlots"].length > 0)
                            _buildInfoRow(
                              "Preferred Times",
                              widget.bloodDonorData["availability"]["timeSlots"].join(", "),
                              themeProvider,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GestureDetector(
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.blue,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            "Request Blood Donation",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        // Add your blood donation request logic here
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}