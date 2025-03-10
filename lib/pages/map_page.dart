import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/activity_screen.dart';
import 'package:food_delivery_app/pages/add_cloth_details.dart';
import 'package:food_delivery_app/pages/add_details.dart';
import 'package:food_delivery_app/pages/add_food_details.dart';
import 'package:food_delivery_app/pages/ambulance_page.dart';
import 'package:food_delivery_app/pages/blood_donor_page.dart';
import 'package:food_delivery_app/pages/distance_data.dart';
import 'package:food_delivery_app/pages/edit_cloth_details.dart';
import 'package:food_delivery_app/pages/edit_food_details.dart';
import 'package:food_delivery_app/pages/edit_shelter_details.dart';
import 'package:food_delivery_app/pages/fire_and_safety_page.dart';

import 'package:food_delivery_app/pages/location_selector.dart';
import 'package:food_delivery_app/pages/map_screen.dart';
import 'package:food_delivery_app/pages/medical_assistance_page.dart';
import 'package:food_delivery_app/pages/notifications_page.dart';
import 'package:food_delivery_app/pages/preparedness_page.dart';
import 'package:food_delivery_app/pages/profile_page.dart';
import 'package:food_delivery_app/pages/settings_page.dart';
import 'package:food_delivery_app/pages/volunteer_page.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/language_provider.dart';
import 'package:food_delivery_app/service/translation_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';


