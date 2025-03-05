import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/pages/address_selector.dart';
import 'package:food_delivery_app/pages/fire_and_safety_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/service/database.dart';

class EditFireAndSafetyDetails extends StatefulWidget {
  final String userId;
  final String fireAndsafetyId;
  final Map<String, dynamic> fireAndSafetyDetails;
  final String location;

  const EditFireAndSafetyDetails({
    super.key,
    required this.userId,
    required this.fireAndsafetyId,
    required this.fireAndSafetyDetails,
    required this.location,
  });

  @override
  State<EditFireAndSafetyDetails> createState() => _EditFireAndSafetyDetailsState();
}

class _EditFireAndSafetyDetailsState extends State<EditFireAndSafetyDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ServicenameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String? _selectedType;
  String? _selectedAvailability;
  String _selectedGender = "Male";
  List<String> selectedServices = [];
  File? _certificateFile;
  String? certificateFileName;
  File? selectedImage;
  bool isLoading = false;

  TimeOfDay? fromTime;
  TimeOfDay? toTime;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.fireAndSafetyDetails['name'];
    _ServicenameController.text = widget.fireAndSafetyDetails['Servicename'];
    _ageController.text = widget.fireAndSafetyDetails['age'].toString();
    _addressController.text = widget.fireAndSafetyDetails['address'];
    _phoneController.text = widget.fireAndSafetyDetails['contact'];
    _emailController.text = widget.fireAndSafetyDetails['email'];
    _descriptionController.text = widget.fireAndSafetyDetails['description'];
    _experienceController.text = widget.fireAndSafetyDetails['experience'].toString();
    _selectedType = widget.fireAndSafetyDetails['facilityType'];
    _selectedAvailability = widget.fireAndSafetyDetails['availability']['type'];
    _selectedGender = widget.fireAndSafetyDetails['gender'];
    selectedServices = List<String>.from(widget.fireAndSafetyDetails['services']);
    certificateFileName = widget.fireAndSafetyDetails['certificatePDF'].toString().split('/').last;

     if (widget.fireAndSafetyDetails['availability']['fromTime'] != null) {
    final fromParts = widget.fireAndSafetyDetails['availability']['fromTime'].split(' ');
    final fromTimeParts = fromParts[0].split(':');
    final fromHour = int.parse(fromTimeParts[0]);
    final fromMinute = int.parse(fromTimeParts[1]);
    fromTime = TimeOfDay(hour: fromHour, minute: fromMinute);
  }

  if (widget.fireAndSafetyDetails['availability']['toTime'] != null) {
    final toParts = widget.fireAndSafetyDetails['availability']['toTime'].split(' ');
    final toTimeParts = toParts[0].split(':');
    final toHour = int.parse(toTimeParts[0]);
    final toMinute = int.parse(toTimeParts[1]);
    toTime = TimeOfDay(hour: toHour, minute: toMinute);
  }

  }

  Future pickImageFromGallery() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      selectedImage = File(returnedImage.path);
    });
  }

  Future pickImageFromCamera() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      selectedImage = File(returnedImage.path);
    });
  }

  Future<void> pickCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _certificateFile = File(result.files.single.path!);
          certificateFileName = path.basename(result.files.single.path!);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error picking PDF: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child("fire_safety_images/$fileName.jpg");
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<String> uploadPDFToFirebase(File pdfFile) async {
    String fileName = "certificate_${DateTime.now().millisecondsSinceEpoch}.pdf";
    Reference storageRef = FirebaseStorage.instance.ref().child("fire_safety_certificates/$fileName");
    UploadTask uploadTask = storageRef.putFile(pdfFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> updateDetails() async {
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

    setState(() {
      isLoading = true;
    });

    try {
      String imageUrl = widget.fireAndSafetyDetails['profileImage'];
      String pdfUrl = widget.fireAndSafetyDetails['certificatePDF'];

      if (selectedImage != null) {
        imageUrl = await uploadImageToFirebase(selectedImage!);
      }

      if (_certificateFile != null) {
        pdfUrl = await uploadPDFToFirebase(_certificateFile!);
      }

      String availabilityTime = "";
    String? formattedFromTime;
    String? formattedToTime;

    if (_selectedAvailability == "24/7") {
      availabilityTime = "24 hours (All days)";
    } else if (_selectedAvailability != null && fromTime != null && toTime != null) {
      formattedFromTime = fromTime!.format(context);
      formattedToTime = toTime!.format(context);
      availabilityTime = "$formattedFromTime - $formattedToTime";
    }

      Map<String, dynamic> updateInfo = {
        'name': _nameController.text.trim(),
        'Servicename': _ServicenameController.text.trim(),
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'facilityType': _selectedType,
        'email': _emailController.text.trim(),
        'address': _addressController.text,
        'Location': widget.fireAndSafetyDetails['Location'],
        'contact': _phoneController.text.trim(),
        'profileImage': imageUrl,
        'experience': int.parse(_experienceController.text),
        'certificatePDF': pdfUrl,
        'description': _descriptionController.text,
        'services': selectedServices,
        'availability': {
          'type': _selectedAvailability,
        'timeSlot': availabilityTime,
        'fromTime': formattedFromTime,
        'toTime': formattedToTime,
        'duration': _calculateDuration(fromTime, toTime),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await DatabaseMethods().updatefireAndsafetyDetail(widget.fireAndsafetyId, updateInfo);

      Fluttertoast.showToast(
        msg: "Fire and Safety details updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      Navigator.push(context, MaterialPageRoute(builder: (context)=>FireAndSafetyPage(userId: widget.userId, location: widget.location)));
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
        isLoading = false;
      });
    }
  }

  String _calculateDuration(TimeOfDay? from, TimeOfDay? to) {
  if (from == null || to == null) return "";
  
  int fromMinutes = from.hour * 60 + from.minute;
  int toMinutes = to.hour * 60 + to.minute;
  
  // Handle cases where end time is on the next day
  if (toMinutes < fromMinutes) {
    toMinutes += 24 * 60; // Add 24 hours worth of minutes
  }
  
  int totalMinutes = toMinutes - fromMinutes;
  int hours = totalMinutes ~/ 60;
  int minutes = totalMinutes % 60;
  
  return "${hours}h ${minutes}m";
}

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.orange,
        title: Text(
          "Edit Fire & Safety Details",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                  controller: _nameController,
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
                Text(
                  "Facility/Service Name",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ServicenameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter facility/service name',
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
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.fill,
                              ))
                          : widget.fireAndSafetyDetails['profileImage'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.fireAndSafetyDetails['profileImage'],
                                    fit: BoxFit.fill,
                                  ),
                                )
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
                                  pickImageFromCamera();
                                  Navigator.pop(context);
                                },
                                child: const Text("Upload From Camera"),
                              ),
                              TextButton(
                                onPressed: () {
                                  pickImageFromGallery();
                                  Navigator.pop(context);
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
                Text(
                  "Facility Type",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                    fontSize: 18.0,
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
                      hint: const Text("Select facility type"),
                      value: _selectedType,
                      items: [
                        'Fire Station',
                        'Emergency Response Unit',
                        'Fire Safety Training Center',
                        'Safety Equipment Supplier',
                        'Hazmat Response Unit'
                      ]
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                        controller: _ageController,
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
                              groupValue: _selectedGender,
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedGender = value!;
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
                              groupValue: _selectedGender,
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedGender = value!;
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
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter contact number',
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
                    color: Colors.black,
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
                        controller: _addressController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter facility address',
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
                              _addressController.text =
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
                  controller: _emailController,
                  enabled: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter Email Address",
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
                Text(
                  "Years of Experience",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter years of experience',
                  ),
                  keyboardType: TextInputType.number,
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
                const SizedBox(height: 20),
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
                      hint: const Text("Select availability"),
                      value: _selectedAvailability,
                      items: [
                        '24/7',
                        'Day Shift Only',
                        'Night Shift Only',
                        'On-Call'
                      ]
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAvailability = newValue;
                          if (newValue != "24/7") {
                            fromTime = null;
                            toTime = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
                if (_selectedAvailability != "24/7" && _selectedAvailability != null)
                  _buildTimeSelectionRow(),
                const SizedBox(height: 20),
                _buildServiceCheckboxes(),
                const SizedBox(height: 20),
                _buildEquipmentSection(),
                const SizedBox(height: 20),
                Text(
                  "Description",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter facility/service description',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is mandatory';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  "Upload Certificate (PDF)",
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
                        certificateFileName ?? "No file selected",
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: pickCertificate,
                        icon: const Icon(Icons.upload_file, color: Colors.white),
                        label: const Text(
                          "Choose PDF",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: updateDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.isDarkMode ? Colors.deepOrange : Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                          ),
                          child: Text(
                            "Update Details",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildServiceCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Services Offered",
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: [
            'Fire Fighting',
            'Rescue Operations',
            'Fire Safety Training',
            'Equipment Maintenance',
            'Fire Audits',
            'Emergency Medical Services',
            'Hazardous Material Response',
            'Fire Prevention Consultancy'
          ].map((service) {
            return FilterChip(
              label: Text(service),
              selected: selectedServices.contains(service),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedServices.add(service);
                  } else {
                    selectedServices.remove(service);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.orange[200],
              checkmarkColor: Colors.deepOrange,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Equipment",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ExpansionTile(
          title: Text(
            "Basic Equipment",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 5,
              children: [
                'Fire Extinguishers',
                'Fire Hoses',
                'Breathing Apparatus',
                'Protective Gear'
              ].map((equipment) {
                return FilterChip(
                  label: Text(equipment),
                  selected: widget.fireAndSafetyDetails['equipment']['Basic Equipment'].contains(equipment),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        widget.fireAndSafetyDetails['equipment']['Basic Equipment'].add(equipment);
                      } else {
                        widget.fireAndSafetyDetails['equipment']['Basic Equipment'].remove(equipment);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.orange[200],
                  checkmarkColor: Colors.deepOrange,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
        ExpansionTile(
          title: Text(
            "Vehicles",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 5,
              children: [
                'Fire Trucks',
                'Rescue Vehicles',
                'Ambulances',
                'Water Tankers'
              ].map((vehicle) {
                return FilterChip(
                  label: Text(vehicle),
                  selected: widget.fireAndSafetyDetails['equipment']['Vehicles'].contains(vehicle),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        widget.fireAndSafetyDetails['equipment']['Vehicles'].add(vehicle);
                      } else {
                        widget.fireAndSafetyDetails['equipment']['Vehicles'].remove(vehicle);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.orange[200],
                  checkmarkColor: Colors.deepOrange,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
        ExpansionTile(
          title: Text(
            "Specialized Equipment",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 5,
              children: [
                'Hydraulic Tools',
                'Thermal Imaging Cameras',
                'Chemical Response Kits',
                'Height Rescue Equipment'
              ].map((specializedEquipment) {
                return FilterChip(
                  label: Text(specializedEquipment),
                  selected: widget.fireAndSafetyDetails['equipment']['Specialized Equipment'].contains(specializedEquipment),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        widget.fireAndSafetyDetails['equipment']['Specialized Equipment'].add(specializedEquipment);
                      } else {
                        widget.fireAndSafetyDetails['equipment']['Specialized Equipment'].remove(specializedEquipment);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.orange[200],
                  checkmarkColor: Colors.deepOrange,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ],
    );
  }
}