import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/address_selector.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class EditBloodDonorDetails extends StatefulWidget {
  final String userId;
  final String donorId;
  final Map<String, dynamic> bloodDonorData;
  final String location;

  const EditBloodDonorDetails({super.key, required this.userId, required this.donorId,required this.bloodDonorData,required this.location});

  @override
  State<EditBloodDonorDetails> createState() => _EditBloodDonorDetailsState();
}

class _EditBloodDonorDetailsState extends State<EditBloodDonorDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController contactController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController weightController;
  late TextEditingController medicationsController;
  late TextEditingController travelHistoryController;
  late TextEditingController emergencyNameController;
  late TextEditingController emergencyPhoneController;
  late TextEditingController _otherConditionsController;

  List<String> preferredTimeSlots = [];
  List<String> chronicConditions = [];
  bool hadRecentIllness = false;
  String recentIllnessDetails = '';
  bool hasTattooOrPiercing = false;
  DateTime? tattooDate;
  String selectedGender = "Male";
  String? selectedBloodGroup;
  List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  String selectedDonationFrequency = "First time Donor";
  DateTime? lastDonationDate;
  String selectedDonType = "Whole Blood";
  String selectedAvailability = "Full Time";
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  bool willingForEmergencyDonation = false;
  bool consentForDonation = false;
  bool consentForNotifications = false;

   bool donatedInLast3Months = false;
  bool hasInfectiousDiseases = false;
  bool hasTravelledToHighRiskArea = false;
  bool hasHadSurgeryInLast6Months = false;

  File? selectedImage_one;
  File? idProof;
  File? medicalCertificate;
  File? donorCard;
  String? idProofName;
  String? medicalCertificateName;
  String? donorCardName;

  final _personalFormKey = GlobalKey<FormState>();
  final _bloodFormKey = GlobalKey<FormState>();
  final _healthFormKey = GlobalKey<FormState>();
  final _availabilityFormKey = GlobalKey<FormState>();
  final _consentFormKey = GlobalKey<FormState>();

  bool isloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  
    // Initialize controllers with empty values to prevent LateInitializationError
  nameController = TextEditingController();
  ageController = TextEditingController();
  contactController = TextEditingController();
  emailController = TextEditingController();
  addressController = TextEditingController();
  weightController = TextEditingController();
  medicationsController = TextEditingController();
  travelHistoryController = TextEditingController();
  emergencyNameController = TextEditingController();
  emergencyPhoneController = TextEditingController();
  _otherConditionsController = TextEditingController();


    fetchDonorDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _otherConditionsController.dispose();
    super.dispose();
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

  Future<void> fetchDonorDetails() async {
  try {
    DocumentSnapshot donorSnapshot = await FirebaseFirestore.instance.collection('bloodDonor').doc(widget.donorId).get();
    if (donorSnapshot.exists) {
      Map<String, dynamic> donorData = donorSnapshot.data() as Map<String, dynamic>;

      nameController = TextEditingController(text: donorData['name']);
      ageController = TextEditingController(text: donorData['age'].toString());
      contactController = TextEditingController(text: donorData['contact']);
      emailController = TextEditingController(text: donorData['email']);
      addressController = TextEditingController(text: donorData['address']);
      weightController = TextEditingController(text: donorData['weight']);
      medicationsController = TextEditingController(text: donorData['medications']);
      travelHistoryController = TextEditingController(text: donorData['travelHistory']);
      emergencyNameController = TextEditingController(text: donorData['emergencyContact']['name']);
      emergencyPhoneController = TextEditingController(text: donorData['emergencyContact']['phone']);
      _otherConditionsController = TextEditingController();

      selectedGender = donorData['gender'];
      selectedBloodGroup = donorData['bloodGroup'];
      selectedDonationFrequency = donorData['donationFrequency'];
      lastDonationDate = donorData['lastDonationDate'] != "" ? DateTime.parse(donorData['lastDonationDate']) : null;
      selectedDonType = donorData['donationType'];
      selectedAvailability = donorData['availability']['status'];
      preferredTimeSlots = List<String>.from(donorData['availability']['timeSlots']);
      fromTime = donorData['availability']['fromTime'] != "Not set" ? TimeOfDay.fromDateTime(DateTime.parse(donorData['availability']['fromTime'])) : null;
      toTime = donorData['availability']['toTime'] != "Not set" ? TimeOfDay.fromDateTime(DateTime.parse(donorData['availability']['toTime'])) : null;
      willingForEmergencyDonation = donorData['willingForEmergencyDonation'] ?? false;
      consentForDonation = donorData['consent']['donationConsent'];
      consentForNotifications = donorData['consent']['notificationsConsent'];
      chronicConditions = List<String>.from(donorData['chronicConditions']);
      hadRecentIllness = donorData['hadRecentIllness'] ?? false;
      recentIllnessDetails = donorData['recentIllnessDetails'] ?? '';
      hasTattooOrPiercing = donorData['hasTattooOrPiercing'] ?? false;
      tattooDate = donorData['tattooDate'] != "" ? DateTime.parse(donorData['tattooDate']) : null;

      // Fetch URLs for uploaded files
      if (donorData['profileImage'] != null && donorData['profileImage'] != "") {
        selectedImage_one = await downloadFile(donorData['profileImage']);
      }
      if (donorData['documents']['idProof'] != null && donorData['documents']['idProof'] != "") {
        idProof = await downloadFile(donorData['documents']['idProof']);
        idProofName = donorData['documents']['idProof'].split('/').last;
      }
      if (donorData['documents']['medicalCertificate'] != null && donorData['documents']['medicalCertificate'] != "") {
        medicalCertificate = await downloadFile(donorData['documents']['medicalCertificate']);
        medicalCertificateName = donorData['documents']['medicalCertificate'].split('/').last;
      }
      if (donorData['documents']['donorCard'] != null && donorData['documents']['donorCard'] != "") {
        donorCard = await downloadFile(donorData['documents']['donorCard']);
        donorCardName = donorData['documents']['donorCard'].split('/').last;
      }

      setState(() {});
    }
  } catch (e) {
    Fluttertoast.showToast(
      msg: "Error fetching donor details: $e",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}

Future<File?> downloadFile(String url) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/${url.split('/').last}';
    final file = File(path);
    final ref = FirebaseStorage.instance.refFromURL(url);
    await ref.writeToFile(file);
    return file;
  } catch (e) {
    print("Error downloading file: $e");
    return null;
  }
}

  Future<void> updateBloodDonorDetails() async {
    /*if (!(_personalFormKey.currentState?.validate() ?? false) ||
        !(_bloodFormKey.currentState?.validate() ?? false) ||
        !(_healthFormKey.currentState?.validate() ?? false) ||
        !(_availabilityFormKey.currentState?.validate() ?? false) ||
        !(_consentFormKey.currentState?.validate() ?? false)) {
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
    setState(() {
      isloading = true;
    });

    try {
      String imageUrl = selectedImage_one != null ? await uploadImageToFirebase(selectedImage_one!) : "";
      String? idProofUrl = idProof != null ? await uploadFileToFirebase(idProof!, 'idProof') : null;
      String? medicalCertUrl = medicalCertificate != null ? await uploadFileToFirebase(medicalCertificate!, 'medicalCertificate') : null;
      String? donorCardUrl = donorCard != null ? await uploadFileToFirebase(donorCard!, 'donorCard') : null;

      Map<String, dynamic> bloodDonorInfo = {
        'userId': widget.userId,
        'name': nameController.text.trim(),
        'age': ageController.text.isNotEmpty ? int.tryParse(ageController.text) ?? 0 : 0,
        'gender': selectedGender,
        'bloodGroup': selectedBloodGroup ?? "Not specified",
        'donationFrequency': selectedDonationFrequency,
        'lastDonationDate': lastDonationDate?.toIso8601String() ?? "",
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
        'location': widget.location,
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
        'profileImage': imageUrl.isNotEmpty ? imageUrl : widget.bloodDonorData['profileImage'],
        'status': 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await DatabaseMethods().updatebloodDonorDetail(widget.donorId, bloodDonorInfo);

      Fluttertoast.showToast(
        msg: "Blood donor details updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating donor details: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isloading = false;
      });
    }
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child("images/$fileName.jpg");
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Center(child: const Text('Edit Blood Donor Details', style: TextStyle(fontWeight: FontWeight.bold))),
        automaticallyImplyLeading: false,
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.orange,
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
                personalInfo(),
                bloodInfo(),
                healthInfo(),
                availabilityInfo(),
                consentAndEligibilityInfo(),
                documentUploadTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget personalInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Form(
      key: _personalFormKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        : widget.bloodDonorData['profileImage'] != null && widget.bloodDonorData['profileImage'] != ""
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.bloodDonorData['profileImage'],
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              Text(
                "Location",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
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
              const SizedBox(height: 20),
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
                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.deepOrange,
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
                                ),
                              ),
                              const SizedBox(width: 15),
                              Icon(Icons.arrow_forward, color: Colors.white)
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        if (_personalFormKey.currentState!.validate()) {
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
          lastDonationDate = picked;

          final duration = DateTime.now().difference(lastDonationDate!);
          final monthsElapsed = duration.inDays / 30;

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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                "Donation Frequency",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
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
              if (selectedDonationFrequency == "Regular Donor" || selectedDonationFrequency == "Non-Regular Donor")
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
              const SizedBox(height: 20),
              Text(
                "Preferred Donation Type",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 60),
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
      ),
    );
  }

  Widget healthInfo() {
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
          tattooDate = picked;

          final duration = DateTime.now().difference(tattooDate!);
          final monthsElapsed = duration.inDays / 30;

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

    return Form(
      key: _healthFormKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Weight (kg)",
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
              Text("Chronic Medical Conditions",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text("(Check on \"None\" if you have no medical conditions)",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text("Diabetes"),
                value: chronicConditions.contains("Diabetes"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      chronicConditions.add("Diabetes");
                    } else {
                      chronicConditions.remove("Diabetes");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Hypertension (High Blood Pressure)"),
                value: chronicConditions.contains("Hypertension"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      chronicConditions.add("Hypertension");
                    } else {
                      chronicConditions.remove("Hypertension");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Heart Disease"),
                value: chronicConditions.contains("Heart Disease"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      chronicConditions.add("Heart Disease");
                    } else {
                      chronicConditions.remove("Heart Disease");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Thyroid Disorder"),
                value: chronicConditions.contains("Thyroid Disorder"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      chronicConditions.add("Thyroid Disorder");
                    } else {
                      chronicConditions.remove("Thyroid Disorder");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Asthma"),
                value: chronicConditions.contains("Asthma"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      chronicConditions.add("Asthma");
                    } else {
                      chronicConditions.remove("Asthma");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("None"),
                value: chronicConditions.contains("None"),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      chronicConditions.clear();
                      chronicConditions.add("None");
                    } else {
                      chronicConditions.remove("None");
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text("Other"),
                value: chronicConditions.contains("Other"),
                onChanged: (bool? value) {
                  setState(() {
                    if  (value == true) {
                      chronicConditions.add("Other");
                    } else {
                      chronicConditions.remove("Other");
                    }
                  });
                },
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
                            final currentText = _otherConditionsController.text.trim();
                            if (currentText.isNotEmpty) {
                              _addCondition(currentText);
                              _otherConditionsController.clear();
                            }
                          },
                        ),
                      ),
                      controller: _otherConditionsController,
                      onFieldSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _addCondition(value.trim());
                          _otherConditionsController.clear();
                        }
                      },
                      onChanged: (value) {
                        if (value.endsWith(',')) {
                          final condition = value.substring(0, value.length - 1).trim();
                          if (condition.isNotEmpty) {
                            _addCondition(condition);
                            _otherConditionsController.clear();
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 10),
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
              const SizedBox(height: 20),
              Text("Recent Illness",
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
                        if (!value) {
                          recentIllnessDetails = '';
                        }
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
              Text("Current Medications",
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text("Travel History (last 12 months)",
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text("Recent Tattoos or Piercings",
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
      ),
    );
  }

  Widget availabilityInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Form(
      key: _availabilityFormKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Availability Status",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
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
                    _buildTimeSelectionRow(),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                "Emergency Contact",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Name",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[800],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: emergencyNameController,
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
                    height: 56,
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
                      controller: emergencyPhoneController,
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
      ),
    );
  }

  Widget consentAndEligibilityInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Eligibility Questions",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
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
                value: willingForEmergencyDonation,
                onChanged: (bool? value) {
                  setState(() {
                    willingForEmergencyDonation = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Consent for Donation",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                          if (!consentForDonation) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("You must agree to the terms and conditions to proceed.")),
                            );
                            return;
                          }
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
      ),
    );
  }

  Widget documentUploadWidget(String title, File? file, String? fileName, VoidCallback pickFileCallback, String? downloadUrl) {
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
              fileName ?? (downloadUrl != null ? downloadUrl.split('/').last : "No file selected"),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  documentUploadWidget("Upload ID Proof (Required)", idProof, idProofName, () => pickFile('idProof'), widget.bloodDonorData['documents']['idProof']),
documentUploadWidget("Upload Medical Certificate (Optional)", medicalCertificate, medicalCertificateName, () => pickFile('medicalCertificate'), widget.bloodDonorData['documents']['medicalCertificate']),
documentUploadWidget("Upload Donor Card (Optional)", donorCard, donorCardName, () => pickFile('donorCard'), widget.bloodDonorData['documents']['donorCard']),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: isloading ? 70 : 20,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {
                    updateBloodDonorDetails();
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
                        "Save Changes",
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

  
  Future<void> updatebloodDonorDetail() async {
    if (!(_personalFormKey.currentState?.validate() ?? false) ||
        !(_bloodFormKey.currentState?.validate() ?? false) ||
        !(_healthFormKey.currentState?.validate() ?? false) ||
        !(_availabilityFormKey.currentState?.validate() ?? false) ||
        !(_consentFormKey.currentState?.validate() ?? false)) {
      Fluttertoast.showToast(
        msg: "Please fill in all required fields.",
        toastLength: Toast.LENGTH_SHORT,
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
      String imageUrl = selectedImage_one != null ? await uploadImageToFirebase(selectedImage_one!) : "";
      String? idProofUrl = idProof != null ? await uploadFileToFirebase(idProof!, 'idProof') : null;
      String? medicalCertUrl = medicalCertificate != null ? await uploadFileToFirebase(medicalCertificate!, 'medicalCertificate') : null;
      String? donorCardUrl = donorCard != null ? await uploadFileToFirebase(donorCard!, 'donorCard') : null;

      Map<String, dynamic> bloodDonorInfo = {
        'userId': widget.userId,
        'name': nameController.text.trim(),
        'age': ageController.text.isNotEmpty ? int.tryParse(ageController.text) ?? 0 : 0,
        'gender': selectedGender,
        'bloodGroup': selectedBloodGroup ?? "Not specified",
        'donationFrequency': selectedDonationFrequency,
        'lastDonationDate': lastDonationDate?.toIso8601String() ?? "",
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
        'location': widget.location,
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
        'profileImage': imageUrl.isNotEmpty ? imageUrl : widget.bloodDonorData['profileImage'],
        'status': 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await DatabaseMethods().updatebloodDonorDetail(widget.donorId, bloodDonorInfo);

      Fluttertoast.showToast(
        msg: "Blood donor details updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating donor details: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isloading = false;
      });
    }
  }
}