class MapPage extends StatefulWidget {
  final String userId;
  final String selectedLoc;
  final bool showTutorial;
  const MapPage({super.key, required this.userId, required this.selectedLoc, this.showTutorial = false});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {

  String? UserName;
  String? UserEmail;
  Stream<DocumentSnapshot<Map<String,dynamic>>>? userProfileStream;
  @override
  bool get wantKeepAlive => true;

  String selectedLoc = "Thrissur";
  String selectedpref = "Females Only";
  String selectedGender = "Male";
  String? profileImageUrl;
  File? selectedImage_one;
  File? selectedImage_two;

  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController sizeController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  Stream? shelterStream;
  Stream? foodStream;
  Stream? clothStream;

  int _selectedIndex = 0;

  Future<Map<String, String>> translateSnapshotData(Map<String, dynamic> data, String targetLanguage) async {
  final translationService = TranslationService();
  Map<String, String> translatedData = {};

  // Fields to translate
  final fieldsToTranslate = [
    'Name',
    'Description',
    'Address',
    'Preference',
    'Size',
    'Type',
    'Quantity',
    'HouseName',
    'Gender',
    'ClothName',
    'FoodName',
    
    // Add other fields that need translation
  ];

  for (var field in fieldsToTranslate) {
    if (data[field] != null && data[field].toString().isNotEmpty) {
      try {
        String translated = await translationService.translateText(
          data[field].toString(),
          targetLanguage
        );
        translatedData[field] = translated;
      } catch (e) {
        print('Translation error for $field: $e');
        translatedData[field] = data[field].toString();
      }
    }
  }
  return translatedData;
}

 Future<void> _checkExpiredFood() async {
    try {
      await DatabaseMethods().checkAndDeleteExpiredFood();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking expired food: $e')),
        );
      }
    }
 }
  

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        initializeUserProfileStream();
      }
    });
  }

  Future<void> getontheload(String location) async {
    foodStream = await DatabaseMethods().getfoodDetails(location: location,);
    shelterStream = await DatabaseMethods().getshelterDetails(location: location);
    clothStream = await DatabaseMethods().getclothDetails(location: location,);
    setState(() {});
  }

  void initializeUserProfileStream() {
    userProfileStream = DatabaseMethods()
        .getUserProfile(widget.userId)
        .asStream()
        .asBroadcastStream()
        .map((future)=>future as DocumentSnapshot<Map<String,dynamic>>);
  }

  

  @override
  void initState() {
    super.initState();
    
    selectedLoc = widget.selectedLoc;
    initializeUserProfileStream();
    getontheload(selectedLoc);
    _loadProfileImage();
    _checkExpiredFood();

    userProfileStream?.listen((snapshot){
      if(snapshot.exists){
        final data=snapshot.data();
        setState(() {
          UserName=data?['name'];
          UserEmail=data?['email'];
        });
      }
    });
  }

  

  Future<void> _loadProfileImage() async{
    try{
      DocumentSnapshot userDoc=await FirebaseFirestore.instance
      .collection('Profile')
      .doc(widget.userId)
      .get();

      if(userDoc.exists)
      { 
        Map<String,dynamic> data=userDoc.data() as Map<String,dynamic>;
        setState(() {
          profileImageUrl=data['Image'];
        });
      }
    } catch(e){
      print("Error laoding Profile Image : $e");
    }
  }

 Widget userProfileSection(BuildContext context) {
  final languageProvider = Provider.of<LanguageProvider>(context);

  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: userProfileStream,
    builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      } else if (snapshot.hasData && snapshot.data != null) {
        final userProfile = snapshot.data!;
        final welcomeText = languageProvider.translations['welcome'] ?? "Welcome";

        return Column(
          children: [
            Text(
              "$welcomeText, ${userProfile['name']}!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Uncomment the following line if you want to display the email
            // Text("Email: ${userProfile['email']}"),
          ],
        );
      } else {
        return const Center(child: Text("No Data Available"));
      }
    },
  );
}


  Map<String, Map<String, Widget>> locationContent(String userId) {
    return {
      "Thrissur": {
        "Shelter": allShelterDetails(userId),
        "Food": allfoodDetails(userId),
        "Cloth": allclothDetails(userId),
        "Volunteer":VolunteerPage(userId: widget.userId,location: selectedLoc,),
        "Ambulance":AmbulancePage(userId:widget.userId ,location: selectedLoc,),
        "Medical Assistance":MedicalAssistancePage(userId: widget.userId,location: widget.selectedLoc,),
        "Fire and Safety":FireAndSafetyPage(userId: widget.userId,location:  "Thrissur"),
        "Blood Donors":BloodDonorPage(userId: widget.userId, location: "Thrissur"),
        "Preparedness":PreparednessScreen(location: "Thrissur",),
      },
      "Palakkad": {
        "Shelter": allShelterDetails(userId),
        "Food": allfoodDetails(userId),
        "Cloth": allclothDetails(userId),
        "Volunteer":VolunteerPage(userId: widget.userId,location: selectedLoc,),
        "Ambulance":AmbulancePage(userId:widget.userId ,location: selectedLoc,),
        "Medical Assistance":MedicalAssistancePage(userId: widget.userId,location: widget.selectedLoc,),
        "Fire and Safety":FireAndSafetyPage(userId: widget.userId,location: "Palakkad"),
        "Blood Donors":BloodDonorPage(userId: widget.userId, location: "Palakkad"),
        "Preparedness":PreparednessScreen(location: "Palakkad"),
      },
      "Eranakulam": {
        "Shelter": allShelterDetails(userId),
        "Food": allfoodDetails(userId),
        "Cloth": allclothDetails(userId),
        "Volunteer":VolunteerPage(userId: widget.userId,location: selectedLoc,),
        "Ambulance":AmbulancePage(userId:widget.userId ,location: selectedLoc,),
        "Medical Assistance":MedicalAssistancePage(userId: widget.userId,location: widget.selectedLoc,),
        "Fire and Safety":FireAndSafetyPage(userId: widget.userId,location:  "Eranakulam"),
        "Blood Donors":BloodDonorPage(userId: widget.userId, location: "Eranakulam"),
        "Preparedness":PreparednessScreen(location: "Eranakulam"),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
     final themeProvider = Provider.of<ThemeProvider>(context);
     final languageProvider=Provider.of<LanguageProvider>(context);
    List<Widget> pages = [
      DefaultTabController(
        length: 9,
        child: Scaffold(
         appBar: AppBar(
  toolbarHeight: 120,
  automaticallyImplyLeading: false,
  title: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.userId,InitialName: UserName,InitialEmail: UserEmail,)));
              _loadProfileImage();
            },
            child: Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              child: ClipOval(
                child: profileImageUrl != null && profileImageUrl!.trim().isNotEmpty
                    ? Image.network(
                        profileImageUrl!,
                        fit: BoxFit.fill,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Colors.white),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location selector and text wrapped together
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.location_on, color: Colors.white),
                onPressed: () async {
                  final selectedLocation = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LocationSelector(initialLocation: selectedLoc),
                    ),
                  );
                  
                  if (selectedLocation != null) {
                    setState(() {
                      selectedLoc = selectedLocation;
                      getontheload(selectedLoc);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select a location.")),
                    );
                  }
                },
              ),
              Text(
                selectedLoc,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Welcome message on the right
          Row(
            children: [
              const Icon(Icons.near_me_rounded,color: Colors.white,),
              const SizedBox(width:10),
              userProfileSection(context),
            ],
          ),
        ],
      ),
    ],
  ),
  backgroundColor: themeProvider.isDarkMode?Colors.grey[900]: Colors.blue,
  bottom: TabBar(
    isScrollable: true,
    labelColor: Colors.white,
    indicatorColor: Colors.white,
    tabs: [
     SizedBox(
      width: 120, // Width for Shelter tab
    
      child: Tab(text: languageProvider.translations['shelter']??"Shelters"),
    ),
      SizedBox(
        width: 120,
        child:  Tab(text:languageProvider.translations['food']??"Foods")),
       SizedBox(
        width: 120,
        child: Tab(text:languageProvider.translations['cloth']?? "Clothes")),
       SizedBox(
        width: 150,
        child: Tab(text:languageProvider.translations['volunteer']??"Volunteers")),
        SizedBox(
        width: 150,
        child: Tab(text:languageProvider.translations['ambulance']??"Ambulance")),
        SizedBox(
        width: 150,
        child: Tab(text:languageProvider.translations['medical']??"Medical Assistance")),
        SizedBox(
      width: 120, // Width for Shelter tab
    
      child: Tab(text: languageProvider.translations['fire']??"Fire and Safety"),
    ),
         SizedBox(
        width: 120,
        child:  Tab(text:languageProvider.translations['blood']??"Blood Donors")),
        SizedBox(
        width: 120,
        child:  Tab(text:languageProvider.translations['preparedness']??"Preparedness")),
    ],
  ),
),
          backgroundColor:themeProvider.isDarkMode?const Color.fromARGB(255, 50, 49, 49): Colors.white,
          body: Column(
            children: [
              //userProfileSection(),
              Expanded(
                child: TabBarView(
                  children: [
                    locationContent(widget.userId)[selectedLoc]?["Shelter"] ??
                        const Center(child: Text("No Shelter data available")),
                    locationContent(widget.userId)[selectedLoc]?["Food"] ??
                        const Center(child: Text("No Food data available")),
                    locationContent(widget.userId)[selectedLoc]?["Cloth"] ??
                        const Center(child: Text("No Cloth data available")),
                    locationContent(widget.userId)[selectedLoc]?["Volunteer"] ??
                        const Center(child: Text("No Volunteer data Available"),),
                    locationContent(widget.userId)[selectedLoc]?["Ambulance"] ??
                        const Center(child: Text("No Ambulance data Available"),),
                    locationContent(widget.userId)[selectedLoc]?["Medical Assistance"] ??
                        const Center(child: Text("No  Medical Assistance data Available"),),
                         locationContent(widget.userId)[selectedLoc]?["Fire and Safety"] ??
                        const Center(child: Text("No Fire and Safety Assistants available")),
                    locationContent(widget.userId)[selectedLoc]?["Blood Donors"] ??
                        const Center(child: Text("No  Blood Donor data Available"),),
                    locationContent(widget.userId)[selectedLoc]?["Preparedness"] ??
                        const Center(child: Text("No  Preparedness data Available"),),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ActivityScreen(userId:widget.userId),
       NotificationsPage(userId: widget.userId,),
      const SettingsPage(),
    ];

    return Scaffold(
      bottomNavigationBar: NavBar(onTabChange: navigateBottomBar),
      body: pages[_selectedIndex],
    );
  }




Widget allShelterDetails(String userId) {
   final themeProvider = Provider.of<ThemeProvider>(context);
   final languageProvider = Provider.of<LanguageProvider>(context);
   final targetLanguage = languageProvider.currentLocale.languageCode;
   final bool isEnglish = targetLanguage == 'en';
   final double fontSize = isEnglish ? 18.0 : 17.0;
   
  return Stack(
    children: [
      StreamBuilder(
        stream: shelterStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return FutureBuilder<Map<String, String>>(
                      future: translateSnapshotData(
                          ds.data() as Map<String, dynamic>,
                          targetLanguage
                      ),
                      builder: (context, translationSnapshot){
                         if (!translationSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final translatedData = translationSnapshot.data!;
                          final storedDistance = ds['distance'] ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child:  Slidable(
                            endActionPane: ds["UserId"]==userId 
                            ?ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.25,
                              children: [
                                CustomSlidableAction(
                                  backgroundColor:themeProvider.isDarkMode? Colors.grey.shade400:Colors.red,
                                  onPressed: (context) async{
                                     final shelterId = ds.id;
                                    final confirmation = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirm Deletion"),
                                          content: const Text("Are you sure you want to delete this shelter?"),
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
                                        await DatabaseMethods().deleteshelterDetail(shelterId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Shelter deleted successfully")),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error deleting shelter: $e")),
                                        );
                                      }
                                    }
                                  },
                                  child:  Icon(
                                    Icons.delete,
                                    color:themeProvider.isDarkMode?Colors.black: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            )
                            :null,
                            child: GestureDetector(
                              child: Material(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:themeProvider.isDarkMode?Colors.grey[600] : Color(0xFFDEEDFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  width: double.infinity,
                                  height: 200,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color:  Colors.grey,
                                            border: Border.all(color: Colors.white),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: ds["Images"].isNotEmpty
                                                ? (ds["Images"][0].startsWith('http') 
                                                    ? Image.network(
                                                        ds["Images"][0],
                                                        fit: BoxFit.fill,
                                                        width: 100,
                                                        height: 100,
                                                      )
                                                    : const Icon(
                                                        Icons.image,
                                                        color: Colors.white,
                                                        size: 50,
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
                                        padding: const EdgeInsets.only(top: 20.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                 Text(
                                                    translatedData['Name'] ?? ds['Name'],
                                                    style: TextStyle(
                                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                                      fontSize: fontSize,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  "${ds["Age"]}",
                                                  style: TextStyle(
                                                    color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 15),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: "${ds["Gender"]}" == "Male"
                                                        ? Colors.blue
                                                        : const Color.fromARGB(255, 236, 52, 113),
                                                    borderRadius: BorderRadius.circular(15),
                                                    border: Border.all(color: Colors.white),
                                                  ),
                                                  width: 70,
                                                  child: Center(
                                                    child: Text(
                                                       translatedData['Gender'] ?? ds['Gender'],
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: targetLanguage=='ml'?14.0:17.0,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              translatedData['HouseName'] ?? ds['HouseName'],
                                              style: TextStyle(
                                                color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            
                                            Row(
                                              children: [
                                                Text(
                                                  "Fit for: ${ds["Size"]}",
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 10,),
                                                FutureBuilder(
                                                  future: FirebaseFirestore.instance
                                                  .collection('shelter')
                                                  .doc(ds.id)
                                                  .collection('reviews')
                                                  .get(), 
                                                  builder: (
                                                    context,
                                                    AsyncSnapshot<QuerySnapshot>
                                                    reviewSnapshot){
                                                      if(reviewSnapshot.connectionState==ConnectionState.waiting){
                                                        return Text(
                                                          "Loading...",
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: fontSize - 2,
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
                                                              fontSize: fontSize - 2,
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
                                                                style: TextStyle(
                                                                 color:themeProvider.isDarkMode?Colors.white: Colors.orange,
                                                                 fontSize: fontSize - 2,
                                                                 fontWeight: FontWeight.bold,                  
                                                                ),
                                                              ),
                                                              const SizedBox(width: 5,),
                                                              Row(
                                                                children: List.generate(5, (index){
                                                                  if(index <avgRating.floor())
                                                                  {
                                                                    return Icon(Icons.star,color:themeProvider.isDarkMode?Colors.white: Colors.orange,size: fontSize - 2,);                                                        
                                                                  }
                                                                  else if (index < avgRating && avgRating - index >= 0.5) {
                                                                    return Icon(Icons.star_half, color: themeProvider.isDarkMode?Colors.white: Colors.orange, size: fontSize - 2);
                                                                  } 
                                                                  else {
                                                                      return Icon(Icons.star_border, color: Colors.grey, size: fontSize - 2);
                                                                    }
                                                                })
                                                              ),
                                                              Text(
                                                                "(${reviews.length})",
                                                                style: TextStyle(
                                                                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                                                  fontSize: fontSize - 2,
                                                                ),
                                                              ),
                                                            ],             
                                                          );
                                                      }
                        
                                                        return Text(
                                                          "(No Reviews)",
                                                          style: TextStyle(
                                                            color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                                            fontSize: fontSize - 2,
                                                          ),
                                                        );       
                                                    })
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                   languageProvider.translations['preference']??"Preference "": ${ds["Size"]}",
                                                  style: TextStyle(
                                                    color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width:12),
                                                Text(
                                                  translatedData['Preference'] ?? ds['Preference'],
                                                  style: TextStyle(
                                                    color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 5),
                                            SizedBox(
                                              height: 40,
                                              width: 40,
                                              child: FloatingActionButton(
                                                backgroundColor: themeProvider.isDarkMode?Colors.grey.shade800: const Color.fromARGB(255, 62, 64, 231),
                                                elevation: 5,
                                                child: const Icon(
                                                  Icons.directions,
                                                  size: 30,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () async {
                                                          try {
                                                            String addressString = ds['Address'];
                                                            List<String> latLng = addressString.split(',');
                                                            double shelterLat = double.parse(latLng[0].trim());
                                                            double shelterLng = double.parse(latLng[1].trim());
                        
                                                            DocumentSnapshot userProfile = await FirebaseFirestore.instance
                                                                .collection("Profile")
                                                                .doc(userId)
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

                                                                await FirebaseFirestore.instance
                                                                    .collection('shelter')
                                                                    .doc(ds.id)
                                                                    .update({'distance': distanceInKm});
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
                                                                    shelterId: ds["Id"],
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
                                            ),
                                            const SizedBox(height: 20),
                                            
                                            const SizedBox(height: 15),
                                            GestureDetector(
                                              child: ds['UserId'] == userId
                                                  ? Container(
                                                      height: 40,
                                                      width: 40,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                      ),
                                                      child: const Icon(
                                                        Icons.edit,
                                                        color: Colors.black,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => EditDetails(
                                                      shelterData: ds,
                                                      userId: userId,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              onTap: () async{
                                final distance = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PopScreen(
                                      shelterData: ds,
                                    ),
                                  ),
                                );
                                  if (distance != null) {
                                       await FirebaseFirestore.instance
                                        .collection('shelter')
                                        .doc(ds.id)
                                        .update({'distance': distance});
                                  setState(() {
                                shelterStream = DatabaseMethods().getshelterDetails(location: selectedLoc) as Stream?;
                                  });
                                }
                              },
                            ),
                          ),
                        );
                    },
                    );
                  },
                )
              : Container();
        },
      ),
      Positioned(
        bottom: 20,
        right: 20,
        child: FloatingActionButton(
          backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800:  Colors.blue,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddDetails(
                        Loc: selectedLoc,
                        userId: userId,
                      )),
            );
          },
        ),
      ),
    ],
  );
}

Widget allfoodDetails(String userId){
  final themeProvider = Provider.of<ThemeProvider>(context);
    return Stack(
      children: [
          StreamBuilder(
          stream: foodStream, 
          builder: (context, AsyncSnapshot snapshot){
            return snapshot.hasData
            ?ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context,index){
                DocumentSnapshot ds=snapshot.data.docs[index];
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Slidable(
                    endActionPane: ds["UserId"]==userId
                    ?ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.25,
                      children: [
                        CustomSlidableAction(
                          backgroundColor: themeProvider.isDarkMode?Colors.grey.shade400: Colors.red,
                          onPressed: (context) async{
                            final foodId=ds.id;
                            final confirmation=await showDialog(
                              context: context, 
                              builder: (BuildContext context){
                                return AlertDialog(
                                  title: const Text("Confirm Deletion"),
                                  content: const Text("Are you sure you want to delete this food item?"),
                                   actions: [
                                   TextButton(
                                      onPressed: ()=>Navigator.of(context).pop(false),
                                     child: const Text("Cancel")
                                     ),
                                     TextButton(
                                      onPressed: ()=>Navigator.of(context).pop(true),
                                     child: const Text("Delete")
                                     )
                                  ],
                                );
                              });

                              if(confirmation == true){
                                try{
                                  await DatabaseMethods().deletefoodDetail(foodId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Food Item deleted successfully")),
                                    );
                                }
                                catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error deleting Food Item: $e")),
                                    );
                                  }
                              }
                          }, 
                          child:  Icon(
                            Icons.delete,
                            color:themeProvider.isDarkMode?Colors.black:  Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ):null,
                    child: GestureDetector(
                      child: Material(
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode?Colors.grey[600] : Color(
                                      0xFFDEEDFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          width: double.infinity,
                          height: 200,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    //shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white)
                                  ),
                                  child: ClipRRect(
                                    child: ds["Images"][0].isNotEmpty
                                      ? (ds["Images"][0].startsWith('/data') 
                                                  ? Image.file(
                                        File(ds["Images"][0]),
                                        fit: BoxFit.fill,
                                        width: 100,
                                        height: 100,
                                          )
                                        : Image.network(
                                          ds["Images"][0],
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
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10,),
                                    Row(
                                      children: [
                                         Text("${ds["FoodName"]}",
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),),
                                        const SizedBox(width: 20,),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: "${ds["Type"]}"=="Veg"?Colors.green[800]:Colors.red,
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(color: Colors.white)
                                          ),
                                         width: 100,
                                          child:  Center(
                                            child: Text("${ds["Type"]}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5,),
                                     Text(
                                      "${ds["HouseName"]}",
                                      style: TextStyle(
                                        color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Expiring on : ${DateFormat('MMMM d, y').format((ds["Expirty-Date"] as Timestamp).toDate())}",
                                      style:  TextStyle(
                                        color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                        fontSize: 16.3,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Fit for: ${ds["Size"]}",
                                          style: TextStyle(
                                            color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10,),
                                            FutureBuilder(
                                              future: FirebaseFirestore.instance
                                              .collection('food')
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
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    );
                                                  }

                                                  if(reviewSnapshot.hasData){
                                                    final reviews=reviewSnapshot.data!.docs;
                                                    if(reviews.isEmpty){
                                                      return  Text(
                                                        "(No Reviews)",
                                                        style: TextStyle(
                                                          color: themeProvider.isDarkMode?Colors.white: Colors.black,
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
                                                             color: themeProvider.isDarkMode?Colors.white: Colors.orange,
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
                                                                return  Icon(Icons.star_half, color:themeProvider.isDarkMode?Colors.white: Colors.orange, size: 16);
                                                              } 
                                                              else {
                                                                  return const Icon(Icons.star_border, color: Colors.grey, size: 16);
                                                                }
                                                            })
                                                          ),
                                                          Text("(${reviews.length})",
                                                          style:  TextStyle(
                                                            color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                                            fontSize: 16,
                                                          ),),
                                                        ],             
                                                      );

                                                  }

                                                    return  Text(
                                                      "(No Reviews)",
                                                      style: TextStyle(
                                                        color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                                        fontSize: 16,
                                                      ),
                                                    );       
                                                })

                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5,),
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: FloatingActionButton(
                                        backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: const Color.fromARGB(255, 62, 64, 231),
                                        elevation: 5,
                                        child: const Icon(
                                          Icons.directions,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async{
                                          // Logic to open Google Maps
                                          try {
                                                        // Fetch shelter coordinates
                                                        String addressString = ds['Address'];
                                                        List<String> latLng = addressString.split(',');
                                                        double shelterLat = double.parse(latLng[0].trim());
                                                        double shelterLng = double.parse(latLng[1].trim());

                                                        // Fetch user coordinates from Profile collection
                                                        DocumentSnapshot userProfile = await FirebaseFirestore.instance
                                                            .collection("Profile")
                                                            .doc(userId)
                                                            .get();
                                                        String locationString = userProfile["location"];
                                                        List<String> userlatLng = locationString.split(',');
                                                        double locationLat = double.parse(userlatLng[0].trim());
                                                        double locationLng = double.parse(userlatLng[1].trim());

                                                        // Get the real distance using Google Directions API
                                                        String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc'; // Replace with your actual API key
                                                        String url = 'https://maps.googleapis.com/maps/api/directions/json'
                                                            '?origin=$locationLat,$locationLng'
                                                            '&destination=$shelterLat,$shelterLng'
                                                            '&mode=driving' // Specify travel mode
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

                                                          // Get the actual road distance from the first route
                                                          var route = data['routes'][0]['legs'][0];
                                                          var distanceInMeters = route['distance']['value'];
                                                          var distanceText = route['distance']['text'];
                                                          var durationText = route['duration']['text'];
                                                          var distanceInKm = distanceInMeters / 1000.0;

                                                          // Get the polyline points for the route
                                                          String encodedPoints = data['routes'][0]['overview_polyline']['points'];
                                                          
                                                          // Navigate to the map screen with all route information
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
                                                                shelterId: ds["Id"],
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
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    const SizedBox(height: 55,),
                                    GestureDetector(
                                          child: ds['UserId']==userId
                                          ? Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.black,
                                            ),
                                          ):const SizedBox.shrink(),                                        
                                          onTap: () {
                                            // Logic to open Edit Screen
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditFoodDetails
                                                (foodData:ds ,
                                                 userId: userId)
                                              ),
                                            );
                                          },
                                          
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PopfoodScreen(foodData: ds,),//passing snapShot Details to Another Screen=>Pop Screen Here!
                          ),
                        );
                      },
                    ),
                  ),
                );
              }):Container();
          }),
          //Add Icon in bottom-left corner
          Positioned(bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: themeProvider.isDarkMode?Colors.grey.shade800:  Colors.blue,
            child: const Icon(Icons.add,color: Colors.white,),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddfoodDetails(Loc:selectedLoc,userId: userId,)));
            }))
        ],
    );
  }
  Widget allclothDetails(String userId){
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Stack(
      children: [
          StreamBuilder(
          stream: clothStream, 
          builder: (context, AsyncSnapshot snapshot){
            return snapshot.hasData
            ?ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context,index){
                DocumentSnapshot ds=snapshot.data.docs[index];
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Slidable(
                    endActionPane: ds["UserId"]==userId
                    ?ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.25,
                      children: [
                        CustomSlidableAction(
                          backgroundColor:themeProvider.isDarkMode?Colors.grey.shade400: Colors.red,
                          onPressed: (context) async{
                            final clothId=ds.id;
                            final confirmation=await showDialog(
                              context: context,
                              builder:(BuildContext context){
                                return AlertDialog(
                                  title: const Text("Confirm Deletion"),
                                  content: const Text("Are you Sure you want to Delete this Cloth Item?"),
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
                              }
                            );

                             if (confirmation == true) {
                                  try {
                                    await DatabaseMethods().deleteclothDetail(clothId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Cloth Item deleted successfully")),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error deleting shelter: $e")),
                                    );
                                  }
                                }
                          }, 
                          child:  Icon(
                                Icons.delete,
                                color:themeProvider.isDarkMode?Colors.black: Colors.white,
                                size: 30,
                              ),
                            )
                      ],
                    ):null,
                    child: GestureDetector(
                      child: Material(
                        child: Container(
                          decoration: BoxDecoration(
                            color:themeProvider.isDarkMode?Colors.grey[600] : Color(
                                      0xFFDEEDFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          width: double.infinity,
                          height: 200,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    //shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white)
                                  ),
                                  child: ClipRRect(
                                    child: ds["Images"][0].isNotEmpty
                                      ? (ds["Images"][0].startsWith('/data') 
                                                  ? Image.file(
                                        File(ds["Images"][0]),
                                        fit: BoxFit.fill,
                                        width: 100,
                                        height: 100,
                                          )
                                        : Image.network(
                                          ds["Images"][0],
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
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10,),
                                    Row(
                                      children: [
                                         Text("${ds["ClothName"]}",
                                        style: TextStyle(
                                          color:  themeProvider.isDarkMode?Colors.white: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),),
                                         const SizedBox(width: 15,),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: ds["Gender"] == "Male"
                                              ? Colors.blue
                                              : ds["Gender"] == "Female"
                                            ? const Color.fromARGB(255, 236, 52, 113)
                                            : Colors.grey,
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(color: Colors.white)
                                          ),
                                         width: 70,
                                          child:  Center(
                                            child: Text("${ds["Gender"]}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5,),
                                     Text(
                                      "${ds["HouseName"]}",
                                      style:  TextStyle(
                                        color:  themeProvider.isDarkMode?Colors.white: Colors.black,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${ds["Address"]}",
                                      style:  TextStyle(
                                        color:  themeProvider.isDarkMode?Colors.white: Colors.black,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Size : ${ds["Size"]}",
                                          style:  TextStyle(
                                            color:  themeProvider.isDarkMode?Colors.white: Colors.black,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10,),
                                            FutureBuilder(
                                              future: FirebaseFirestore.instance
                                              .collection('cloth')
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
                                                      return  Text(
                                                        "(No Reviews)",
                                                        style: TextStyle(
                                                          color:  themeProvider.isDarkMode?Colors.white: Colors.black,
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
                                                                return  Icon(Icons.star_half, color:themeProvider.isDarkMode?Colors.white: Colors.orange, size: 16);
                                                              } 
                                                              else {
                                                                  return const Icon(Icons.star_border, color: Colors.grey, size: 16);
                                                                }
                                                            })
                                                          ),
                                                          Text("(${reviews.length})",
                                                          style:  TextStyle(
                                                            color:  themeProvider.isDarkMode?Colors.white: Colors.black,
                                                            fontSize: 16,
                                                          ),),
                                                        ],             
                                                      );

                                                  }

                                                    return  Text(
                                                      "(No Reviews)",
                                                      style: TextStyle(
                                                        color:  themeProvider.isDarkMode?Colors.white: Colors.black,
                                                        fontSize: 16,
                                                      ),
                                                    );       
                                                })
                                      ],
                                    ),
                                     Text("For : ${ds["Count"]} Persons",
                                    style:  TextStyle(
                                        color:  themeProvider.isDarkMode?Colors.white: Colors.black,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5,),
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: FloatingActionButton(
                                        backgroundColor: themeProvider.isDarkMode?Colors.grey.shade800: const Color.fromARGB(255, 62, 64, 231),                                
                                        elevation: 5,
                                        child: const Icon(
                                          Icons.directions,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          // Logic to open Google Maps
                                           try {
                                                        // Fetch shelter coordinates
                                                        String addressString = ds['Address'];
                                                        List<String> latLng = addressString.split(',');
                                                        double shelterLat = double.parse(latLng[0].trim());
                                                        double shelterLng = double.parse(latLng[1].trim());

                                                        // Fetch user coordinates from Profile collection
                                                        DocumentSnapshot userProfile = await FirebaseFirestore.instance
                                                            .collection("Profile")
                                                            .doc(userId)
                                                            .get();
                                                        String locationString = userProfile["location"];
                                                        List<String> userlatLng = locationString.split(',');
                                                        double locationLat = double.parse(userlatLng[0].trim());
                                                        double locationLng = double.parse(userlatLng[1].trim());

                                                        // Get the real distance using Google Directions API
                                                        String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc'; // Replace with your actual API key
                                                        String url = 'https://maps.googleapis.com/maps/api/directions/json'
                                                            '?origin=$locationLat,$locationLng'
                                                            '&destination=$shelterLat,$shelterLng'
                                                            '&mode=driving' // Specify travel mode
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

                                                          // Get the actual road distance from the first route
                                                          var route = data['routes'][0]['legs'][0];
                                                          var distanceInMeters = route['distance']['value'];
                                                          var distanceText = route['distance']['text'];
                                                          var durationText = route['duration']['text'];
                                                          var distanceInKm = distanceInMeters / 1000.0;

                                                          // Get the polyline points for the route
                                                          String encodedPoints = data['routes'][0]['overview_polyline']['points'];
                                                          
                                                          // Navigate to the map screen with all route information
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
                                                                shelterId: ds["Id"],
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
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    const SizedBox(height: 55,),
                                    GestureDetector(
                                          child: ds['UserId']==userId
                                          ? Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.black,
                                            ),
                                          ):const SizedBox.shrink(),                                        
                                          onTap: () {
                                            // Logic to open Edit Screen
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditClothDetails
                                                (clothData:ds ,
                                                 userId: userId)
                                              ),
                                            );
                                          },
                                          
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PopclothScreen(clothData: ds,),//passing snapShot Details to Another Screen=>Pop Screen Here!
                          ),
                        );
                      },
                    ),
                  ),
                );
              }):Container();
          }),
          //Add Icon in bottom-left corner
          Positioned(bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: Colors.blue,
            child: const Icon(Icons.add,color: Colors.white,),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddclothDetails(Loc:selectedLoc,userId: userId,)));
            }))
        ],
    );
  }

}




