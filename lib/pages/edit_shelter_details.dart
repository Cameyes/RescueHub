import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import '../components/theme_provider.dart';

class EditDetails extends StatefulWidget {
  final DocumentSnapshot shelterData;
  final String userId;
  const EditDetails({super.key, required this.shelterData, required this.userId});

  @override
  State<EditDetails> createState() => _EditDetailsState();
}

class _EditDetailsState extends State<EditDetails> {
  String selectedpref = "Females Only";
  String selectedGender = "Male";
  File? selectedImage_one;
  File? selectedImage_two;
  bool isloading = false;
  List<String> existingImageUrls = [];

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController housenameController;
  late TextEditingController addressController;
  late TextEditingController sizeController;
  late TextEditingController contactController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.shelterData["Name"]);
    ageController = TextEditingController(text: widget.shelterData["Age"].toString());
    housenameController = TextEditingController(text: widget.shelterData["HouseName"]);
    addressController = TextEditingController(text: widget.shelterData["Address"]);
    sizeController = TextEditingController(text: widget.shelterData["Size"].toString());
    contactController = TextEditingController(text: widget.shelterData["Contact"]);
    descriptionController = TextEditingController(text: widget.shelterData["Description"]);
    selectedpref = widget.shelterData["Preference"];
    selectedGender = widget.shelterData["Gender"];
    existingImageUrls = List<String>.from(widget.shelterData["Images"]);
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

  Future pickImagefromGallerytwo() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      selectedImage_two = File(returnedImage.path);
      Navigator.pop(context);
    });
  }

  Future pickImagefromCameratwo() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      selectedImage_two = File(returnedImage.path);
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

  Future<void> updateDetails() async {
    setState(() {
      isloading = true;
    });
    try {
      List<String> updatedImageUrls = [...existingImageUrls];
      
      // Upload new images if selected
      if (selectedImage_one != null) {
        String imageUrlOne = await uploadImageToFirebase(selectedImage_one!);
        if (updatedImageUrls.isNotEmpty) {
          updatedImageUrls[0] = imageUrlOne;
        } else {
          updatedImageUrls.add(imageUrlOne);
        }
      }
      if (selectedImage_two != null) {
        String imageUrlTwo = await uploadImageToFirebase(selectedImage_two!);
        if (updatedImageUrls.length > 1) {
          updatedImageUrls[1] = imageUrlTwo;
        } else {
          updatedImageUrls.add(imageUrlTwo);
        }
      }

      Map<String, dynamic> updateInfo = {
        'Name': nameController.text,
        'Age': int.parse(ageController.text),
        'Gender': selectedGender,
        'HouseName': housenameController.text,
        'Address': addressController.text,
        'Size': int.parse(sizeController.text),
        'Preference': selectedpref,
        'Contact': contactController.text,
        'Images': updatedImageUrls,
        'Description': descriptionController.text,
      };

      await FirebaseFirestore.instance
          .collection("shelter")
          .doc(widget.shelterData.id)
          .update(updateInfo);

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
        isloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
      final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Shelter Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor:themeProvider.isDarkMode?Colors.black: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                "Name",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your name',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Age",
                    style: TextStyle(
                      color: themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 180),
                  Text(
                    "Gender",
                    style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
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
                    child: TextField(
                      controller: ageController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'age',
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
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
              const SizedBox(height: 20),
              Text(
                "House Name",
                style: TextStyle(
                  color: themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: housenameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'House Name',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Address",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your address',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Size of Affordable Occupants",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Size',
                  ),
                ),
              ),
              const SizedBox(height: 10),
               Text(
                "Preference",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedpref,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedpref = newValue!;
                  });
                },
                items: <String>[
                  'Females Only',
                  'Males Only',
                  'Family',
                  'Females and \n Children Only'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                "Contact",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    height: 55,
                    width: 80,
                    decoration: BoxDecoration(
                      color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.white,
                      border: Border.all(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          const SizedBox(width: 5),
                          const Icon(Icons.call),
                          Text(
                            "+91",
                            style: TextStyle(
                              color:themeProvider.isDarkMode?Colors.white: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: contactController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your Number',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Upload Images",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          width: 160,
                          height: 160,
                          child: selectedImage_one != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedImage_one!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : existingImageUrls.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        existingImageUrls[0],
                                        fit: BoxFit.cover,
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
                    const SizedBox(width: 30),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color:themeProvider.isDarkMode?Colors.white: Colors.black,),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          width: 160,
                          height: 160,
                          child: selectedImage_two != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedImage_two!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : existingImageUrls.length > 1
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        existingImageUrls[1],
                                        fit: BoxFit.cover,
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
                                      pickImagefromCameratwo();
                                    },
                                    child: const Text("Upload From Camera"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      pickImagefromGallerytwo();
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Description",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Description",
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: updateDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:themeProvider.isDarkMode?Colors.grey.shade600: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "Update Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              if (isloading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
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
    housenameController.dispose();
    addressController.dispose();
    sizeController.dispose();
    contactController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}