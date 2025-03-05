import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/address_selector.dart';
import 'package:food_delivery_app/pages/blood_donor_page.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';

class AddBloodDonorDetails extends StatefulWidget {
  final String userId;
  // ignore: non_constant_identifier_names
  final String Loc;

  const AddBloodDonorDetails({super.key, required this.userId, required this.Loc});

  @override
  State<AddBloodDonorDetails> createState() => _AddBloodDonorDetailsState();
}

class _AddBloodDonorDetailsState extends State<AddBloodDonorDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  TextEditingController nameController=TextEditingController();
  TextEditingController ageController=TextEditingController();
  TextEditingController contactController=TextEditingController();
  TextEditingController emailController=TextEditingController();
  TextEditingController addressController=TextEditingController();

  TextEditingController weightController = TextEditingController();
  TextEditingController medicationsController = TextEditingController();
  TextEditingController travelHistoryController = TextEditingController();
  
  List<String> preferredTimeSlots = [];
  TextEditingController emergencyNameController = TextEditingController();
  TextEditingController emergencyPhoneController = TextEditingController();
  final TextEditingController _otherConditionsController = TextEditingController();

  // Variables for eligibility questions
  bool donatedInLast3Months = false;
  bool hasInfectiousDiseases = false;
  bool hasTravelledToHighRiskArea = false;
  bool hasHadSurgeryInLast6Months = false;

  bool? willingForEmergencyDonation = false; 

  // Variables for consent
  bool consentForDonation = false;
  bool consentForNotifications = false;



  // Variables for checkboxes and selections
  List<String> chronicConditions = [];
  bool hadRecentIllness = false;
  String recentIllnessDetails = '';
  bool hasTattooOrPiercing = false;
  DateTime? tattooDate;
  
  // Function to select tattoo/piercing date
  Future<void> _selectTattooDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2022),
    lastDate: DateTime.now(),
  );
  if (picked != null) {
    setState(() {
      // Store only the date part by setting time to midnight
      tattooDate = DateTime(picked.year, picked.month, picked.day);
      
      // Calculate duration since tattoo/piercing
      final duration = DateTime.now().difference(tattooDate!);
      final monthsElapsed = duration.inDays / 30; // Approximate months
      
      if (monthsElapsed < 6) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Information"),
              content: const Text("Recent tattoos or piercings (less than 6 months old) may temporarily disqualify you from donating blood."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("I Understand"),
                ),
              ],
            );
          },
        );
      }
    });
  }
}

  void _addCondition(String condition) {
  if (condition.isNotEmpty && !chronicConditions.contains(condition)) {
    setState(() {
      // When adding a specific "other" condition, remove the "Other" checkbox selection
      if (chronicConditions.contains("Other")) {
        chronicConditions.remove("Other");
      }
      chronicConditions.add(condition);
    });
  }
}

  String selectedGender="Male";

  String? selectedBloodGroup;
  List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']; 

   String selectedDonationFrequency = "First time Donor";
   DateTime? lastDonationDate;

   String selectedDonType="Whole Blood";

   // Availability related variables
  String selectedAvailability = "Full Time";
  TimeOfDay? fromTime;
  TimeOfDay? toTime;

  bool isloading = false; //Controller for CircularProgressIndicator

  File? selectedImage_one;

  //Variable for Form Creation
  final _personalFormKey = GlobalKey<FormState>();