class PopScreen extends StatefulWidget {
  final DocumentSnapshot shelterData;

  const PopScreen({super.key,required this.shelterData});

  @override
  State<PopScreen> createState() => _PopScreenState();
}

class _PopScreenState extends State<PopScreen> {

  String address="Loading...";
  final TextEditingController _reviewController=TextEditingController();
  int selectedRating=5;
   Map<String, String>? translatedData;

   @override
  void initState() {
    super.initState();
    _getAddress();
    _translateContent();
  }

  Future<Map<String, DateTime>?> _showBookingDialog(BuildContext context) {
  DateTime? fromDate;
  DateTime? toDate;
  
  return showDialog<Map<String, DateTime>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Select Stay Period'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('From Date'),
                  subtitle: Text(fromDate?.toString().split(' ')[0] ?? 'Select date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      setState(() {
                        fromDate = selected;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('To Date'),
                  subtitle: Text(toDate?.toString().split(' ')[0] ?? 'Select date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    if (fromDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select from date first')),
                      );
                      return;
                    }
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: fromDate!.add(const Duration(days: 1)),
                      firstDate: fromDate!.add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      setState(() {
                        toDate = selected;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Proceed'),
                onPressed: () async {
                 if (fromDate != null && toDate != null) {
                    // Show waiting toast
                    Fluttertoast.showToast(
                      msg: "Waiting for volunteer to accept...",
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                    );
                     // Temporarily remove shelter from list
                    await FirebaseFirestore.instance
                        .collection('shelter')
                        .doc(widget.shelterData.id)
                        .update({'status': 'pending'});

                    Navigator.of(context).pop({
                      'fromDate': fromDate!,
                      'toDate': toDate!,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select both dates')),
                    );
                  }
                },
              ),
            ],
          );
        }
      );
    },
  );
}





