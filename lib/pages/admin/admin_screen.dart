import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_app/components/nav_bar.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/activity_screen.dart';
import 'package:food_delivery_app/pages/admin/admin_Shelter_Screen.dart';
import 'package:food_delivery_app/pages/admin/admin_notifications.dart';
import 'package:food_delivery_app/pages/admin/admin_profile_page.dart';
import 'package:food_delivery_app/pages/settings_page.dart';
import 'package:provider/provider.dart';

class AdminScreen extends StatefulWidget {
  final String userId;
  final String location;
  const AdminScreen({super.key, required this.userId, required this.location});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with AutomaticKeepAliveClientMixin {
  String? adminName;
  String? profileImageUrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchAdminDetails();
  }

  Future<void> fetchAdminDetails() async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('adminDetails')
          .doc(widget.userId)
          .get();

      if (adminDoc.exists) {
        setState(() {
          adminName = adminDoc["name"] ?? "Admin";
          profileImageUrl = adminDoc["profileImageUrl"] ?? "";
        });
      } else {
        setState(() {
          adminName = "Admin";
          profileImageUrl = "";
        });
      }
    } catch (e) {
      setState(() {
        adminName = "Admin";
        profileImageUrl = "";
      });
      debugPrint("Error fetching admin details: $e");
    }
  }

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    super.build(context);
    List<Widget> pages = [
      DefaultTabController(
        length: 8,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 120,
            automaticallyImplyLeading: false,
            title: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "            Rescue Hub",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminProfilePage(userId: widget.userId),
                          ),
                        );
                      },
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${widget.location} Coordinator Panel",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Welcome, ${adminName ?? 'Admin'}!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor:themeProvider.isDarkMode?Colors.grey[800]: Colors.blue,
            bottom: const TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: "Shelters"),
                Tab(text: "Foods"),
                Tab(text: "Clothes"),
                Tab(text: "Volunteers"),
                Tab(text: "Ambulance"),
                Tab(text: "Medical Assistance"),
                Tab(text: "Fire and Safety"),
                Tab(text: "Blood Donors"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              AdminShelterScreen(userId: widget.userId, location: widget.location),
              const Center(child: Text("Foods Page")),
              const Center(child: Text("Clothes Page")),
              const Center(child: Text("Volunteers Page")),
              const Center(child: Text("Ambulance Page")),
              const Center(child: Text("Medical Assistance Page")),
              const Center(child: Text("Fire and Safety Page")),
              const Center(child: Text("Blood Donors Page")),
            ],
          ),
        ),
      ),
      ActivityScreen(userId: widget.userId),
      AdminNotifications(UserId: widget.userId,),
      SettingsPage(),
    ];

    return Scaffold(
      bottomNavigationBar: NavBar(onTabChange: navigateBottomBar),
      body: pages[_selectedIndex],
    );
  }
}