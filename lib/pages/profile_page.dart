import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String? InitialName;
  final String? InitialEmail;
  const ProfilePage({
    required this.userId, 
    super.key,
    required this.InitialName,
    required this.InitialEmail,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return ProfileViewScreen(userId: widget.userId);
  }
}

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? initialName;
  final String? initialEmail;
  const ProfileViewScreen({
    required this.userId, 
    super.key,
     this.initialName,
    this.initialEmail,
    });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Profile')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      setState(() {
      userData = userDoc.data() as Map<String, dynamic>;
      // Use initial values if available and document field is empty
      if (userData?['Name'] == null || userData?['Name'].isEmpty) {
        userData?['Name'] = widget.initialName;
      }
      if (userData?['email'] == null || userData?['email'].isEmpty) {
        userData?['email'] = widget.initialEmail;
      }
      isLoading = false;
    });
    } else {
      setState(() {
      userData = {
        'Name': widget.initialName,
        'email': widget.initialEmail,
      };
      isLoading = false;
    });
    }
  }

  Widget _buildInfoRow(String label, String? value, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:  TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not set',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
           Divider(
            color: themeProvider.isDarkMode?Colors.white:Colors.black,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:themeProvider.isDarkMode?Colors.black: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black),
                ),
                child: (userData?['Image'] != null && userData!['Image'].toString().trim().isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          userData!['Image'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 80),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.blue, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name', userData?['Name'],context),
                  _buildInfoRow('Age', userData?['Age'],context),
                  _buildInfoRow('Gender', userData?['Gender'],context),
                  _buildInfoRow('House Name', userData?['HouseName'],context),
                  _buildInfoRow('Address', userData?['Address'],context),
                  _buildInfoRow('Contact', '+91 ${userData?['Contact']}',context),
                  _buildInfoRow('Email', userData?['email'],context,),
                  _buildInfoRow('Location', userData?['location'],context),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditScreen(userId: widget.userId),
                  ),
                ).then((_) {
                  // Refresh the profile data when returning from edit screen
                  setState(() {
                    isLoading = true;
                  });
                  _loadUserProfile();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.isDarkMode?Colors.grey.shade600: userData?.isEmpty??true?Colors.green :Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child:  Text(
                userData?.isEmpty??true?'Set Profile' :'Edit Profile',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ProfileEditScreen extends StatefulWidget {
  final String userId;
  const ProfileEditScreen({required this.userId, super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  File? selectedImage;
  String? ImageUrl;
  bool isloading = false;
  bool isDirty = false;
  String selectedGender = "Male";
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController housenameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _markDirty() {
    if (!isDirty) {
      setState(() {
        isDirty = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
            Fluttertoast.showToast(
                msg: "Location permission denied",
                backgroundColor: Colors.red,
            );
            return;
        }
    }
    
    if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
            msg: "Location permission permanently denied, please enable from settings",
            backgroundColor: Colors.red,
        );
        return;
    }

    try {
        setState(() {
            isloading = true;
        });

        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
        );

        setState(() {
            locationController.text = "${position.latitude}, ${position.longitude}";
            _markDirty();
        });

    } catch (e) {
        Fluttertoast.showToast(
            msg: "Error getting location: $e",
            backgroundColor: Colors.red,
        );
    } finally {
        setState(() {
            isloading = false;
        });
    }
}


  Future<void> _deleteProfile() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Profile"),
          content: const Text("Are you sure you want to delete your profile?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('Profile')
                    .doc(widget.userId)
                    .delete();
                
                if (ImageUrl != null && ImageUrl!.isNotEmpty) {
                  try {
                    await FirebaseStorage.instance
                        .refFromURL(ImageUrl!)
                        .delete();
                  } catch (e) {
                    print("Error deleting image: $e");
                  }
                }

                Fluttertoast.showToast(
                  msg: "Profile Deleted Successfully!",
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );

                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserProfile() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Profile')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        nameController.text = data['Name'] ?? '';
        ageController.text = data['Age'] ?? '';
        housenameController.text = data['HouseName'] ?? '';
        addressController.text = data['Address'] ?? '';
        contactController.text = data['Contact'] ?? '';
        emailController.text = data['email'] ?? '';
        locationController.text = data['location'] ?? '';
        selectedGender = data['Gender'] ?? 'Male';
        ImageUrl = data['Image'];
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isloading = true;
    });

    String imageUrl = ImageUrl ?? "";
    if (selectedImage != null) {
      imageUrl = await uploadImageToFirebase(selectedImage!);
    }

    Map<String, dynamic> profileInfoMap = {
      'Image': imageUrl,
      'Name': nameController.text,
      'Age': ageController.text,
      'Gender': selectedGender,
      'HouseName': housenameController.text,
      'Address': addressController.text,
      'Contact': contactController.text,
      'email': emailController.text,
      'location': locationController.text,
    };

    await FirebaseFirestore.instance
        .collection('Profile')
        .doc(widget.userId)
        .set(profileInfoMap, SetOptions(merge: true));

    Fluttertoast.showToast(
      msg: isDirty ? "Profile Updated Successfully!" : "Profile Details Saved Successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    setState(() {
      isloading = false;
      isDirty = false;
    });
    if(mounted){
    Navigator.pop(context); // Return to view screen after saving
    }
  }

  Future pickImagefromGallery() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      selectedImage = File(returnedImage.path);
      _markDirty();
      Navigator.pop(context);
    });
  }

  Future pickImagefromCamera() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      selectedImage = File(returnedImage.path);
      _markDirty();
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    InputDecoration? decoration,
  }) {
    return TextField(
      controller: controller,
      decoration: (decoration ?? InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hintText,
      )),
      onTap: _markDirty,
      onChanged: (_) => _markDirty(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: Colors.white,
      appBar: AppBar(
        title:  Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:themeProvider.isDarkMode?Colors.black: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            Center(
              child: GestureDetector(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color:themeProvider.isDarkMode?Colors.white: Colors.black),
                  ),
                  child: selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                          ))
                      : (ImageUrl != null && ImageUrl!.trim().isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                ImageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 80),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.blue, size: 50),
                ),
                onTap: () {
                  _markDirty();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Choose an Option"),
                        actions: [
                          TextButton(
                            onPressed: pickImagefromCamera,
                            child: const Text("Upload From Camera"),
                          ),
                          TextButton(
                            onPressed: pickImagefromGallery,
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
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              child: Text(
                "Name",
                style: TextStyle(
                  color: themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              child: _buildTextField(
                controller: nameController,
                hintText: "Enter your Name",
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              child: Row(
                children: [
                  Text(
                    "Age",
                    style: TextStyle(
                      color:themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 120),
                  Text(
                    "Gender",
                    style: TextStyle(
                      color: themeProvider.isDarkMode?Colors.white: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 100,
                    child: _buildTextField(
                      controller: ageController,
                      hintText: "Enter your Age",
                    ),
                  ),
                ),
                const SizedBox(width: 40),
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
                              _markDirty();
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
                              _markDirty();
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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "HouseName",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              child: _buildTextField(
                controller: housenameController,
                hintText: "Enter your House Name",
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Address",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              child: _buildTextField(
                controller: addressController,
                hintText: "Enter your Address",
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Contact",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    height: 55,
                    width: 80,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode?Colors.grey.shade700: Colors.white,
                      border: Border.all(color:  Colors.black,),
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
                              color: themeProvider.isDarkMode?Colors.white: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 240,
                  child: _buildTextField(
                    controller: contactController,
                    hintText: 'Enter your Number',
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Email",
                style: TextStyle(
                  color: themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0),
              child: TextField(
                controller: emailController,
                enabled: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Email",
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Location",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 300,
                    child: TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Your Location",
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _getCurrentLocation,
                          child:  Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color:themeProvider.isDarkMode?Colors.grey.shade700: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child:  Icon(Icons.location_on, color:themeProvider.isDarkMode?Colors.black: Colors.white, size: 30),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -45,
                      left: -15,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(90, 40),
                            painter: LocationDialogPainter(),
                          ),
                          const Positioned(
                            top: 5,
                            child: Text(
                              "Locate me",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: isloading
                  ? const CircularProgressIndicator(color: Colors.blue)
                  : GestureDetector(
                      onTap: _saveProfile,
                      child: Container(
                        width: 120,
                        height: 50,
                        decoration: BoxDecoration(
                          color:themeProvider.isDarkMode?Colors.grey.shade600: isDirty ? Colors.blue : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isDirty ? "Update" : "Save",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _deleteProfile,
                child: Container(
                  width: 120,
                  height: 50,
                  decoration: BoxDecoration(
                    color:themeProvider.isDarkMode?Colors.grey.shade600: Colors.red,
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: const Center(
                    child: Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class LocationDialogPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final Path path = Path();
    
    // Draw main bubble rectangle with rounded corners
    final RRect bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.7),
      const Radius.circular(8),
    );
    
    // Draw the triangle pointer
    path.moveTo(size.width * 0.5 - 6, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(size.width * 0.5 + 6, size.height * 0.7);
    
    // Combine shapes
    path.addRRect(bubble);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}