Future<void> _handleBooking(BuildContext context, DocumentSnapshot shelterData) async {
  final dates = await _showBookingDialog(context);
  if (dates == null) return;

  try {
    // Get current user details
    final currentUser = FirebaseAuth.instance.currentUser;
    final userProfile = await FirebaseFirestore.instance
        .collection('Profile')
        .doc(currentUser?.uid)
        .get();

        // Get donor's profile details including image
    final donorProfile = await FirebaseFirestore.instance
        .collection('Profile')
        .doc(shelterData['UserId'])
        .get();

    // Get first available volunteer
    final volunteersSnapshot = await FirebaseFirestore.instance
        .collection('volunteer')
        .where('status', isEqualTo: 'active')
        .get();

    if (volunteersSnapshot.docs.isEmpty) {
      throw Exception('No volunteers available');
    }

    // Fetch reviews for the shelter
         final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('shelter')
        .doc(shelterData.id)
        .collection('reviews')
        .get();

        // Convert reviews to a list of maps
    final reviews = reviewsSnapshot.docs.map((doc) => doc.data()).toList();

    //final volunteerData = volunteersSnapshot.docs.first;

    // Create booking data
    final bookingData = {
      'shelterDetails': {
        'houseName': shelterData['HouseName'],
        'description': shelterData['Description'],
        'images': shelterData['Images'],
        'coordinates': shelterData['Address'],
        'fit':shelterData['Size'],
        'preference':shelterData['Preference'],
        'reviews':reviews,
        'shelterId':shelterData['Id'],
        'date':shelterData['Date']
      },
      'donorDetails': {
        'userId': shelterData['UserId'],
        'name': shelterData['Name'],
        'contact': shelterData['Contact'],
        'coordinates':shelterData['Address'],
        'date':shelterData['Date'],
        'profileImage': donorProfile.data()?['Image'] ?? '',
        'age':shelterData['Age'],
         'gender':shelterData['Gender'],
         'Address':shelterData['Address'],
      },
      'requesterDetails': {
        'userId': currentUser?.uid,
        'name': userProfile['Name'],
        'contact': userProfile['Contact'],
        'coordinates': userProfile['location'],
        'profileImage': userProfile['Image'] ?? '',
        'age':userProfile['Age'],
        'gender':userProfile['Gender'],
        'Address':userProfile['Address'],
      },
      'stayPeriod': {
        'fromDate': dates['fromDate'],
        'toDate': dates['toDate'],
      },
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'district':shelterData['Location'],
      'distance':shelterData['distance'],
    };

  // Start volunteer request process
    bool volunteerFound = await _requestVolunteer(
      bookingData, 
      volunteersSnapshot.docs, 
      0
    );

    if (!volunteerFound) {

      // Reset shelter status if no volunteer accepts
      await FirebaseFirestore.instance
          .collection('shelter')
          .doc(shelterData.id)
          .update({'status': 'not booked'});

      // Handle case when no volunteer accepts
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No volunteer available at the moment. Please try again later.')),
      );
      return;
    }

    // If volunteer accepts, show success message
    Fluttertoast.showToast(
      msg: "Shelter has been requested for booking",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );

    // Update shelter status to booked
    await FirebaseFirestore.instance
        .collection('shelter')
        .doc(shelterData.id)
        .update({'status': 'booked'});



    // Add to adminShelterDetails
    await FirebaseFirestore.instance
        .collection('adminShelterDetails')
        .add(bookingData);

     // Add notification
    await _addNotification(currentUser!.uid, shelterData['Location']);

    // Temporarily remove shelter from shelterStream
   /* await FirebaseFirestore.instance
        .collection('shelter')
        .doc(shelterData.id)
        .update({'status': 'booked'});*/

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking request sent successfully')),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

Future<double> _calculateDistance(String location1, String location2) async {
  try {
    // Parse the coordinates
    List<String> coords1 = location1.split(',');
    List<String> coords2 = location2.split(',');
    
    double lat1 = double.parse(coords1[0].trim());
    double lng1 = double.parse(coords1[1].trim());
    double lat2 = double.parse(coords2[0].trim());
    double lng2 = double.parse(coords2[1].trim());

    // Google Maps Directions API request
    String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc';
    String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$lat1,$lng1'
        '&destination=$lat2,$lng2'
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

      // Get the distance in meters and convert to kilometers
      var route = data['routes'][0]['legs'][0];
      var distanceInMeters = route['distance']['value'];
      return distanceInMeters / 1000.0; // Convert to kilometers
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode}');
    }
  } catch (e) {
    print('Error calculating distance: $e');
    return 0.0;
  }
}

