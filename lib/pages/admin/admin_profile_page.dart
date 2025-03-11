import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminProfilePage extends StatefulWidget {
  final String userId;
  const AdminProfilePage({super.key, required this.userId});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String? adminName;
  String? dob;
  String? phone;
  String? gender;
  String? selectedLocation;
  String? profileImageUrl;
  String? govtIdUrl;
  String address = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchAdminDetails();
  }

  Future<void> _getAddress(String addressCoords) async {
    try {
      final coords = addressCoords.split(',');
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
          address = " ${place.subLocality}, "
              "${place.locality}, ${place.postalCode}";
        });
      }
    } catch (e) {
      setState(() {
        address = "Could not fetch address";
      });
    }
  }

  Future<void> fetchAdminDetails() async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('adminDetails')
          .doc(widget.userId)
          .get();

      if (adminDoc.exists) {
        setState(() {
          adminName = adminDoc["name"];
          dob = adminDoc["dob"];
          phone = adminDoc["phone"];
          gender = adminDoc["gender"];
          selectedLocation = adminDoc["location"];
          profileImageUrl = adminDoc["profileImageUrl"];
          govtIdUrl = adminDoc["govtIdUrl"];
          
          if (adminDoc["address"] != null) {
            _getAddress(adminDoc["address"]);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin details: $e");
    }
  }


  Future<void> launchPDF(BuildContext context, String pdfUrl) async {
  try {
    final Uri url = Uri.parse(pdfUrl);
    
    // Check if the URL can be launched
    if (await canLaunchUrl(url)) {
      // Launch the URL, preferring external application
      await launchUrl(
        url, 
        mode: LaunchMode.externalApplication
      );
    } else {
      // If launching fails, show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the document'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    // Handle any unexpected errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        duration: Duration(seconds: 3),
      ),
    );
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
        title: const Text(
          "Admin Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[850] : Colors.blue,
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
                    child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? Image.network(
                            profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: Colors.white, size: 80),
                          )
                        : const Icon(Icons.person, color: Colors.white, size: 80),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                children: [
                  Card(
                    color: cardColor,
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminName ?? "Admin",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow("Date of Birth", dob ?? "Not set", themeProvider),
                          _buildInfoRow("Gender", gender ?? "Not set", themeProvider),
                          _buildInfoRow("Phone", phone ?? "Not set", themeProvider),
                          _buildInfoRow("Location", selectedLocation ?? "Not set", themeProvider),
                          _buildInfoRow("Address", address, themeProvider),
                        ],
                      ),
                    ),
                  ),
                  if (govtIdUrl != null && govtIdUrl!.isNotEmpty)
                    Card(
                    color: cardColor,
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Government ID",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => launchPDF(context, govtIdUrl!),
                                  icon: const Icon(Icons.open_in_new,color: Colors.white,),
                                  label: const Text('Open Government ID',style: TextStyle(color: Colors.white),),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(12),
                                    backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
  }
}