// ignore_for_file: prefer_const_constructors

import 'dart:io';
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

class AddclothDetails extends StatefulWidget {
  final String userId;
  final String Loc;
  const AddclothDetails({super.key,
  required this.Loc,required this.userId});

  @override
  State<AddclothDetails> createState() => _AddclothDetailsState();
}

class _AddclothDetailsState extends State<AddclothDetails> {
  String selectedsize = "XS";//Controller for drop down menu
  String selectedType="Male";//Controller for Radio Button
  File? selectedImage_one; //Controller For First Image
  File? selectedImage_two; // Controller for Second Image
  bool isloading=false;//for showing CircularProgressIndicator

  TextEditingController nameController=TextEditingController(); // Controller for Name field
  TextEditingController housenameController=TextEditingController(); // Controller for HouseName field
  TextEditingController addressController=TextEditingController(); // Controller for address field
  TextEditingController sizeController=TextEditingController(); // Controller for size field
  TextEditingController contactController=TextEditingController(); // Controller for contact field
  TextEditingController descriptionController=TextEditingController(); // Controller for Description field
  TextEditingController clothController=TextEditingController(); // Controller for FoodName field!

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

  Future<void> saveDetails() async {
    setState(() {
      isloading = true; // Start loading
    });
    try {
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      if (selectedImage_one != null) {
        String imageUrlOne = await uploadImageToFirebase(selectedImage_one!);
        imageUrls.add(imageUrlOne);
      }
      if (selectedImage_two != null) {
        String imageUrlTwo = await uploadImageToFirebase(selectedImage_two!);
        imageUrls.add(imageUrlTwo);
      }

      // Generate unique ID for the entry
      String Id = randomAlphaNumeric(10);

      // Get current date and time
      DateTime now = DateTime.now();
      String formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      String formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      // Prepare data for Firestore
      Map<String, dynamic> clothInfoMap = {
                          'UserId':widget.userId,
                          'Id':Id,
                        'ClothName':clothController.text,
                        'Name':nameController.text,
                        'HouseName':housenameController.text,
                        'Address':addressController.text,
                        "Location":widget.Loc,
                        'Count':int.parse(sizeController.text),
                        'Size':selectedsize,
                        'Gender':selectedType,
                        'Contact':contactController.text,
                        'Images':imageUrls,
                        'Description':descriptionController.text,
                        'Date':formattedDate, //Add date
                        'Time':formattedTime, //Add time
      };

      // Save data to Firestore
      await DatabaseMethods().addclothDetails(clothInfoMap,Id);

      // Show success message
      Fluttertoast.showToast(
        msg: "cloth details updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Clear form fields
      nameController.clear();
     // ageController.clear();
      housenameController.clear();
      addressController.clear();
      sizeController.clear();
      contactController.clear();
      descriptionController.clear();

      // Navigate to MapPage
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
    }
    finally{
      setState(() {
        isloading=false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Access ThemeProvider
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Center(
          child: Text(
            "Add Cloth Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: themeProvider.isDarkMode ? const Color.fromARGB(255, 115, 105, 105) : Colors.orange,
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
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),),
              const SizedBox(height: 10,),
              TextField(
                controller: housenameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'House Name',
                ),
              ),
              const SizedBox(height: 10,),
              Text(
                "Address",
                style: TextStyle(
                  color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
               Row(
                 children: [
                   Row(
                     children: [
                       SizedBox(
                        width: 300,
                         child: TextField(
                          controller: addressController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your address',
                          ),
                          ),
                       ),
                       const SizedBox(width: 15,),
                        GestureDetector(
                       child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                            color: themeProvider.isDarkMode?Colors.grey[600]:Colors.orange,
                            borderRadius: BorderRadius.circular(20)
                        ),
                        child: Center(
                          child: Icon(
                            Icons.map,
                            color: Colors.white,
                          ),
                        ),
                       ),
                       onTap: () async{
                          //function to open map and select location
                          //here we navigate to address_selector.dart page 
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
                     )
                     ],
                   ),
                 ],
               ),
              const SizedBox(height: 20),
              Text(
                "Number of Affordable Occupants",
                style: TextStyle(
                  color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                      decoration: InputDecoration(
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
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                      style: TextStyle(color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900]),
                    ),
                  );
                }).toList(),
              ),        
                ],
              ),
              const SizedBox(height: 10),
              Text("Type",
              style: TextStyle(
                  color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                  color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                        color: themeProvider.isDarkMode ? Colors.grey[900] :Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius:BorderRadius.circular(10)
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          const SizedBox(width: 5,),
                          const Icon(Icons.call),
                          Text("+91",
                          style: TextStyle(
                            color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                      decoration: InputDecoration(
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
                  color:themeProvider.isDarkMode?Colors.white:Colors.grey[900],
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
                                    fit: BoxFit.cover,
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
                                    fit: BoxFit.cover,
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
                color:themeProvider.isDarkMode?Colors.white:Colors.grey[900],
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 10,),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
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
                    onPressed: () async{
                      //Call Save Details function
                      saveDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isDarkMode ? Colors.deepOrange : Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "Save Details",
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
              child: Center(
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