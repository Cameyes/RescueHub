import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:food_delivery_app/pages/fire_and_safety_page.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/address_selector.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';

class AddFireAndSafetyDetails extends StatefulWidget {
  final String userId;
  final String location;
  const AddFireAndSafetyDetails({super.key, required this.userId, required this.location});

  @override
  State<AddFireAndSafetyDetails> createState() => _AddFireAndSafetyDetailsState();
}

class _AddFireAndSafetyDetailsState extends State<AddFireAndSafetyDetails> {
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

  final List<String> facilityTypes = [
    'Fire Station',
    'Emergency Response Unit',
    'Fire Safety Training Center',
    'Safety Equipment Supplier',
    'Hazmat Response Unit'
  ];
  
  final List<String> availabilityOptions = [
    '24/7',
    'Day Shift Only',
    'Night Shift Only',
    'On-Call'
  ];
  
  final List<String> serviceOptions = [
    'Fire Fighting',
    'Rescue Operations',
    'Fire Safety Training',
    'Equipment Maintenance',
    'Fire Audits',
    'Emergency Medical Services',
    'Hazardous Material Response',
    'Fire Prevention Consultancy'
  ];

  final Map<String, List<String>> requiredEquipment = {
    'Basic Equipment': [
      'Fire Extinguishers',
      'Fire Hoses',
      'Breathing Apparatus',
      'Protective Gear'
    ],
    'Vehicles': [
      'Fire Trucks',
      'Rescue Vehicles',
      'Ambulances',
      'Water Tankers'
    ],
    'Specialized Equipment': [
      'Hydraulic Tools',
      'Thermal Imaging Cameras',
      'Chemical Response Kits',
      'Height Rescue Equipment'
    ]
  };

  // Equipment selection tracking
  final Map<String, List<String>> selectedEquipment = {
    'Basic Equipment': [],
    'Vehicles': [],
    'Specialized Equipment': []
  };

  Future pickImageFromGallery() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      selectedImage = File(returnedImage.path);
      Navigator.pop(context);
    });
  }

  Future pickImageFromCamera() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      selectedImage = File(returnedImage.path);
      Navigator.pop(context);
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
          children: serviceOptions.map((service) {
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
        ...requiredEquipment.entries.map((entry) {
          return ExpansionTile(
            title: Text(
              entry.key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children: entry.value.map((equipment) {
                  return FilterChip(
                    label: Text(equipment),
                    selected: selectedEquipment[entry.key]!.contains(equipment),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedEquipment[entry.key]!.add(equipment);
                        } else {
                          selectedEquipment[entry.key]!.remove(equipment);
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
          );
        }),
      ],
    );
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

    if (_selectedType == null) {
      Fluttertoast.showToast(
        msg: "Please select a facility type",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_selectedAvailability == null) {
      Fluttertoast.showToast(
        msg: "Please select availability",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (selectedServices.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select at least one service",
        backgroundColor: Colors.red,
      );
      return;
    }

    bool hasAnyEquipment = false;
    for (var category in selectedEquipment.keys) {
      if (selectedEquipment[category]!.isNotEmpty) {
        hasAnyEquipment = true;
        break;
      }
    }

    if (!hasAnyEquipment) {
      Fluttertoast.showToast(
        msg: "Please select at least one equipment item",
        backgroundColor: Colors.red,
      );
      return;
    }

    // Check for image upload
    if (selectedImage == null) {
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

    if (_certificateFile == null) {
      Fluttertoast.showToast(
        msg: "Please upload your certificate PDF",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload image to Firebase Storage
      String imageUrl = await uploadImageToFirebase(selectedImage!);

      //Upload PDF to Firebase Storage
      String pdfUrl = await uploadPDFToFirebase(_certificateFile!);

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
      if (_selectedAvailability == "Day Shift Only" || _selectedAvailability == "Night Shift Only" || _selectedAvailability == "On-Call") {
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
      } else if (_selectedAvailability == "24/7") {
        availabilityTime = "24 hours (All days)";
        durationHours = 24;
        durationMinutes = 0;
      }

      // Prepare data for Firestore
      Map<String, dynamic> fireAndSafetyInfoMap = {
        'userId': widget.userId,
        'id': id,
        'name': _nameController.text.trim(),
        'Servicename': _ServicenameController.text.trim(),
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'facilityType': _selectedType,
        'email': _emailController.text.trim(),
        'address': _addressController.text,
        'Location': widget.location,
        'contact': _phoneController.text.trim(),
        'profileImage': imageUrl,
        'experience': int.parse(_experienceController.text),
        'certificatePDF': pdfUrl,
        'description': _descriptionController.text,
        'services': selectedServices,
        'equipment': {
          'Basic Equipment': selectedEquipment['Basic Equipment'],
          'Vehicles': selectedEquipment['Vehicles'],
          'Specialized Equipment': selectedEquipment['Specialized Equipment'],
        },
        'availability': {
          'type': _selectedAvailability,
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
      await DatabaseMethods().setfireAndsafetyDetails(fireAndSafetyInfoMap, id);

      // Show success message
      Fluttertoast.showToast(
        msg: "Fire and Safety details saved successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Clear form fields
      _ServicenameController.clear();
      _ageController.clear();
      _phoneController.clear();
      _emailController.clear();
      _descriptionController.clear();
      _experienceController.clear();
      _addressController.clear();
      
      setState(() {
        selectedImage = null;
        _certificateFile = null;
        certificateFileName = null;
        _selectedType = null;
        _selectedAvailability = null;
        fromTime = null;
        toTime = null;
        selectedServices = [];
        
        // Clear equipment selections
        for (var key in selectedEquipment.keys) {
          selectedEquipment[key] = [];
        }
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>FireAndSafetyPage(userId: widget.userId, location: widget.location)));

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.orange,
        title: Text(
          "Add Fire & Safety Details",
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
                                },
                                child: const Text("Upload From Camera"),
                              ),
                              TextButton(
                                onPressed: () {
                                  pickImageFromGallery();
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
                // Facility Type Dropdown
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
                      items: facilityTypes
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
                // Manager/Contact Person Details
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
                // Location/Address Field
                Text("Location",
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
                // Email Field
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
               // In the build method, after the Years of Experience field, add:

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

// Add Availability section
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
      items: availabilityOptions
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

// Add Services section
_buildServiceCheckboxes(),
const SizedBox(height: 20),

// Add Equipment section
_buildEquipmentSection(),
const SizedBox(height: 20),

// Add Description field
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

// Add Certificate Upload section
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

// Add Submit button
Center(
  child: isLoading
      ? const CircularProgressIndicator()
      : ElevatedButton(
          onPressed: saveDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.isDarkMode ? Colors.deepOrange : Colors.orange,
            padding: const EdgeInsets.symmetric(
              horizontal: 50,
              vertical: 15,
            ),
          ),
          child: Text(
            "Save Details",
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

  @override
  void dispose() {
    _ServicenameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}