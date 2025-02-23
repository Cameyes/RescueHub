import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/address_selector.dart';
import 'package:food_delivery_app/pages/map_page.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';

class AddMedicalAssistanceDetails extends StatefulWidget {

  final String userId;
  // ignore: non_constant_identifier_names
  final String Loc;

  const AddMedicalAssistanceDetails({super.key,required this.userId,required this.Loc});

  @override
  State<AddMedicalAssistanceDetails> createState() => _AddMedicalAssistanceDetailsState();
}

class _AddMedicalAssistanceDetailsState extends State<AddMedicalAssistanceDetails> {

  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController=TextEditingController();
  TextEditingController descriptionController=TextEditingController();
  TextEditingController otherSpecializationController = TextEditingController();
  TextEditingController experienceController=TextEditingController();

  
  String selectedGender = "Male";
  String selectedQualification="Doctor";
  String selectedSpecialization="General Medicine";



   // Availability related variables
  String selectedAvailability = "Full Time";
  TimeOfDay? fromTime;
  TimeOfDay? toTime;

  bool isloading = false; //Controller for CircularProgressIndicator

  File? selectedImage_one;

  //Variable for Form Creation
  final _formKey = GlobalKey<FormState>();
  
  


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

   Future<String> uploadPDFToFirebase(File pdfFile) async {
    String fileName = "licence_${DateTime.now().millisecondsSinceEpoch}.pdf";
    Reference storageRef = FirebaseStorage.instance.ref().child("licences/$fileName");
    UploadTask uploadTask = storageRef.putFile(pdfFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> saveDetails() async {
  // Validate whether all fields are filled or not
  if (!_formKey.currentState!.validate()) {
    Fluttertoast.showToast(
      msg: "Please fill in all required fields",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }

  // Check for image upload
  if (selectedImage_one == null) {
    Fluttertoast.showToast(
      msg: "Please upload an image.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    return;
  }


  setState(() {
    isloading = true;
  });

  try {
    // Upload image to Firebase Storage
    String imageUrl = await uploadImageToFirebase(selectedImage_one!);


    // Generate unique ID for the entry
    String id = randomAlphaNumeric(10);

    // Get current date and time
    DateTime now = DateTime.now();
    String formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    String formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    // Initialize availability-related variables
    String availabilityTime = "";
    int durationHours = 0;
    int durationMinutes = 0;
    String? formattedFromTime;
    String? formattedToTime;

    // Calculate time-related fields based on availability type
    if (selectedAvailability == "Specific Hours" || selectedAvailability == "Part Time") {
      if (fromTime != null && toTime != null) {
        formattedFromTime = fromTime!.format(context);
        formattedToTime = toTime!.format(context);
        availabilityTime = "$formattedFromTime - $formattedToTime";

        // Calculate time difference
        int fromMinutes = fromTime!.hour * 60 + fromTime!.minute;
        int toMinutes = toTime!.hour * 60 + toTime!.minute;
        
        // Handle cases where end time is on the next day
        if (toMinutes < fromMinutes) {
          toMinutes += 24 * 60; // Add 24 hours worth of minutes
        }
        
        int totalMinutes = toMinutes - fromMinutes;
        durationHours = totalMinutes ~/ 60;
        durationMinutes = totalMinutes % 60;
      }
    } else if (selectedAvailability == "Full Time") {
      availabilityTime = "Full Time (24 hours)";
      durationHours = 24;
      durationMinutes = 0;
    }

    // Prepare data for Firestore
    Map<String, dynamic> medicalInfoMap = {
      'userId': widget.userId,
      'id': id,
      'name': nameController.text.trim(),
      'age': int.parse(ageController.text),
      'gender': selectedGender,
      'email': emailController.text.trim(),
      'Address': addressController.text,
      'location': widget.Loc,
      'contact': contactController.text.trim(),
      'profileImage': imageUrl,
      'experience':int.parse(experienceController.text),
      'description':descriptionController.text,
      'qualification':selectedQualification,
      'specialization':selectedSpecialization!="Other"?selectedSpecialization:otherSpecializationController.text.trim(),
      'availability': {
        'type': selectedAvailability,
        'timeSlot': availabilityTime,
        'fromTime': formattedFromTime,
        'toTime': formattedToTime,
        'duration': "${durationHours}h ${durationMinutes}m"
      },
      'createdAt': {
        'date': formattedDate,
        'time': formattedTime,
      },
      'status': 'active',
      'lastUpdated': FieldValue.serverTimestamp(),

    };

    // Save data to Firestore
    await DatabaseMethods().setmedicalDetails(medicalInfoMap, id);

    // Show success message
    Fluttertoast.showToast(
      msg: "Medical Personnel details saved successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // Clear form fields
    nameController.clear();
    ageController.clear();
    contactController.clear();
    emailController.clear();
    descriptionController.clear();
    experienceController.clear();
    setState(() {
      
      selectedImage_one = null;
      fromTime = null;
      toTime = null;
      selectedAvailability = "Full Time";
    });

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MapPage(userId: widget.userId,selectedLoc: widget.Loc,)));

  } catch (e) {
    Fluttertoast.showToast(
      msg: "Error: $e",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } finally {
    setState(() {
      isloading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.orange,
        title: Text(
          "Add Medical Assistant Details",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : const Color.fromARGB(255, 255, 255, 255),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding:  const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                    fontSize: 18.0,
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Medical Qualification",
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10,),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                                value: selectedQualification,
                                items: ["Doctor", "Nurse", "Paramedic", "Pharmacist"].map((String qualification) {
                                  return DropdownMenuItem<String>(
                                    value: qualification,
                                    child: Text(qualification),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      selectedQualification = newValue;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: "Select Qualification",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                        ),
                      ],
                    ),
                    
                    Column(
                      children: [
                        Text(
                          "Experience",
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10,),
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                  controller: experienceController,
                  enabled: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "In Years",
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
                  ],
                ),
    const SizedBox(height: 10,),
    Text(
                  "Specialization",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10,),
                //create a dropdown menu for selecting specialization
                DropdownButtonFormField<String>(
                   value: selectedSpecialization,
                  items: ["General Medicine", "Surgery", "Pediatrics", "Other"].map((String specialization) {
                    return DropdownMenuItem<String>(
                      value: specialization,
                      child: Text(specialization),
                    );
                  }).toList(), 
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedSpecialization = newValue;
                        if (newValue != "Other") {
                          otherSpecializationController.clear();
                        }
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Select Specialization",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  ),
                  if (selectedSpecialization == "Other") ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: otherSpecializationController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Please specify your specialization',
                      labelText: 'Other Specialization',
                    ),
                    validator: (value) {
                      if (selectedSpecialization == "Other" && (value == null || value.trim().isEmpty)) {
                        return 'Please specify your specialization';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 10,),
                Text(
                  "Availability",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedAvailability,
                      items: ["Full Time", "Part Time", "Specific Hours"]
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedAvailability = newValue!;
                          if (newValue == "Full Time") {
                            fromTime = null;
                            toTime = null;
                          }
                        });
                      }, 
                    ),
                  ),
                ),
                if (selectedAvailability != "Full Time") _buildTimeSelectionRow(),
                const SizedBox(height: 20),
                Text("Description",
                      style: TextStyle(
                      color: themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold
                          ),),
                  const SizedBox(height: 20,),
                  TextFormField(
                      autocorrect: true,
                      controller: descriptionController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 60, horizontal: 12),
                        border: OutlineInputBorder(),
                        hintText: "Tell About Yourself",
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is mandatory';
                        }
                        return null;
                      },
                    ),
                     const SizedBox(height: 20,),
                //Save Details Button
                   Center(
                    child: ElevatedButton(
                      onPressed: (){
                        //logic for saving details
                       saveDetails();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.isDarkMode ?Colors.deepOrange : Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        "Save Details",
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : const Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  if (isloading)
                Container(
                  color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.blue,),
                  ),
                ),
              ],
            ),
            ),
        )),
    );
  }
}