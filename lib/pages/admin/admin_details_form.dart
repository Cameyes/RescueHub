import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/address_selector.dart';
import 'package:food_delivery_app/pages/admin/admin_verification.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminDetailsForm extends StatefulWidget {
  final String userId;
  final String userEmail;
  const AdminDetailsForm({super.key, required this.userId, required this.userEmail});

  @override
  State<AdminDetailsForm> createState() => _AdminDetailsFormState();
}

class _AdminDetailsFormState extends State<AdminDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  File? selectedImage_one;
  String? _selectedLocation;
  String? _govtIdPath;
  bool _isLoading = false;
  String? _govtIdFileName;
  String selectedGender = "Male";

  final List<String> locations = ['Thrissur', 'Palakkad', 'Eranakulam'];

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

  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child("images/$fileName.jpg");
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  LatLng? _parseCoordinates(String address) {
    try {
      final parts = address.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
      return null;
    } catch (e) {
      print('Error parsing coordinates: $e');
      return null;
    }
  }

  Future<void> _pickGovtId() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _govtIdPath = result.files.single.path;
          _govtIdFileName = result.files.single.name;
        });
        // Show warning dialog
        _showGovtIdWarning();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (!_isAtLeast21YearsOld(picked)) {
        // Show warning dialog
        _showAgeWarning();
        return;
      }
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  bool _isAtLeast21YearsOld(DateTime dob) {
    DateTime now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 21;
  }

  void _showGovtIdWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Warning"),
          content: const Text("Please ensure you upload a clear format of your Government ID that contains your Name and Date of Birth."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAgeWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Age Requirement"),
          content: const Text("You must be at least 21 years old to be a coordinator."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _dobController.text = '';
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    final coordinates = _parseCoordinates(addressController.text);

    if (!_formKey.currentState!.validate() || 
        _selectedLocation == null || 
        _govtIdPath == null ||
        selectedImage_one == null ||
        coordinates == null
    ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and provide required documents')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String profileImageUrl = await uploadImageToFirebase(selectedImage_one!);
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('admin_ids/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      
      await storageRef.putFile(File(_govtIdPath!));
      final govtIdUrl = await storageRef.getDownloadURL();

      // Save initial details
      await FirebaseFirestore.instance.collection('adminDetails').doc(widget.userId).set({
        'name': _nameController.text,
        'dob': _dobController.text,
        'gender': selectedGender,
        'phone': _phoneController.text,
        'location': _selectedLocation,
        'address': addressController.text,
        'coordinates': GeoPoint(coordinates.latitude, coordinates.longitude),
        'profileImageUrl': profileImageUrl,
        'govtIdUrl': govtIdUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'verificationStatus': 'pending',
      });

      if (!mounted) return;

      // Navigate to verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminVerificationScreen(
            userId: widget.userId,
            enteredName: _nameController.text,
            govtIdUrl: govtIdUrl,
            userEmail: widget.userEmail, enteredDob: '', 
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(child: Text('Coordinator Details', style: TextStyle(color: Colors.white))),
        backgroundColor: isDark ? Colors.grey[850] : Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '⚠️ Important: Location can only be selected once and cannot be changed later.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name (As per Govt ID)',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (DD/MM/YYYY)',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Gender",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                      ),
                      Row(
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
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Enter your address',
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
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
              const SizedBox(height: 16),
              Text(
                "Upload Photo (Most Recent)",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                )
              ),
              const SizedBox(height: 16),
              // Center the photo upload container
              Center(
                child: GestureDetector(
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 160, // Fixed width
                        height: 160, // Same height as width for perfect square
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: selectedImage_one != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage_one!,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover, // Use cover to ensure proper filling
                                ),
                              )
                            : const Center(child: Text("Please Select an Image")),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(
                  labelText: 'Select Location',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                items: locations.map((String location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickGovtId,
                icon: const Icon(Icons.upload_file),
                label: Text(_govtIdFileName ?? 'Upload Government ID (PDF)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}