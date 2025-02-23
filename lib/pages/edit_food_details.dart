import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

class EditFoodDetails extends StatefulWidget {
  final DocumentSnapshot foodData;
  final String userId;
  const EditFoodDetails({super.key,required this.foodData,required this.userId});

  @override
  State<EditFoodDetails> createState() => _EditFoodDetailsState();
}

class _EditFoodDetailsState extends State<EditFoodDetails> {

  String selectedFood="Veg";//Controller for Radio Button
  File? selectedImage_one; //Controller For First Image
  File? selectedImage_two; // Controller for Second Image
  DateTime? expiryDate; //controller for Selected expiry Date
  bool isloading=false;//Controller for CircularProgressIndicator
  List<String> existingImageUrls=[];

  late TextEditingController nameController;
  late TextEditingController housenameController;
  late TextEditingController addressController;
  late TextEditingController sizeController;
  late TextEditingController contactController;
  late TextEditingController descriptionController;
  late TextEditingController foodController;

  @override
  void initState(){
    super.initState();
    nameController=TextEditingController(text: widget.foodData["Name"]);
    housenameController=TextEditingController(text: widget.foodData["HouseName"]);
    addressController=TextEditingController(text: widget.foodData["Address"]);
    sizeController=TextEditingController(text: widget.foodData["Size"].toString());
    contactController=TextEditingController(text: widget.foodData["Contact"]);
    descriptionController=TextEditingController(text: widget.foodData["Description"]);
    foodController=TextEditingController(text: widget.foodData["FoodName"]);
    selectedFood=widget.foodData["Type"];
    expiryDate=widget.foodData["Expirty-Date"]?.toDate();
     if (widget.foodData["Images"] != null) {
        existingImageUrls = List<String>.from(widget.foodData["Images"]);
    }
  }

  Future<void> pickExpiryDate(BuildContext context) async{
    final DateTime? picked=await showDatePicker(
      context: context, firstDate: DateTime.now(), 
      lastDate: DateTime(2026));
      if(picked !=null && picked !=expiryDate){
        setState(() {
          expiryDate = picked;
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
        'FoodName':foodController.text,
        'Name':nameController.text,
        'HouseName':housenameController.text, 
        'Address':addressController.text,
        'Size':int.parse(sizeController.text),
        'Type':selectedFood,
        'Expiry-Date':expiryDate,
        'Contact':contactController.text,
        'Description':descriptionController.text,
        'Images': updatedImageUrls,
      };

      await FirebaseFirestore.instance
          .collection("food")
          .doc(widget.foodData.id)
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
        title: const Text(
          "Edit Food Details",
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
                "Food Name",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),const SizedBox(height: 10),
              TextField(
                controller: foodController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter food name',
                ),
              ),
              const SizedBox(height: 10,),
              Text(
                "Name",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
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
                "Size of Affordable Occupants",
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
                        hintText: 'Size'
                      ),
                    ),
                  ),
                  const SizedBox(width: 120,),
                  //Radio Button For Choosing between Veg and Non-Veg
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          children: [
                            Radio<String>(
                            value: "Veg",
                            groupValue: selectedFood,
                            onChanged: (String? value) {
                            setState(() {
                            selectedFood = value!;
                                });
                                  },
                                      ),
                                      const Text("Veg"),
                                    ],
                                  ),
                                  Row(
                          children: [
                            Radio<String>(
                            value: "Non-Veg",
                            groupValue: selectedFood,
                            onChanged: (String? value) {
                            setState(() {
                            selectedFood = value!;
                                });
                                  },
                                      ),
                                      const Text("Non-Veg"),
                                    ],
                                  ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("Choose Date of Expiry",
              style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10,),
              Row(
                children: [
                  ElevatedButton(onPressed: ()=>pickExpiryDate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.isDarkMode?Colors.grey.shade600:Colors.blue,
                  ), 
                  child: Text("Pick a Date",
                  style: TextStyle(
                  color: themeProvider.isDarkMode?Colors.white: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),),
                  ),
                  const SizedBox(width: 10,),
                  Text(
                    expiryDate == null?
                    "No Date Chosen"
                    : "${expiryDate!.day}-${expiryDate!.month}-${expiryDate!.year}",
                    style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                  )
                ],
              ),
              const SizedBox(height: 10,),
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
                        borderRadius:BorderRadius.circular(10)
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          const SizedBox(width: 5,),
                          const Icon(Icons.call),
                          Text("+91",
                          style: TextStyle(
                            color:themeProvider.isDarkMode?Colors.white: Colors.black,
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
                  color: themeProvider.isDarkMode?Colors.white: Colors.black,
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
                            border: Border.all(color: Colors.black),
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
                color: themeProvider.isDarkMode?Colors.white: Colors.black,
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