final _bloodFormKey = GlobalKey<FormState>();
final _healthFormKey = GlobalKey<FormState>();
final _availabilityFormKey = GlobalKey<FormState>();
final _consentFormKey = GlobalKey<FormState>();

   Future pickImagefromGalleryone() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      selectedImage_one = File(returnedImage.path);
      Navigator.pop(context);
    });
  }

  Future pickImagefromCameraone() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      selectedImage_one = File(returnedImage.path); 
      Navigator.pop(context);
    });
  }

  Future<void> _selectTime(BuildContext context, bool isFromTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFromTime) {
          fromTime = picked;
        } else {
          toTime = picked;
        }
      });
    }
  }

  Widget _buildTimeSelectionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "From",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () => _selectTime(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fromTime?.format(context) ?? 'Select time',
                            style: TextStyle(
                              color: fromTime != null ? Colors.black : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "To",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () => _selectTime(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            toTime?.format(context) ?? 'Select time',
                            style: TextStyle(
                              color: toTime != null ? Colors.black : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child("images/$fileName.jpg");
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  //For Document Upload
  File? idProof;
  File? medicalCertificate;
  File? donorCard;
  String? idProofName;
  String? medicalCertificateName;
  String? donorCardName;

  Future<void> pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        if (type == 'idProof') {
          idProof = File(result.files.single.path!);
          idProofName = result.files.single.name;
        } else if (type == 'medicalCertificate') {
          medicalCertificate = File(result.files.single.path!);
          medicalCertificateName = result.files.single.name;
        } else if (type == 'donorCard') {
          donorCard = File(result.files.single.path!);
          donorCardName = result.files.single.name;
        }
      });
    }
  }

  Future<String?> uploadFileToFirebase(File file, String path) async {
    try {
      Reference storageRef = FirebaseStorage.instance.ref().child("documents/$path/${DateTime.now().millisecondsSinceEpoch}.pdf");
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  //Function for Saving the Details 
 
  Future<void> saveBloodDonorDetails() async {
  // Validate forms before proceeding
   /*
  if (!(_personalFormKey.currentState?.validate() ?? false) ||
      !(_bloodFormKey.currentState?.validate() ?? false) ||
      !(_healthFormKey.currentState?.validate() ?? false) ||
      !(_availabilityFormKey.currentState?.validate() ?? false) ||
      !(_consentFormKey.currentState?.validate() ?? false)
      ) 
      {
    Fluttertoast.showToast(
      msg: "Please fill in all required fields.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }
*/
  // Ensure a profile image is uploaded
  if (selectedImage_one == null) {
    Fluttertoast.showToast(
      msg: "Please upload a profile image.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }

  setState(() {
    isloading = true;
  });

  try {
    // Upload profile image
    String imageUrl = await uploadImageToFirebase(selectedImage_one!);

    // Upload documents if available
    String? idProofUrl = idProof != null ? await uploadFileToFirebase(idProof!, 'idProof') : null;
    String? medicalCertUrl = medicalCertificate != null ? await uploadFileToFirebase(medicalCertificate!, 'medicalCertificate') : null;
    String? donorCardUrl = donorCard != null ? await uploadFileToFirebase(donorCard!, 'donorCard') : null;

    // Generate a unique ID for the donor
    String id = randomAlphaNumeric(10);
    DateTime now = DateTime.now();
    String formattedDate = "${now.day}-${now.month}-${now.year}";
    String formattedTime = "${now.hour}:${now.minute}:${now.second}";

    // Build data map
    Map<String, dynamic> bloodDonorInfo = {
      'userId': widget.userId,
      'id': id,
      'name': nameController.text.trim(),
      'age': ageController.text.isNotEmpty ? int.tryParse(ageController.text) ?? 0 : 0, // Safe parsing
      'gender': selectedGender,
      'bloodGroup': selectedBloodGroup ?? "Not specified", // Default value
      'donationFrequency': selectedDonationFrequency,
      'lastDonationDate': lastDonationDate?.toIso8601String() ?? "", // Avoid null issues
      'donationType': selectedDonType,
      'weight': weightController.text.trim(),
      'chronicConditions': chronicConditions,
      'medications': medicationsController.text.trim(),
      'travelHistory': travelHistoryController.text.trim(),
      'hasTattooOrPiercing': hasTattooOrPiercing,
      'tattooDate': tattooDate?.toIso8601String() ?? "",
      'contact': contactController.text.trim(),
      'email': emailController.text.trim(),
      'address': addressController.text.trim(),
      'location': widget.Loc,
      'availability': {
        'status': selectedAvailability,
        'timeSlots': preferredTimeSlots,
        'fromTime': fromTime?.format(context) ?? "Not set",
        'toTime': toTime?.format(context) ?? "Not set"
      },
      'emergencyContact': {
        'name': emergencyNameController.text.trim(),
        'phone': emergencyPhoneController.text.trim()
      },
      'consent': {
        'donationConsent': consentForDonation,
        'notificationsConsent': consentForNotifications,
      },
      'documents': {
        'idProof': idProofUrl,
        'medicalCertificate': medicalCertUrl,
        'donorCard': donorCardUrl,
      },
      'createdAt': {
        'date': formattedDate,
        'time': formattedTime,
      },
      'profileImage': imageUrl,
      'status': 'active',
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // Save details to Firestore
    await DatabaseMethods().setbloodDonorDetails(bloodDonorInfo, id);

    // Success toast message
    Fluttertoast.showToast(
      msg: "Blood donor details saved successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    // Clear fields after successful submission
    nameController.clear();
    ageController.clear();
    contactController.clear();
    emailController.clear();
    weightController.clear();
    medicationsController.clear();
    travelHistoryController.clear();
    setState(() {
      chronicConditions.clear();
      preferredTimeSlots.clear();
      selectedImage_one = null;
      idProof = null;
      medicalCertificate = null;
      donorCard = null;
      fromTime = null;
      toTime = null;
      selectedAvailability = "Full Time";
    });

    // Navigate to the MapPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BloodDonorPage(userId: widget.userId, location: widget.Loc),
      ),
    );
  } catch (e, stacktrace) {
    // Catch errors and log the stack trace
    print("Error in saveBloodDonorDetails: $e");
    print(stacktrace);

    // Show error message
    Fluttertoast.showToast(
      msg: "Error: $e",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  } finally {
    // Hide loading indicator
    setState(() {
      isloading = false;
    });
  }
}




  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _otherConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Center(child: const Text('Add Blood Donor Details',style: TextStyle(fontWeight: FontWeight.bold),)),
        automaticallyImplyLeading: false,
        backgroundColor:themeProvider.isDarkMode?Colors.grey[900]: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red,
              tabs: const [
                Tab(text: 'Personal Information'),
                Tab(text: 'Blood-Related Information'),
                Tab(text: 'Health Information'),
                Tab(text: 'Availability'),
                Tab(text: 'Consent and Eligibility'),
                Tab(text: 'Document Uploads'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Personal Information Tab
                Container(
                  padding: const EdgeInsets.all(16),
                  child:personalInfo(), 
                ),
                // Blood-Related Information Tab
                Container(
                  padding: const EdgeInsets.all(16),
                  child: bloodInfo(),
                ),
                // Health Information Tab
                Container(
                  padding: const EdgeInsets.all(16),
                  child: healthInfo(),
                ),
                // Availability Tab
                Container(
                  padding: const EdgeInsets.all(16),
                  child: availabilityInfo(),
                ),
                // Consent and Eligibility Tab
                Container(
                  padding: const EdgeInsets.all(16),
                  child: consentAndEligibilityInfo(),
                ),
                // Document Uploads Tab
                Container(
                  padding: const EdgeInsets.all(16),
                  child: documentUploadTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget personalInfo(){
  final themeProvider = Provider.of<ThemeProvider>(context);
  return Form(
    key: _personalFormKey,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Name",
          style: TextStyle(
            color: themeProvider.isDarkMode?Colors.white:Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),),
          const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is mandatory';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Text("Upload Photo",
                    style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: GestureDetector(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  width: 160,
                                  height: 160,
                                  child: selectedImage_one != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            selectedImage_one!,
                                            fit: BoxFit.fill,
                                          ))
                                      : const Center(child: Text("Please Select an Image")),
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Choose an Option"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              pickImagefromCameraone();
                                            },
                                            child: const Text("Upload From Camera"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              pickImagefromGalleryone();
                                            },
                                            child: const Text("Upload From Gallery"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10,),
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Age",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 180),
                          Text(
                            "Gender",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: ageController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'age',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'This field is mandatory';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 50),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Radio<String>(
                                    value: "Male",
                                    groupValue: selectedGender,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedGender = value!;
                                      });
                                    },
                                  ),
                                  const Text("Male"),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: "Female",
                                    groupValue: selectedGender,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedGender = value!;
                                      });
                                    },
                                  ),
                                  const Text("Female"),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ), 
                  const SizedBox(height: 10),
                  Text(
                    "Contact",
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 56, // Match TextField height
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            children: [
                              const Icon(Icons.call, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                "+91",
                                style: TextStyle(
                                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your Number',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'This field is mandatory';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                   Text("Location",
                  style: TextStyle(
                    color:themeProvider.isDarkMode?Colors.white: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your address',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'This field is mandatory';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56, // Match TextField height
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.isDarkMode ? Colors.grey[600] : Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: () async {
                            final LatLng? selectedLocation = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddressSelector()),
                            );
                            if (selectedLocation != null) {
                              setState(() {
                                addressController.text =
                                    "${selectedLocation.latitude}, ${selectedLocation.longitude}";
                              });
                            }
                          },
                          child: const Icon(Icons.map, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Email",
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    enabled: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter Mail Address",
                      suffixIcon: Icon(Icons.email),
                    ),
                     validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'This field is mandatory';
                            }
                            return null;
                          },
                  ),
                  const SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      child: Container(
                        width: 160,
                        height: 50,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode?Colors.grey[600]:Colors.deepOrange,
                          borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Next",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),),
                            const SizedBox(width: 15,),
                            Icon(Icons.arrow_forward,color: Colors.white,)
                          ],
                        ),
                      ),
                        ),
                        onTap: () {
                           if (_personalFormKey.currentState!.validate()) {
            // Move to next tab
                                _tabController.animateTo(_tabController.index + 1);
                              }
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

Widget bloodInfo() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
 Future<void> selectDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );
  if (picked != null) {
    setState(() {
      // Store only the date part by setting time to midnight
      lastDonationDate = DateTime(picked.year, picked.month, picked.day);
      
      // Calculate duration between last donation and today
      final duration = DateTime.now().difference(lastDonationDate!);
      final monthsElapsed = duration.inDays / 30; // Approximate months
      
      if (monthsElapsed < 3) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Warning"),
              content: const Text("You cannot donate blood now. Minimum 3 months recovery is required."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    });
  }
}

  return Form(
    key: _bloodFormKey,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blood Group Dropdown
          Text("Blood Group",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBloodGroup,
                hint: const Text('Select Blood Group'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                elevation: 16,
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                dropdownColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                onChanged: (String? value) {
                  setState(() {
                    selectedBloodGroup = value;
                  });
                },
                items: bloodGroups.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Donation Frequency
          Text(
            "Donation Frequency",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          // Radio Buttons for Donation Frequency
          Column(
            children: [
              RadioListTile<String>(
                title: const Text("First time Donor"),
                value: "First time Donor",
                groupValue: selectedDonationFrequency,
                onChanged: (String? value) {
                  setState(() {
                    selectedDonationFrequency = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Regular Donor"),
                value: "Regular Donor",
                groupValue: selectedDonationFrequency,
                onChanged: (String? value) {
                  setState(() {
                    selectedDonationFrequency = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Non-Regular Donor"),
                value: "Non-Regular Donor",
                groupValue: selectedDonationFrequency,
                onChanged: (String? value) {
                  setState(() {
                    selectedDonationFrequency = value!;
                  });
                },
              ),
            ],
          ),
          
          // Last Donation Date (conditional)
          if (selectedDonationFrequency == "Regular Donor" || 
              selectedDonationFrequency == "Non-Regular Donor")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Last Donation Date",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lastDonationDate != null
                              ? "${lastDonationDate!.day}/${lastDonationDate!.month}/${lastDonationDate!.year}"
                              : "Select Date",
                          style: TextStyle(
                            color: lastDonationDate != null
                                ? themeProvider.isDarkMode ? Colors.white : Colors.black
                                : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20,),
            Text(
            "Preferred Donation Type",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          // Radio Buttons for Donation Frequency
          Column(
            children: [
              RadioListTile<String>(
                title: const Text("Whole Blood"),
                value: "Whole Blood",
                groupValue: selectedDonType,
                onChanged: (String? value) {
                  setState(() {
                    selectedDonType = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Plasma"),
                value: "Plasma",
                groupValue: selectedDonType,
                onChanged: (String? value) {
                  setState(() {
                    selectedDonType = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Platelets"),
                value: "Platelets",
                groupValue: selectedDonType,
                onChanged: (String? value) {
                  setState(() {
                    selectedDonType = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 60,),
          // Next button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      child: Container(
                        width: 160,
                        height: 50,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back, color: Colors.white),
                              SizedBox(width: 15),
                              Text(
                                "Previous",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        if (_bloodFormKey.currentState!.validate()) {
                          // Check if donation date is valid when not a first-time donor
                          if (selectedDonationFrequency != "First time Donor" && lastDonationDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select your last donation date")),
                            );
                            return;
                          }
                          
                          // If everything is valid, move to next tab
                          _tabController.animateTo(_tabController.index - 1);
                        }
                      },
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      child: Container(
                        width: 160,
                        height: 50,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Next",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 15),
                              Icon(Icons.arrow_forward, color: Colors.white)
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        if (_bloodFormKey.currentState!.validate()) {
                          // Check if donation date is valid when not a first-time donor
                          if (selectedDonationFrequency != "First time Donor" && lastDonationDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select your last donation date")),
                            );
                            return;
                          }
                          
                          // If everything is valid, move to next tab
                          _tabController.animateTo(_tabController.index + 1);
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

Widget healthInfo() {
  final themeProvider = Provider.of<ThemeProvider>(context);
    bool hasShownTravelWarning = false;

   // Warning message state
  final bool showWarning = chronicConditions.contains("None") && 
    chronicConditions.length > 1;


    // Function to validate health info
  Map<String, dynamic> validateHealthInfo(String medications, String recentIllness) {
    final medicationsLower = medications.toLowerCase();
    final illnessLower = recentIllness.toLowerCase();
    
    // Blood thinners check
    final bloodThinners = ['warfarin', 'coumadin', 'heparin', 'fondaparinux', 'arixtra', 'edoxaban', 'savaysa'];
    final hasBloodThinners = bloodThinners.any((med) => medicationsLower.contains(med));
    
    // Other disqualifying medications
    final otherMeds = ['isotretinoin', 'accutane', 'absorica', 'claravis', 'finasteride', 'proscar', 'propecia'];
    final hasOtherMeds = otherMeds.any((med) => medicationsLower.contains(med));
    
    // Infections and conditions check
    final disqualifyingConditions = ['cold', 'flu', 'sore throat', 'fever', 'stomach bug', 'infection', 
      'hepatitis', 'malaria', 'dengue', 'zika', 'g6pd'];
    final hasConditions = disqualifyingConditions.any((condition) => 
      illnessLower.contains(condition) || medicationsLower.contains(condition));

    if (hasBloodThinners || hasOtherMeds || hasConditions) {
      String reason = '';
      if (hasBloodThinners) {
        reason = 'You are currently taking blood thinning medications';
      } else if (hasOtherMeds) {
        reason = 'You are taking medications that may affect blood donation';
      } else {
        reason = 'You have a recent illness or condition that prevents blood donation';
      }
      return {'canDonate': false, 'reason': reason};
    }

    return {'canDonate': true};
  }


     // Function to show health alert dialog
  Future<void> showHealthAlertDialog(String reason) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Unable to Proceed with Blood Donation',
            style: TextStyle(
              color: Colors.red[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Based on the information provided, you are currently not eligible to donate blood.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                reason,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please consult with a healthcare provider for more information about when you may be eligible to donate.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Edit Information'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
                // Add your navigation logic here
              },
            ),
          ],
        );
      },
    );
  }


    Future<void> showNoneSelectionDialog(String condition) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove "None" Selection?'),
          content: const Text('If you want to select other conditions, you need to remove "None" first. Do you want to remove "None"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                setState(() {
                  chronicConditions.remove("None");
                  chronicConditions.add(condition);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void handleConditionChange(String condition, bool? value) {
  if (condition == "None" && value == true) {
    setState(() {
      // Clear all other conditions when None is selected
      chronicConditions.clear();
      chronicConditions.add("None");
    });
  } else if (chronicConditions.contains("None") && value == true) {
    // Show dialog when trying to select another condition while None is selected
    showNoneSelectionDialog(condition);
  } else if (value == true) {
    if (condition == "Other") {
      // Just add "Other" to the list, but it will be removed when specific conditions are added
      setState(() {
        chronicConditions.add(condition);
      });
    } else {
      setState(() {
        chronicConditions.add(condition);
      });
    }
  } else {
    setState(() {
      chronicConditions.remove(condition);
      
      // Special case: If we're unchecking "Other", remove all custom conditions
      if (condition == "Other") {
        chronicConditions.removeWhere((item) => 
          !["Diabetes", "Hypertension", "Heart Disease", "Thyroid Disorder", "Asthma", "None"].contains(item));
      }
    });
  }
}

  void addCondition(String condition) {
    if (condition.isNotEmpty && !chronicConditions.contains(condition)) {
      setState(() {
        chronicConditions.add(condition);
      });
    }
  }

  return Form(
    key: _healthFormKey,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight input
          Text(
            "Weight (kg)",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your weight in kilograms',
              suffixText: 'kg',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Weight is required';
              }
              final weight = double.tryParse(value);
              if (weight == null) {
                return 'Please enter a valid number';
              }
              if (weight < 50) {
                return 'Weight must be at least 50 kg';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Chronic Conditions
          Text(
            "Chronic Medical Conditions",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text("(Check on \"None\" if you have no medical conditions)",
          style:TextStyle(
            color:Colors.grey[600],
            fontSize:16,
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height:10),
          CheckboxListTile(
            title: const Text("Diabetes"),
            value: chronicConditions.contains("Diabetes"),
            onChanged: (value) => handleConditionChange("Diabetes", value),
          ),
          CheckboxListTile(
            title: const Text("Hypertension (High Blood Pressure)"),
            value: chronicConditions.contains("Hypertension"),
           onChanged: (value) => handleConditionChange("Hypertension", value),
          ),
          CheckboxListTile(
            title: const Text("Heart Disease"),
            value: chronicConditions.contains("Heart Disease"),
            onChanged: (value) => handleConditionChange("Heart Disease", value),
          ),
          CheckboxListTile(
            title: const Text("Thyroid Disorder"),
            value: chronicConditions.contains("Thyroid Disorder"),
            onChanged: (value) => handleConditionChange("Thyroid Disorder", value),
          ),
          CheckboxListTile(
            title: const Text("Asthma"),
            value: chronicConditions.contains("Asthma"),
           onChanged: (value) => handleConditionChange("Asthma", value),
          ),
          CheckboxListTile(
            title: const Text("None"),
            value: chronicConditions.contains("None"),
            onChanged: (value) => handleConditionChange("None", value),
          ),
          CheckboxListTile(
            title: const Text("Other"),
            value: chronicConditions.contains("Other"),
            onChanged: (value) => handleConditionChange("Other", value),
          ),
           if (chronicConditions.contains("Other"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Enter other conditions (separate with comma)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // Handle adding condition when button is pressed
                        final currentText = _otherConditionsController.text.trim();
                        if (currentText.isNotEmpty) {
                          addCondition(currentText);
                          _otherConditionsController.clear();
                        }
                      },
                    ),
                  ),
                  controller: _otherConditionsController,
                  onFieldSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      addCondition(value.trim());
                      _otherConditionsController.clear();
                    }
                  },
                  onChanged: (value) {
                    // Handle comma input
                    if (value.endsWith(',')) {
                      final condition = value.substring(0, value.length - 1).trim();
                      if (condition.isNotEmpty) {
                        addCondition(condition);
                        _otherConditionsController.clear();
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Display tags for added conditions
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: chronicConditions
                      .where((condition) => !["Diabetes", "Hypertension", "Heart Disease", "Thyroid Disorder", "Asthma", "None", "Other"].contains(condition))
                      .map((condition) => Chip(
                            label: Text(condition),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              setState(() {
                                chronicConditions.remove(condition);
                              });
                            },
                          ))
                      .toList(),
                ),
              ],
            ),

            if (showWarning)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                "You cannot select other conditions when 'None' is selected",
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(height: 20),
          // Recent Illness
          Text(
            "Recent Illness",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: hadRecentIllness,
                onChanged: (bool? value) {
                  setState(() {
                    hadRecentIllness = value!;
                  });
                },
              ),
              const Text("Yes"),
              const SizedBox(width: 30),
              Radio<bool>(
                value: false,
                groupValue: hadRecentIllness,
                onChanged: (bool? value) {
                  setState(() {
                    hadRecentIllness = value!;
                    if (!value) {
                      recentIllnessDetails = '';
                    }
                  });
                },
              ),
              const Text("No"),
            ],
          ),
          
          if (hadRecentIllness)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Please specify (e.g., flu, fever, etc.)',
                  ),
                  onChanged: (value) {
                     setState(() {
                      recentIllnessDetails = value;
                      // Check if the new value should trigger the alert
                      if (value.isNotEmpty) {
                        final validation = validateHealthInfo(medicationsController.text, value);
                        if (!validation['canDonate']) {
                          showHealthAlertDialog(validation['reason']);
                        }
                      }
                    });
                  },
                  validator: (value) {
                    if (hadRecentIllness && (value == null || value.trim().isEmpty)) {
                      return 'Please provide details about your recent illness';
                    }
                    return null;
                  },
                ),
              ],
            ),
          
          const SizedBox(height: 20),
          
          // Medications
          Text(
            "Current Medications",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: medicationsController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter medications (if none, write "None")',
            ),
            onChanged: (value) {
              // Check if the new value should trigger the alert
              if (value.isNotEmpty) {
                final validation = validateHealthInfo(value, recentIllnessDetails);
                if (!validation['canDonate']) {
                  showHealthAlertDialog(validation['reason']);
                }
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Travel History
          Text(
            "Travel History (last 12 months)",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: travelHistoryController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'List countries visited (if none, write "None")',
            ),

             onChanged: (value) {
  final input = value.trim().toLowerCase();
  
  // Reset the warning flag if field is empty
  if (input.isEmpty) {
    setState(() {
      hasShownTravelWarning = false;
    });
    return;
  }

  // Only show warning if:
  // 1. Warning hasn't been shown yet
  // 2. Input length is exactly 1 (first letter only)
  // 3. First letter is not 'n' (to avoid warning for "none")
  if (!hasShownTravelWarning && 
      input.length == 1 && 
      input[0] != 'n') {
    setState(() {
      hasShownTravelWarning = true;
    });
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Travel History Warning',
            style: TextStyle(
              color: Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please ensure that:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('• You have not been exposed to any infectious diseases'),
              Text('• You have not visited any malaria-risk areas'),
              Text('• You have not had any symptoms like fever or illness during or after travel'),
              SizedBox(height: 16),
              Text(
                'If you have any concerns about your travel history affecting your eligibility to donate blood, please consult with our healthcare staff.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('I Understand'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
},
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Tattoos/Piercings
          Text(
            "Recent Tattoos or Piercings",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: hasTattooOrPiercing,
                onChanged: (bool? value) {
                  setState(() {
                    hasTattooOrPiercing = value!;
                  });
                },
              ),
              const Text("Yes"),
              const SizedBox(width: 30),
              Radio<bool>(
                value: false,
                groupValue: hasTattooOrPiercing,
                onChanged: (bool? value) {
                  setState(() {
                    hasTattooOrPiercing = value!;
                  });
                },
              ),
              const Text("No"),
            ],
          ),
          
          if (hasTattooOrPiercing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Date of most recent tattoo/piercing:",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[800],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _selectTattooDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tattooDate != null
                              ? "${tattooDate!.day}/${tattooDate!.month}/${tattooDate!.year}"
                              : "Select Date",
                          style: TextStyle(
                            color: tattooDate != null
                                ? themeProvider.isDarkMode ? Colors.white : Colors.black
                                : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 30),
          
          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  child: Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          SizedBox(width: 15),
                          Text(
                            "Previous",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    _tabController.animateTo(_tabController.index - 1);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  child: Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 15),
                          Icon(Icons.arrow_forward, color: Colors.white)
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    if (_healthFormKey.currentState!.validate()) {
                      // Additional validation for conditionally visible fields
                      if (hasTattooOrPiercing && tattooDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select the date of your most recent tattoo/piercing")),
                        );
                        return;
                      }
                      
                      // If all validation passes, move to next tab
                      _tabController.animateTo(_tabController.index + 1);
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

  Widget availabilityInfo() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
  return Form(
    key: _availabilityFormKey,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Availability Status
          Text(
            "Availability Status",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          // Radio Buttons for Availability Status
          Column(
            children: [
              RadioListTile<String>(
                title: const Text("Immediately Available"),
                value: "Immediately Available",
                groupValue: selectedAvailability,
                onChanged: (String? value) {
                  setState(() {
                    selectedAvailability = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Available for Emergencies Only"),
                value: "Emergencies Only",
                groupValue: selectedAvailability,
                onChanged: (String? value) {
                  setState(() {
                    selectedAvailability = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text("Available by Schedule"),
                value: "By Schedule",
                groupValue: selectedAvailability,
                onChanged: (String? value) {
                  setState(() {
                    selectedAvailability = value!;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Preferred Time Slots
          Text(
            "Preferred Time Slots",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          Column(
            children: [
              CheckboxListTile(
                title: const Text("Morning (6:00 AM - 12:00 PM)"),
                value: preferredTimeSlots.contains("Morning"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      preferredTimeSlots.add("Morning");
                    } else {
                      preferredTimeSlots.remove("Morning");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Afternoon (12:00 PM - 6:00 PM)"),
                value: preferredTimeSlots.contains("Afternoon"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      preferredTimeSlots.add("Afternoon");
                    } else {
                      preferredTimeSlots.remove("Afternoon");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Evening (6:00 PM - 10:00 PM)"),
                value: preferredTimeSlots.contains("Evening"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      preferredTimeSlots.add("Evening");
                    } else {
                      preferredTimeSlots.remove("Evening");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Weekends Only"),
                value: preferredTimeSlots.contains("Weekends"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      preferredTimeSlots.add("Weekends");
                    } else {
                      preferredTimeSlots.remove("Weekends");
                    }
                  });
                },
              ),
            ],
          ),
          
          // Specific Time Range (if selected "By Schedule")
          if (selectedAvailability == "By Schedule")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Specific Time Range",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTimeSelectionRow(), // Using the existing time selection widget
              ],
            ),
          
          const SizedBox(height: 20),
          
          // Emergency Contact Information
          Text(
            "Emergency Contact",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          // Emergency Contact Name
          Text(
            "Name",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.grey[800],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: emergencyNameController, // Use the controller from the main state
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter emergency contact name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Emergency contact name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 15),
          
          // Emergency Contact Phone
          Text(
            "Phone Number",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.grey[800],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56, // Match TextField height
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Row(
                    children: [
                      const Icon(Icons.call, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        "+91",
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: emergencyPhoneController, // Use the controller from the main state
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter emergency contact number',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Emergency contact number is required';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  child: Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          SizedBox(width: 15),
                          Text(
                            "Previous",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    _tabController.animateTo(_tabController.index - 1);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  child: Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 15),
                          Icon(Icons.arrow_forward, color: Colors.white)
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    if (_availabilityFormKey.currentState!.validate()) {
                      // Additional validation
                      if (preferredTimeSlots.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select at least one preferred time slot")),
                        );
                        return;
                      }
                      
                      if (selectedAvailability == "By Schedule" && (fromTime == null || toTime == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select your specific time range")),
                        );
                        return;
                      }
                      
                      // If all validation passes, move to next tab
                      _tabController.animateTo(_tabController.index + 1);
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

Widget consentAndEligibilityInfo() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  
   // Function to show warning dialog and handle navigation
  void showWarningDialog(String title, String message, {required Function() onDismiss}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss(); // Execute the callback function after dialog is dismissed
              },
            ),
          ],
        );
      },
    );
  }


  return Form(
    key: _consentFormKey,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eligibility Questions
          Text(
            "Eligibility Questions",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Have you donated blood in the last 3 months?
           CheckboxListTile(
            title: const Text("Have you donated blood in the last 3 months?"),
            value: donatedInLast3Months,
            onChanged: (bool? value) {
              if (value == true) {
                showWarningDialog(
                  'Blood Donation Restriction',
                  'You must wait at least 3 months between blood donations. This ensures your body has adequate time to replenish its iron stores.',
                  onDismiss: () {
                    setState(() {
                      donatedInLast3Months = false; // Reset to unchecked
                    });
                    _tabController.animateTo(_tabController.index - 1); // Go back to previous tab
                  }
                );
              } else {
                setState(() {
                  donatedInLast3Months = value!;
                });
              }
            },
          ),

          // Do you have any infectious diseases?
          CheckboxListTile(
            title: const Text("Do you have any infectious diseases?"),
            value: hasInfectiousDiseases,
            onChanged: (bool? value) {
              if (value == true) {
                showWarningDialog(
                  'Medical Restriction',
                  'For safety reasons, individuals with infectious diseases cannot donate blood. This protects both donors and recipients.',
                  onDismiss: () {
                    setState(() {
                      hasInfectiousDiseases = false; // Reset to unchecked
                    });
                    _tabController.animateTo(_tabController.index - 1); // Go back to previous tab
                  }
                );
              } else {
                setState(() {
                  hasInfectiousDiseases = value!;
                });
              }
            },
          ),

          // Have you travelled to a high-risk area in the last 12 months?
           CheckboxListTile(
            title: const Text("Have you travelled to a high-risk area in the last 12 months?"),
            value: hasTravelledToHighRiskArea,
            onChanged: (bool? value) {
              if (value == true) {
                showWarningDialog(
                  'Travel Restriction',
                  'Recent travel to high-risk areas may temporarily affect your eligibility to donate blood. This is a precautionary measure to prevent transmission of region-specific diseases.',
                  onDismiss: () {
                    setState(() {
                      hasTravelledToHighRiskArea = false; // Reset to unchecked
                    });
                    _tabController.animateTo(_tabController.index - 1); // Go back to previous tab
                  }
                );
              } else {
                setState(() {
                  hasTravelledToHighRiskArea = value!;
                });
              }
            },
          ),



          // Have you had surgery in the last 6 months?
           CheckboxListTile(
            title: const Text("Have you had surgery in the last 6 months?"),
            value: hasHadSurgeryInLast6Months,
            onChanged: (bool? value) {
              if (value == true) {
                showWarningDialog(
                  'Medical Restriction',
                  'Recent surgery requires a recovery period before blood donation. This ensures your body has properly healed and maintains adequate blood volume.',
                  onDismiss: () {
                    setState(() {
                      hasHadSurgeryInLast6Months = false; // Reset to unchecked
                    });
                    _tabController.animateTo(_tabController.index - 1); // Go back to previous tab
                  }
                );
              } else {
                setState(() {
                  hasHadSurgeryInLast6Months = value!;
                });
              }
            },
          ),

          const SizedBox(height: 20),
          
          // Willingness for Emergency Donation (NEW SECTION)
          Text(
            "Willingness for Emergency Donation",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          CheckboxListTile(
            title: const Text("I am willing to donate blood in case of emergencies"),
            value: willingForEmergencyDonation ?? false, // You'll need to add this variable
            onChanged: (bool? value) {
              setState(() {
                willingForEmergencyDonation = value!;
              });
            },
          ),
          
          const SizedBox(height: 20),

          // Consent for Donation
          Text(
            "Consent for Donation",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width:10),
          Text(
            "*(required)",
            style:TextStyle(
              color:Colors.red,
              fontSize:14,
            )
          ),
          const SizedBox(height: 10),

          CheckboxListTile(
            title: const Text("I agree to the terms and conditions of blood donation."),
            value: consentForDonation,
            onChanged: (bool? value) {
              setState(() {
                consentForDonation = value!;
              });
            },
          ),

          const SizedBox(height: 20),

          // Consent for Notifications
          Text(
            "Consent for Notifications",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          CheckboxListTile(
            title: const Text("I agree to receive notifications about blood donation campaigns or urgent requests."),
            value: consentForNotifications,
            onChanged: (bool? value) {
              setState(() {
                consentForNotifications = value!;
              });
            },
          ),

          const SizedBox(height: 30),

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  child: Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          SizedBox(width: 15),
                          Text(
                            "Previous",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    _tabController.animateTo(_tabController.index - 1);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  child: Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 15),
                          Icon(Icons.arrow_forward, color: Colors.white)
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    if (_consentFormKey.currentState!.validate()) {
                      // Additional validation for consent
                      if (!consentForDonation) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("You must agree to the terms and conditions to proceed.")),
                        );
                        return;
                      }

                      // If all validation passes, move to next tab
                      _tabController.animateTo(_tabController.index + 1);
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

Widget documentUploadWidget(String title, File? file, String? fileName, VoidCallback pickFileCallback) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName ?? "No file selected",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: pickFileCallback,
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text(
                  "Choose PDF",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

 Widget documentUploadTab() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  return Scaffold(
    body: SingleChildScrollView(
      child: Stack(
        children: [
          // Main content scrollable area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                documentUploadWidget("Upload ID Proof (Required)", idProof, idProofName, () => pickFile('idProof')),
                documentUploadWidget("Upload Medical Certificate (Optional)", medicalCertificate, medicalCertificateName, () => pickFile('medicalCertificate')),
                documentUploadWidget("Upload Donor Card (Optional)", donorCard, donorCardName, () => pickFile('donorCard')),
                // Add padding at the bottom to ensure content doesn't get hidden behind the button
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          // Fixed button at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: isloading ? 70 : 20, // Adjust bottom margin when loader is visible
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  saveBloodDonorDetails();
                },
                child: Container(
                  width: 250,
                  height: 50,
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.orange,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      "Save Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Loading indicator positioned below the save button
          if (isloading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

}