Future<bool> _requestVolunteer(Map<String, dynamic> bookingData, List<DocumentSnapshot> volunteers, int currentIndex) async {
  if (currentIndex >= volunteers.length) {
    return false; // No more volunteers to try
  }

  DocumentSnapshot volunteerDoc = volunteers[currentIndex];
  final volunteerId = volunteerDoc['userId'];

  // Calculate distance between volunteer and requester
  String requesterName = bookingData['requesterDetails']['name'];
  String volunteerLocation = volunteerDoc['Address'];
  String requesterLocation = bookingData['requesterDetails']['coordinates'];
  double distance = await _calculateDistance(volunteerLocation, requesterLocation);

  // Create volunteer request notification
  final requestRef = await FirebaseFirestore.instance.collection('volunteerRequests').add({
    'volunteerId': volunteerId,
    'requesterId': bookingData['requesterDetails']['userId'],
    'requesterName': bookingData['requesterDetails']['name'],
    'requesterContact': bookingData['requesterDetails']['contact'],
    'donorAddress': bookingData['donorDetails']['Address'],
    'requesterAddress': bookingData['requesterDetails']['Address'],
    'distance': distance,
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
    'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
    'bookingData': bookingData,
  });

  // Send notification to volunteer
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': volunteerId,
    'title': 'New Shelter Request',
    'message': 'A Person named $requesterName needs your help with shelter service',
    'type': 'volunteer_request',
    'requestId': requestRef.id,
    'timestamp': FieldValue.serverTimestamp(),
    'expiresIn': 5, // minutes
  });

  // Wait for volunteer response or timeout
  try {
    bool accepted = await _waitForVolunteerResponse(requestRef.id);
    if (accepted) {
      // Update booking data with volunteer info
      bookingData['volunteerDetails'] = {
        'userId': volunteerDoc['userId'],
        'name': volunteerDoc['name'],
        'contact': volunteerDoc['contact'],
        'address': volunteerDoc['Address'],
        'age': volunteerDoc['age'],
        'gender': volunteerDoc['gender'],
        'availability': volunteerDoc['availability'],
        'profileImage': volunteerDoc['profileImage'],
        'email': volunteerDoc['email'],

      };
      
      // Notify requester
      await _notifyRequester(
        bookingData['requesterDetails']['userId'],
        volunteerDoc['name'],
        volunteerDoc['Address']
      );

      // Notify volunteer about pending coordinator approval
      await _notifyVolunteer(
        volunteerId,
        bookingData['shelterDetails']['houseName'],
        bookingData['requesterDetails']['name']
      );

      return true;
    } else {
      // Try next volunteer
      return await _requestVolunteer(bookingData, volunteers, currentIndex + 1);
    }
  } catch (e) {
    print('Error in volunteer request: $e');
    return false;
  }
}

