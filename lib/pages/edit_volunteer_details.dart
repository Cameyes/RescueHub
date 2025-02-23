import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';

class EditVolunteerDetails extends StatefulWidget {
  final String userId;
  final String volunteerId;
  final Map<String, dynamic> volunteerData;
  final String location;

  const EditVolunteerDetails({
    super.key,
    required this.userId,
    required this.volunteerId,
    required this.volunteerData,
    required this.location,
  });

  @override
  State<EditVolunteerDetails> createState() => _EditVolunteerDetailsState();
}

class _EditVolunteerDetailsState extends State<EditVolunteerDetails> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController contactController;
  late TextEditingController emailController;
  late TextEditingController skillsController;
  late TextEditingController descriptionController;
  late String selectedGender;
  late List<String> skills;
  late String selectedAvailability;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  bool isLoading = false;
  String? currentImageUrl;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    nameController = TextEditingController(text: widget.volunteerData['name']);
    ageController = TextEditingController(text: widget.volunteerData['age'].toString());
    contactController = TextEditingController(text: widget.volunteerData['contact']);
    emailController = TextEditingController(text: widget.volunteerData['email']);
    skillsController = TextEditingController();
     descriptionController = TextEditingController(text: widget.volunteerData['description']);
    // Initialize other fields
    selectedGender = widget.volunteerData['gender'];
    skills = List<String>.from(widget.volunteerData['skills']);
    currentImageUrl = widget.volunteerData['profileImage'];
    
    // Initialize availability data
    selectedAvailability = widget.volunteerData['availability']['type'];
    if (selectedAvailability != "Full Time") {
      String? fromTimeStr = widget.volunteerData['availability']['fromTime'];
      String? toTimeStr = widget.volunteerData['availability']['toTime'];
      if (fromTimeStr != null && toTimeStr != null) {
        fromTime = _parseTimeString(fromTimeStr);
        toTime = _parseTimeString(toTimeStr);
      }
    }
    
    skillsController.addListener(_onSkillsChanged);
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1].split(' ')[0]);
      if (hours != null && minutes != null) {
        return TimeOfDay(hour: hours, minute: minutes);
      }
    }
    return TimeOfDay.now();
  }

  void _onSkillsChanged() {
    String text = skillsController.text;
    if (text.endsWith(',')) {
      String newSkill = text.substring(0, text.length - 1).trim();
      if (newSkill.isNotEmpty && !skills.contains(newSkill)) {
        setState(() {
          skills.add(newSkill);
          skillsController.clear();
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFromTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isFromTime ? fromTime ?? TimeOfDay.now() : toTime ?? TimeOfDay.now(),
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

  Future<void> _pickImage(ImageSource source) async {
    final returnedImage = await ImagePicker().pickImage(source: source);
    if (returnedImage != null) {
      setState(() {
        selectedImage = File(returnedImage.path);
      });
      Navigator.pop(context);
    }
  }

  Future<void> updateVolunteerDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'age': int.parse(ageController.text),
        'gender': selectedGender,
        'contact': contactController.text.trim(),
        'email': emailController.text.trim(),
        'skills': skills,
        'description': descriptionController.text.trim(),
        'availability': {
          'type': selectedAvailability,
          'fromTime': fromTime?.format(context),
          'toTime': toTime?.format(context),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Upload new image if selected
      if (selectedImage != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child("images/$fileName.jpg");
        await storageRef.putFile(selectedImage!);
        String imageUrl = await storageRef.getDownloadURL();
        updateData['profileImage'] = imageUrl;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('volunteer')
          .doc(widget.volunteerId)
          .update(updateData);

      Fluttertoast.showToast(
        msg: "Details updated successfully!",
        backgroundColor: Colors.green,
      );

      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating details: $e",
        backgroundColor: Colors.red,
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
        title: const Text("Edit Volunteer Details"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image selection
              Center(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Choose Image Source"),
                        actions: [
                          TextButton(
                            onPressed: () => _pickImage(ImageSource.camera),
                            child: const Text("Camera"),
                          ),
                          TextButton(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            child: const Text("Gallery"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : currentImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(currentImageUrl!, fit: BoxFit.cover),
                              )
                            : const Center(child: Icon(Icons.add_a_photo, size: 50)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Name field
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? "Name is required" : null,
              ),
              const SizedBox(height: 16),
              
              // Age and Gender
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ageController,
                      decoration: const InputDecoration(
                        labelText: "Age",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? "Age is required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(
                        labelText: "Gender",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Male", "Female"]
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedGender = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Contact and Email fields
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: "Contact",
                  border: OutlineInputBorder(),
                  prefixText: "+91 ",
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? "Contact is required" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value?.isEmpty ?? true ? "Email is required" : null,
              ),
              const SizedBox(height: 16),
              
              // Skills
              TextFormField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: "Add Skills (separate with comma)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: skills.map((skill) => Chip(
                  label: Text(skill),
                  onDeleted: () {
                    setState(() => skills.remove(skill));
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              
              // Availability
              DropdownButtonFormField<String>(
                value: selectedAvailability,
                decoration: const InputDecoration(
                  labelText: "Availability",
                  border: OutlineInputBorder(),
                ),
                items: ["Full Time", "Part Time", "Specific Hours"]
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedAvailability = value;
                      if (value == "Full Time") {
                        fromTime = null;
                        toTime = null;
                      }
                    });
                  }
                },
              ),
              if (selectedAvailability != "Full Time") ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(fromTime?.format(context) ?? "Select Start Time"),
                        onPressed: () => _selectTime(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(toTime?.format(context) ?? "Select End Time"),
                        onPressed: () => _selectTime(context, false),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 60, horizontal: 12),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value?.isEmpty ?? true ? "Description is required" : null,
                ),
              const SizedBox(height: 24),
               // Update button
              if (!isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isDarkMode ? Colors.deepOrange : Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: updateVolunteerDetails,
                    child: Text(
                      "Update Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    contactController.dispose();
    emailController.dispose();
    skillsController.dispose();
    super.dispose();
  }
}