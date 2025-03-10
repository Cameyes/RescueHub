// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/pages/address_selector.dart';
import 'package:food_delivery_app/pages/map_page.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import for Firebase Storage
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddDetails extends StatefulWidget {
  final String userId;
  final String Loc;
  const AddDetails({super.key, required this.Loc,required this.userId});

  @override
  State<AddDetails> createState() => _AddDetailsState();
}

class _AddDetailsState extends State<AddDetails> {
  String selectedpref = "Females Only"; // Controller for dropdown menu
  String selectedGender = "Male"; // Controller for Radio Button
  File? selectedImage_one; // Controller for First Image
  File? selectedImage_two; // Controller for Second Image
  bool isloading = false; //Controller for CircularProgressIndicator

  double? distance;
String? distanceText;
String? durationText;



  TextEditingController nameController = TextEditingController(); // Controller for Name field
  TextEditingController ageController = TextEditingController(); // Controller for age field
  TextEditingController housenameController = TextEditingController(); // Controller for HouseName field
  TextEditingController addressController = TextEditingController(); // Controller for address field
  TextEditingController sizeController = TextEditingController(); // Controller for size field
  TextEditingController contactController = TextEditingController(); // Controller for contact field
  TextEditingController descriptionController = TextEditingController(); // Controller for Description field

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

    if (distance == null) {
  Fluttertoast.showToast(
    msg: "Please select a location to calculate distance",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    backgroundColor: Colors.red,
    textColor: Colors.white,
  );
  return;
}
    //Validate whether all fields are filled or not
    if (!_formKey.currentState!.validate()) {
    // If any field is invalid, stop here.
    Fluttertoast.showToast(
      msg: "Please fill in all required fields",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }

  //Checking whether both images have been Uploaded or not

  if (selectedImage_one == null || selectedImage_two == null) {
    Fluttertoast.showToast(
      msg: "Please upload both images.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    return; // Stop execution if images are missing
  }

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
      String id = randomAlphaNumeric(10);

      // Get current date and time
      DateTime now = DateTime.now();
      String formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      String formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      // Prepare data for Firestore
      Map<String, dynamic> shelterInfoMap = {
        'UserId':widget.userId,
        'Id': id,
        'Name': nameController.text,
        'Age': int.parse(ageController.text),
        'Gender': selectedGender,
        'HouseName': housenameController.text,
        'Address': addressController.text,
        "Location": widget.Loc,
        'Size': int.parse(sizeController.text),
        'Preference': selectedpref,
        'Contact': contactController.text,
        'Images': imageUrls, // Store Firebase Storage URLs
        'Description': descriptionController.text,
        'Date': formattedDate, // Add date
        'Time': formattedTime, // Add time
        'distance': distance,  // Add distance
        'distanceText': distanceText,  // Add distance text
        'status': "not booked",  // Add initial status
        
      };

      // Save data to Firestore
      await DatabaseMethods().addshelterDetails(shelterInfoMap, id);

      // Show success message
      Fluttertoast.showToast(
        msg: "Shelter details updated successfully!",
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
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white, // Background color
      appBar: AppBar(
        title: Center(
          child: Text(
            "Add Details",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : const Color.fromARGB(255, 255, 255, 255),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor:themeProvider.isDarkMode ? const Color.fromARGB(255, 87, 84, 84) : Colors.orange,
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
                    color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),const SizedBox(height: 10),
                TextFormField (
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
              decoration: InputDecoration(
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
          ],
        ),
        
                const SizedBox(height: 20),
                Text("House Name",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),),
                const SizedBox(height: 10,),
                TextFormField(
                  controller: housenameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'House Name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is mandatory';
                    }
                    return null;
                  },
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
                     SizedBox(
                      width: 300,
                       child: TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
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
                              try {
      String apiKey = 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc';
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${widget.Loc}'  // Assuming widget.Loc is in "lat,lng" format
          '&destination=${selectedLocation.latitude},${selectedLocation.longitude}'
          '&mode=driving'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          var route = data['routes'][0]['legs'][0];
          var distanceInMeters = route['distance']['value'];
          setState(() {
            distanceText = route['distance']['text'];
            durationText = route['duration']['text'];
            distance = distanceInMeters / 1000.0;
          });
        }
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
                            }
                       },
                     )
                   ],
                 ),
                 const SizedBox(height: 10),
                 if (distance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text(
                            "Distance: ",
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              distanceText ?? '${distance!.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 20),
                Text(
                  "Size of Affordable Occupants",
                  style: TextStyle(
                    color:themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: sizeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Size'
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
                const SizedBox(height: 10),
                Text(
                  "Preference",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                        style:  TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900]),
                      ),
                    );
                  }).toList(),
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
                  children: [
                    Container(
                      height: 55,
                      width: 80,
                      decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
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
                              color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                      child:  TextFormField(
                        controller: contactController,
                        decoration: InputDecoration(
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
                  "Upload Images",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
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
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 10,),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter Description"
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
                    onPressed: saveDetails,
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
        ),
      ),
    );
  }
}