Future<bool> _waitForVolunteerResponse(String requestId) {
  Completer<bool> completer = Completer();
  Timer? timeoutTimer;
  StreamSubscription? subscription;

  // Set timeout timer
  timeoutTimer = Timer(const Duration(minutes: 5), () {
    subscription?.cancel();
    completer.complete(false);
  });

  // Listen for volunteer response
  subscription = FirebaseFirestore.instance
      .collection('volunteerRequests')
      .doc(requestId)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.data()?['status'] == 'accepted') {
      timeoutTimer?.cancel();
      subscription?.cancel();
      completer.complete(true);
    } else if (snapshot.data()?['status'] == 'declined') {
      timeoutTimer?.cancel();
      subscription?.cancel();
      completer.complete(false);
    }
  });

  return completer.future;
}

Future<void> _notifyRequester(String requesterId, String volunteerName, String volunteerLocation) async {
  try {
    // Convert coordinates to address
    final coords = volunteerLocation.split(',');
    if (coords.length != 2) {
      throw Exception('Invalid coordinates format');
    }

    double lat = double.parse(coords[0].trim());
    double lng = double.parse(coords[1].trim());

    // Get address using geocoding
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    String address = "Unknown location";
    
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      address = " ${place.subLocality}, "
          "${place.locality}";
    }

    // Send notification with decoded address
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': requesterId,
      'title': 'Volunteer Assigned- Pending Approval',
      'message': 'Volunteer $volunteerName has accepted your request. They are located at $address',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'volunteer_assigned'
    });
  } catch (e) {
    print('Error in _notifyRequester: $e');
    // Send notification with coordinates if address conversion fails
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': requesterId,
      'title': 'Volunteer Assigned',
      'message': 'Volunteer $volunteerName has accepted your request. They are located at $volunteerLocation',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'volunteer_assigned'
    });
  }
}

Future<void> _notifyVolunteer(String volunteerId, String shelterName, String requesterName) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': volunteerId,
      'title': 'Request Pending Approval',
      'message': 'Your acceptance to help $requesterName with shelter $shelterName is pending coordinator approval. You will be notified once the coordinator reviews the request.',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'volunteer_pending_approval'
    });
  } catch (e) {
    print('Error sending volunteer notification: $e');
  }
}

