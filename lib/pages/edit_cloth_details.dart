import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditClothDetails extends StatefulWidget {
  final DocumentSnapshot clothData;
  final String userId;
  const EditClothDetails({super.key,required this.clothData,required this.userId});

  @override
  State<EditClothDetails> createState() => _EditClothDetailsState();
}

class _EditClothDetailsState extends State<EditClothDetails> {

  String selectedsize = "XS";//Controller for drop down menu
  String selectedType="Male";//Controller for Radio Button
  File? selectedImage_one; //Controller For First Image
  File? selectedImage_two; // Controller for Second Image
  bool isloading=false;//for showing CircularProgressIndicator
  List<String> existingImageUrls=[];

  late TextEditingController nameController;
  late TextEditingController housenameController;
  late TextEditingController addressController;
  late TextEditingController sizeController;
  late TextEditingController contactController;
  late TextEditingController descriptionController;
  late TextEditingController clothController;

  @override
  void initState(){
    super.initState();
    nameController = TextEditingController(text: widget.clothData["Name"]);
    housenameController = TextEditingController(text: widget.clothData["HouseName"]);
    addressController = TextEditingController(text: widget.clothData["Address"]);
    sizeController = TextEditingController(text: widget.clothData["Count"].toString());
    contactController = TextEditingController(text: widget.clothData["Contact"]);
    descriptionController = TextEditingController(text: widget.clothData["Description"]);
    clothController = TextEditingController(text: widget.clothData["ClothName"]);
    selectedType=widget.clothData["Gender"];
    selectedsize=widget.clothData["Size"];
    if (widget.clothData["Images"] != null) {
        existingImageUrls = List<String>.from(widget.clothData["Images"]);
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

  Future<void> updateDetails() async{
    setState(() {
      isloading=true;
    });
    try{
      List<String> updatedImageUrls=[...existingImageUrls];

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

      Map<String,dynamic> updateInfo= {
        'ClothName':clothController.text,
        'Name':nameController.text,
        'HouseName':housenameController.text, 
        'Address':addressController.text,
        'Size':selectedsize,
        'Gender':selectedType,
        'Contact':contactController.text,
        'Description':descriptionController.text,
        'Images': updatedImageUrls,
        'Count':int.parse(sizeController.text)
      };

      await FirebaseFirestore.instance
          .collection("cloth")
          .doc(widget.clothData.id)
          .update(updateInfo);

      Fluttertoast.showToast(
        msg: "Details updated successfully!",
        backgroundColor: Colors.green,
      );

      Navigator.pop(context);
    }
    catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating details: $e",
        backgroundColor: Colors.red,
      );
    } 
    finally {
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
        title: const Center(
          child: Text(
            "Edit Cloth Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                "Cloth Name",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),const SizedBox(height: 10),
              TextField(
                controller: clothController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter cloth name',
                ),
              ),
              const SizedBox(height: 10,),
              Text(
                "Name",
                style: TextStyle(
                  color: themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your name',
                ),
              ),
              const SizedBox(height: 20),
              Text("House Name",
              style: TextStyle(
                color: themeProvider.isDarkMode?Colors.white: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),),
              const SizedBox(height: 10,),
              TextField(
                controller: housenameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'House Name',
                ),
              ),
              const SizedBox(height: 10,),
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
                "Number of Affordable Occupants",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Number'
                      ),
                    ),
                  ),
                  const SizedBox(width: 120,),
                  //Radio Button For Choosing between Veg and Non-Veg
                  Text(
                "Size  ",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedsize,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedsize = newValue!;
                  });
                },
                items: <String>[
                  'XS',
                  'S',
                  'M',
                  'L',
                  'XL',
                  'XXL',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: themeProvider.isDarkMode?Colors.white: Colors.black,)
                    ),
                  );
                }).toList(),
              ),        
                ],
              ),
              const SizedBox(height: 10),
              Text("Type",
              style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10,),
              Row(
                children: [
                   Row(
                          children: [
                            Radio<String>(
                            value: "Male",
                            groupValue: selectedType,
                            onChanged: (String? value) {
                            setState(() {
                            selectedType = value!;
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
                            groupValue: selectedType,
                            onChanged: (String? value) {
                            setState(() {
                            selectedType = value!;
                                });
                                  },
                                      ),
                                      const Text("Female"),
                                    ],
                                  ),
                                   Row(
                          children: [
                            Radio<String>(
                            value: "UniSex",
                            groupValue: selectedType,
                            onChanged: (String? value) {
                            setState(() {
                            selectedType = value!;
                                });
                                  },
                                      ),
                                      const Text("UniSex"),
                                    ],
                                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Text(
                "Contact",
                style: TextStyle(
                  color: themeProvider.isDarkMode?Colors.white: Colors.black,
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
                        borderRadius:BorderRadius.circular(10)
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          const SizedBox(width: 5,),
                          const Icon(Icons.call),
                          Text("+91",
                          style: TextStyle(
                            color: themeProvider.isDarkMode?Colors.white: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  SizedBox(
                    width: 240,
                    child:  TextField(
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
                            border: Border.all(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
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
                                  : existingImageUrls.isNotEmpty
                                    ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                    existingImageUrls[0],
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
                    const SizedBox(width: 30),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: themeProvider.isDarkMode?Colors.white: Colors.black,),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          width: 160,
                          height: 160,
                          child: selectedImage_two != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedImage_two!,
                                    fit: BoxFit.fill,
                                  ))
                                  : existingImageUrls.length > 1
                                      ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                      existingImageUrls[1],
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
              Text("Description", 
              style: TextStyle(
                color:themeProvider.isDarkMode?Colors.white: Colors.black,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 10,),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Description"
                ),
              ),
              const SizedBox(height: 20,),
              //Save Details Button
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
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
              ),
              if (isloading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blue,),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}