Future<void> _addNotification(String userId, String location) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': 'Booking Request',
      'message': 'Your request has been accepted. Waiting for approval by $location Coordinator.',
      'timestamp': Timestamp.now(),
      'status': 'pending',
      'type': 'shelter_booking'
    });
  } catch (e) {
    print('Error adding notification: $e');
  }
}

   Future<void> _translateContent() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.currentLocale.languageCode;
    
    if (targetLanguage == 'en') {
      setState(() {
        translatedData = {
          'Name': widget.shelterData['Name'],
          'Description': widget.shelterData['Description'],
          'Preference': widget.shelterData['Preference'],
          'Size': widget.shelterData['Size'].toString(),
        };
      });
      return;
    }
    try {
      final translationService = TranslationService();
      Map<String, String> translated = {};

      // Translate essential fields
      translated['Name'] = await translationService.translateText(
        widget.shelterData['Name'].toString(), 
        targetLanguage
      );
      translated['Description'] = await translationService.translateText(
        widget.shelterData['Description'].toString(), 
        targetLanguage
      );
      translated['Preference'] = await translationService.translateText(
        widget.shelterData['Preference'].toString(), 
        targetLanguage
      );
      if (mounted) {
        setState(() {
          translatedData = translated;
        });
      }
    } catch (e) {
      print('Translation error: $e');
    }
  }


   Future<void> _getAddress() async {
    try {
      // Parse the coordinates string
      final coords = widget.shelterData["Address"].toString().split(',');
      if (coords.length != 2) {
        setState(() {
          address = "Invalid coordinates";
        });
        return;
      }

      double lat = double.parse(coords[0].trim());
      double lng = double.parse(coords[1].trim());

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          address = "${place.street}, ${place.subLocality}, "
              "${place.locality}, ${place.postalCode}, ";
              
        });
      }
    } catch (e) {
      setState(() {
        address = "Could not fetch address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: Colors.white,
      appBar: AppBar(
        title: Text(translatedData?['Name'] ?? widget.shelterData["Name"]),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
           onPressed: () {
          // Return the distance when navigating back
          Navigator.pop(context, DistanceData().getDistance(widget.shelterData.id));
        },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.blue,
                      borderRadius: BorderRadius.circular(25)
                    ),
                    width: double.infinity,
                    height: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                         Padding(
                          padding: const EdgeInsets.only(top: 12.0,left: 12.0),
                          child: Text(translatedData?['Name'] ?? widget.shelterData["Name"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              address,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text( "Distance: ${widget.shelterData['distance']?.toStringAsFixed(2) ?? '0.00'} km",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            width: 80,
                            height: 50,
                            decoration: BoxDecoration(
                              color:themeProvider.isDarkMode?Colors.grey.shade800: Colors.lightBlue[100],
                              borderRadius: BorderRadius.circular(25)
                            ),
                            child: Center(
                              child: Text("${widget.shelterData["Size"]} Bed",
                              style:  TextStyle(
                                color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold
                              ),)
                            ),
                          ),
                        ),
                         Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            languageProvider.translations['preference'] != null 
                              ? "${languageProvider.translations['preference']}: ${translatedData?['Preference'] ?? widget.shelterData["Preference"]}"
                              : "Preference: ${translatedData?['Preference'] ?? widget.shelterData["Preference"]}",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
               Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(languageProvider.translations['datecre']?? "Date Created",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold
                          ),),
              ),
               Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("${widget.shelterData["Date"]} \t ${widget.shelterData["Time"]}",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.normal
                          ),),
              ),
              Row(
                children: [
                 const SizedBox(height: 10,),
                 Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                                  child: widget.shelterData["Images"][0].isNotEmpty
                                    ? (widget.shelterData["Images"][0].startsWith('/data') 
                                                ? Image.file(
                                      File(widget.shelterData["Images"][0]),
                                      fit: BoxFit.fill,
                                      width: 100,
                                      height: 100,
                                        )
                                      : Image.network(
                                       widget.shelterData["Images"][0],
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
                 const SizedBox(width: 20,),
                 Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child:  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                                  child: widget.shelterData["Images"][1].isNotEmpty
                                    ? (widget.shelterData["Images"][1].startsWith('/data') 
                                                ? Image.file(
                                      File(widget.shelterData["Images"][1]),
                                      fit: BoxFit.fill,
                                      width: 100,
                                      height: 100,
                                        )
                                      : Image.network(
                                       widget.shelterData["Images"][1],
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
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(languageProvider.translations['description']?? "Description",
                      style: TextStyle(
                      color: themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold
                          ),),
              ),
               Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(translatedData?['Description'] ?? widget.shelterData["Description"],
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.normal
                          ),),
              ),
              const SizedBox(height: 80,),
              Text(languageProvider.translations['rev']?? "Reviews",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode?Colors.white: Colors.black,
              ),),

              StreamBuilder(stream: FirebaseFirestore.instance
              .collection('shelter')
              .doc(widget.shelterData.id)
              .collection('reviews')
              .orderBy('timestamp',descending: true)
              .snapshots(), 
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
                if(snapshot.connectionState==ConnectionState.waiting){
                  return const CircularProgressIndicator(color: Colors.orange,);
                }
                if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
                  return  Text(languageProvider.translations['norev']?? "No reviews yet.");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context,index){
                    final review=snapshot.data!.docs[index];
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
                    builder: (context,AsyncSnapshot<List<DocumentSnapshot>> userSnapshot){
                      if(!userSnapshot.hasData || userSnapshot.data!.any((doc) => !doc.exists)){
                        return const CircularProgressIndicator(color: Colors.deepOrange,);
                      }
                      final userData = userSnapshot.data![0].data() as Map<String, dynamic>;
            final profileData = userSnapshot.data![1].data() as Map<String, dynamic>?;
                                              return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profileData != null && profileData['Image'] != null
                                ? NetworkImage(profileData['Image'])
                                : const AssetImage('lib/images/default_profile.png') as ImageProvider,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(userData['name'] ?? 'Unknown User',
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                  ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < review['rating'] ? Icons.star : Icons.star_border,
                                          color: starIndex < review['rating'] ? Colors.orange : Colors.grey,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  (review['timestamp'] as Timestamp).toDate()
                                ),
                                style: TextStyle(fontSize: 12, color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                              ),
                            ],
                          ),
                          subtitle: Text(review['reviewText'],style: TextStyle(color: themeProvider.isDarkMode?Colors.white: Colors.black,),),
                        );

                    });
                  });
              }),
              const SizedBox(height: 20,),
               Text(languageProvider.translations['leaverev']?? "Leave a Review",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              ),
              DropdownButton<int>(
                value: selectedRating,
                items: List.generate(5, 
                (index)=>DropdownMenuItem(
                 value:index+1,
                 child: Text("${index+1} Stars"), 
                )), 
              onChanged: (value){
                setState(() {
                  selectedRating = value!;
                });
              },
            ),
            TextField(
              controller: _reviewController,
              decoration:  InputDecoration(
                labelText: languageProvider.translations['writerev']?? "Write your Review",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 10,),
            ElevatedButton(onPressed:() async{
              if(_reviewController.text.trim().isEmpty)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(languageProvider.translations['emptyrev']?? "Review Cannot be Empty")),
                );
                return;
              }
              final currentUser=FirebaseAuth.instance.currentUser!;
              final existingReview=await FirebaseFirestore.instance
              .collection('shelter')
              .doc(widget.shelterData.id)
              .collection('reviews')
              .where('userId',isEqualTo: currentUser.uid)
              .get();

              if(existingReview.docs.isNotEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(languageProvider.translations['onerev']?? "You can Only Submit One Review")),
                );
                return;
              }

              final reviewData={
                    'reviewText': _reviewController.text.trim(),
                    'rating': selectedRating,
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'timestamp': Timestamp.now(),
              };

              await FirebaseFirestore.instance
                      .collection('shelter')
                      .doc(widget.shelterData.id)
                      .collection('reviews')
                      .add(reviewData);

                   _reviewController.clear();
                  setState(() {
                    selectedRating = 5;
                  });

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review added successfully!")),
                  );

            } , 
            child:  Text(languageProvider.translations['subrev']??"Submit Review",
                      style: TextStyle(
                        color: themeProvider.isDarkMode?Colors.white: Colors.black,
                      ),
            )
            
            ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.blue,
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child:  Center(child: Text(languageProvider.translations['booknow']?? "Book Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    )),
                  ),
                  onTap: () {
                    //Function for booking Resources!
                    _handleBooking(context, widget.shelterData);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PopfoodScreen extends StatefulWidget {
  final DocumentSnapshot foodData;
  const PopfoodScreen({super.key,required this.foodData});

  @override
  State<PopfoodScreen> createState() => _PopfoodScreenState();
}

class _PopfoodScreenState extends State<PopfoodScreen> {
  String address="Loading...";
  final TextEditingController _reviewController=TextEditingController();
  int selectedRating=5;

  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  Future<void> _getAddress() async {
    try {
      // Parse the coordinates string
      final coords = widget.foodData["Address"].toString().split(',');
      if (coords.length != 2) {
        setState(() {
          address = "Invalid coordinates";
        });
        return;
      }

      double lat = double.parse(coords[0].trim());
      double lng = double.parse(coords[1].trim());

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          address = "${place.street}, ${place.subLocality}, "
              "${place.locality}, ${place.postalCode}, ";
              
        });
      }
    } catch (e) {
      setState(() {
        address = "Could not fetch address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
     return Scaffold(
      backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.blue,
                      borderRadius: BorderRadius.circular(25)
                    ),
                    width: double.infinity,
                    height: 280,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Padding(
                          padding: const EdgeInsets.only(top: 12.0,left: 12.0),
                          child: Text("${widget.foodData["FoodName"]}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                          Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                          Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Distance: ${DistanceData().getDistance(widget.foodData.id).toStringAsFixed(2)} km",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            width: 120,
                            height: 50,
                            decoration: BoxDecoration(
                              color:themeProvider.isDarkMode?Colors.grey.shade800: Colors.lightBlue[100],
                              borderRadius: BorderRadius.circular(25)
                            ),
                            child: Center(
                              child: Text("${widget.foodData["Size"]} Persons",
                              style:  TextStyle(
                                color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold
                              ),)
                            ),
                          ),
                        ),
                         Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text("Type : ${widget.foodData["Type"]}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("Date Created",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold
                          ),),
              ),
               Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("${widget.foodData["Date"]} \t ${widget.foodData["Time"]}",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.normal
                          ),),
              ),
              const SizedBox(height: 20,),
              Row(
                children: [
                 const SizedBox(height: 10,),
                 Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: widget.foodData["Images"][0].isNotEmpty
                                    ? (widget.foodData["Images"][0].startsWith('/data') 
                                                ? Image.file(
                                      File(widget.foodData["Images"][0]),
                                      fit: BoxFit.fill,
                                      width: 100,
                                      height: 100,
                                        )
                                      : Image.network(
                                       widget.foodData["Images"][0],
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
                 const SizedBox(width: 20,),
                 Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child:  ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: widget.foodData["Images"][1].isNotEmpty
                                    ? (widget.foodData["Images"][1].startsWith('/data') 
                                                ? Image.file(
                                      File(widget.foodData["Images"][1]),
                                      fit: BoxFit.fill,
                                      width: 100,
                                      height: 100,
                                        )
                                      : Image.network(
                                       widget.foodData["Images"][1],
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
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("Description",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold
                          ),),
              ),
               Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("${widget.foodData["Description"]}",
                      style: TextStyle(
                      color: themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.normal
                          ),),
              ),
              const SizedBox(height: 80,),
              Text("Reviews",
              style: TextStyle(
                color: themeProvider.isDarkMode?Colors.white: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),),

              StreamBuilder(stream: FirebaseFirestore.instance
              .collection('food')
              .doc(widget.foodData.id)
              .collection('reviews')
              .orderBy('timestamp',descending: true)
              .snapshots(), 
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
                if(snapshot.connectionState==ConnectionState.waiting){
                  return const CircularProgressIndicator(color: Colors.orange,);
                }
                if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
                  return const Text("No reviews yet.");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context,index){
                    final review=snapshot.data!.docs[index];
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
                    builder: (context,AsyncSnapshot<List<DocumentSnapshot>> userSnapshot){
                      if(!userSnapshot.hasData || userSnapshot.data!.any((doc) => !doc.exists)){
                        return const CircularProgressIndicator(color: Colors.deepOrange,);
                      }
                      final userData = userSnapshot.data![0].data() as Map<String, dynamic>;
            final profileData = userSnapshot.data![1].data() as Map<String, dynamic>?;
                                              return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profileData != null && profileData['Image'] != null
                                ? NetworkImage(profileData['Image'])
                                : const AssetImage('lib/images/default_profile.png') as ImageProvider,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(userData['name'] ?? 'Unknown User',style: TextStyle(color: themeProvider.isDarkMode?Colors.white: Colors.black,),),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < review['rating'] ? Icons.star : Icons.star_border,
                                          color: starIndex < review['rating'] ? Colors.orange : Colors.grey,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  (review['timestamp'] as Timestamp).toDate()
                                ),
                                style: TextStyle(fontSize: 12, color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                              ),
                            ],
                          ),
                          subtitle: Text(review['reviewText'],
                          style: TextStyle(
                            color: themeProvider.isDarkMode?Colors.white: Colors.black,
                          ),
                          ),
                        );

                    });
                  });
              }),
              const SizedBox(height: 20,),
              Text("Leave a Review",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode?Colors.white: Colors.black,
              ),
              ),
              DropdownButton<int>(
                value: selectedRating,
                items: List.generate(5, 
                (index)=>DropdownMenuItem(
                 value:index+1,
                 child: Text("${index+1} Stars",
                 style: TextStyle(
                  color: themeProvider.isDarkMode?Colors.white: Colors.black,
                 ),), 
                )), 
              onChanged: (value){
                setState(() {
                  selectedRating = value!;
                });
              },
            ),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: "Write your Review",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 10,),
            ElevatedButton(
              onPressed:() async{
              if(_reviewController.text.trim().isEmpty)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Review Cannot be Empty")),
                );
                return;
              }
              final currentUser=FirebaseAuth.instance.currentUser!;
              final existingReview=await FirebaseFirestore.instance
              .collection('food')
              .doc(widget.foodData.id)
              .collection('reviews')
              .where('userId',isEqualTo: currentUser.uid)
              .get();

              if(existingReview.docs.isNotEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You can Only Submit One Review")),
                );
                return;
              }

              final reviewData={
                    'reviewText': _reviewController.text.trim(),
                    'rating': selectedRating,
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'timestamp': Timestamp.now(),
              };

              await FirebaseFirestore.instance
                      .collection('food')
                      .doc(widget.foodData.id)
                      .collection('reviews')
                      .add(reviewData);

                   _reviewController.clear();
                  setState(() {
                    selectedRating = 5;
                  });

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review added successfully!")),
                  );

            } , 
            child: Text("Submit Review",
            style: TextStyle(
              color: themeProvider.isDarkMode?Colors.white: Colors.black,
            ),
            )),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.blue,
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: const Center(child: Text("Book Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    )),
                  ),
                  onTap: () {
                    //Function for booking Resources!
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PopclothScreen extends StatefulWidget {
  final DocumentSnapshot clothData;
  const PopclothScreen({super.key,required this.clothData});

  @override
  State<PopclothScreen> createState() => _PopclothScreenState();
}

class _PopclothScreenState extends State<PopclothScreen> {

  String address="Loading...";
  final TextEditingController _reviewController=TextEditingController();
  int selectedRating=5;

  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  Future<void> _getAddress() async {
    try {
      // Parse the coordinates string
      final coords = widget.clothData["Address"].toString().split(',');
      if (coords.length != 2) {
        setState(() {
          address = "Invalid coordinates";
        });
        return;
      }

      double lat = double.parse(coords[0].trim());
      double lng = double.parse(coords[1].trim());

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          address = "${place.street}, ${place.subLocality}, "
              "${place.locality}, ${place.postalCode}, ";
              
        });
      }
    } catch (e) {
      setState(() {
        address = "Could not fetch address";
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
     return Scaffold(
      backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.blue,
                      borderRadius: BorderRadius.circular(25)
                    ),
                    width: double.infinity,
                    height: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Padding(
                          padding: const EdgeInsets.only(top: 12.0,left: 12.0),
                          child: Text("${widget.clothData["ClothName"]}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                          Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                          Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Distance: ${DistanceData().getDistance(widget.clothData.id).toStringAsFixed(2)} km",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            width: 120,
                            height: 50,
                            decoration: BoxDecoration(
                              color:themeProvider.isDarkMode?Colors.grey.shade800: Colors.lightBlue[100],
                              borderRadius: BorderRadius.circular(25)
                            ),
                            child: Center(
                              child: Text("${widget.clothData["Count"]} Persons",
                              style:  TextStyle(
                                color:themeProvider.isDarkMode?Colors.white: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold
                              ),)
                            ),
                          ),
                        ),
                         Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text("Type : ${widget.clothData["Gender"]}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("Date Created",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold
                          ),),
              ),
               Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("${widget.clothData["Date"]} \t ${widget.clothData["Time"]}",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.normal
                          ),),
              ),
              const SizedBox(height: 20,),
              Row(
                children: [
                 const SizedBox(height: 10,),
                 Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: widget.clothData["Images"][0].isNotEmpty
                                    ? (widget.clothData["Images"][0].startsWith('/data') 
                                                ? Image.file(
                                      File(widget.clothData["Images"][0]),
                                      fit: BoxFit.fill,
                                      width: 100,
                                      height: 100,
                                        )
                                      : Image.network(
                                       widget.clothData["Images"][0],
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
                 const SizedBox(width: 20,),
                 Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child:  ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: widget.clothData["Images"][1].isNotEmpty
                                    ? (widget.clothData["Images"][1].startsWith('/data') 
                                                ? Image.file(
                                      File(widget.clothData["Images"][1]),
                                      fit: BoxFit.fill,
                                      width: 100,
                                      height: 100,
                                        )
                                      : Image.network(
                                       widget.clothData["Images"][1],
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
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("Description",
                      style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold
                          ),),
              ),
               Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("${widget.clothData["Description"]}",
                      style: TextStyle(
                      color: themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.normal
                          ),),
              ),
              const SizedBox(height: 80,),
              Text("Reviews",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode?Colors.white: Colors.black,
              ),),

              StreamBuilder(stream: FirebaseFirestore.instance
              .collection('cloth')
              .doc(widget.clothData.id)
              .collection('reviews')
              .orderBy('timestamp',descending: true)
              .snapshots(), 
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
                if(snapshot.connectionState==ConnectionState.waiting){
                  return const CircularProgressIndicator(color: Colors.orange,);
                }
                if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
                  return const Text("No reviews yet.");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context,index){
                    final review=snapshot.data!.docs[index];
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
                    builder: (context,AsyncSnapshot<List<DocumentSnapshot>> userSnapshot){
                      if(!userSnapshot.hasData || userSnapshot.data!.any((doc) => !doc.exists)){
                        return const CircularProgressIndicator(color: Colors.deepOrange,);
                      }
                      final userData = userSnapshot.data![0].data() as Map<String, dynamic>;
            final profileData = userSnapshot.data![1].data() as Map<String, dynamic>?;
                                              return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profileData != null && profileData['Image'] != null
                                ? NetworkImage(profileData['Image'])
                                : const AssetImage('lib/images/default_profile.png') as ImageProvider,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(userData['name'] ?? 'Unknown User',style: TextStyle(
                                    color: themeProvider.isDarkMode?Colors.white: Colors.black,
                                  ),),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < review['rating'] ? Icons.star : Icons.star_border,
                                          color: starIndex < review['rating'] ? Colors.orange : Colors.grey,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  (review['timestamp'] as Timestamp).toDate()
                                ),
                                style:  TextStyle(fontSize: 12, color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                              ),
                            ],
                          ),
                          subtitle: Text(review['reviewText'],style: TextStyle(color: themeProvider.isDarkMode?Colors.white: Colors.black,),),
                        );

                    });
                  });
              }),
              const SizedBox(height: 20,),
              Text("Leave a Review",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode?Colors.white: Colors.black,
              ),
              ),
              DropdownButton<int>(
                value: selectedRating,
                items: List.generate(5, 
                (index)=>DropdownMenuItem(
                 value:index+1,
                 child: Text("${index+1} Stars",style: TextStyle(color: themeProvider.isDarkMode?Colors.white: Colors.black,),), 
                )), 
              onChanged: (value){
                setState(() {
                  selectedRating = value!;
                });
              },
            ),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: "Write your Review",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 10,),
            ElevatedButton(onPressed:() async{
              if(_reviewController.text.trim().isEmpty)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Review Cannot be Empty")),
                );
                return;
              }
              final currentUser=FirebaseAuth.instance.currentUser!;
              final existingReview=await FirebaseFirestore.instance
              .collection('cloth')
              .doc(widget.clothData.id)
              .collection('reviews')
              .where('userId',isEqualTo: currentUser.uid)
              .get();

              if(existingReview.docs.isNotEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You can Only Submit One Review")),
                );
                return;
              }

              final reviewData={
                    'reviewText': _reviewController.text.trim(),
                    'rating': selectedRating,
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'timestamp': Timestamp.now(),
              };

              await FirebaseFirestore.instance
                      .collection('cloth')
                      .doc(widget.clothData.id)
                      .collection('reviews')
                      .add(reviewData);

                   _reviewController.clear();
                  setState(() {
                    selectedRating = 5;
                  });

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review added successfully!")),
                  );

            } , 
            child: Text("Submit Review",
            style: TextStyle(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
            )),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.blue,
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: const Center(child: Text("Book Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    )),
                  ),
                  onTap: () {
                    //Function for booking Resources!
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
