import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/admin/admin_details_form.dart';
import 'package:food_delivery_app/pages/admin/admin_screen.dart';
import 'package:food_delivery_app/pages/location_selector.dart';
import 'package:food_delivery_app/pages/map_page.dart';
import 'package:food_delivery_app/pages/sign_up_page.dart';
import 'package:food_delivery_app/service/auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {


  TextEditingController emailcontroller=TextEditingController();
  TextEditingController passwordcontroller=TextEditingController();
  bool isPasswordHidden=true;
  //instance for authService for authentication logic
  final AuthService _authService=AuthService();

  bool isLoading=false;
  void login()async{

    //Request Permissions
    bool permissionGranted =await requestPermissions();

    if(!permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Required Permissions not granted."),
          backgroundColor: Colors.red,
        )
        );
        return;
    }

    setState(() {
      isLoading=true;
    });

    //call login method from authServices with user inputs
    String? result =await _authService.login(email: emailcontroller.text, password: passwordcontroller.text,);
    setState(() {
      isLoading=false;
    });
    //Navigate based on role to Show the error message
    // In the login() method, modify the Admin condition:

if (result == "Admin") {
  String? userId = await _authService.getCurrentUserId();
  if (userId != null) {
    DocumentSnapshot adminDoc = await FirebaseFirestore.instance
        .collection('adminDetails')
        .doc(userId)
        .get();

    if (adminDoc.exists) {
      String adminLocation = adminDoc["location"] ?? "Unknown Location";
      
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (_) => AdminScreen(userId: userId, location: adminLocation),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (_) => AdminDetailsForm(userId: userId, userEmail: emailcontroller.text),
        ),
      );
    }
  }
}

    else if(result == "User"){
      String? userId=await _authService.getCurrentUserId(); // Get userId from auth
      if (userId != null) {
    final selectedLocation= await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>  LocationSelector(initialLocation: "Thrissur",),
      ),
    );
    if (selectedLocation != null) {
        // Navigate to Map Page with the selected location
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MapPage(userId: userId,selectedLoc: selectedLocation,),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location selection is required.")),
        );
      }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error: Unable to retrieve user ID")),
    );
  }
    }
    else{
      //login failed: show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed $result,"),
          ),
        );
    }
  }

  //request permissions method
  Future<bool> requestPermissions() async{

    // First check current status
  bool hasAllPermissions = await checkPermissions();
  if (hasAllPermissions) return true;

  if (!context.mounted) return false;
  showPermissionRationale();
  
  await Future.delayed(const Duration(seconds: 2));

    Map<Permission,PermissionStatus> statuses=await[
      Permission.sms,
      Permission.phone,
      Permission.location,
    ].request();
    //check if all permissions are granted
    return statuses.values.every((status)=>status.isGranted);
  }

  Future<bool> checkPermissions() async {
  return await Permission.sms.isGranted && 
         await Permission.phone.isGranted && 
         await Permission.location.isGranted;
}

  void showPermissionRationale() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      duration: Duration(seconds: 5),
      content: Text(
        "This app requires SMS, phone, and location permissions to provide emergency services. "
        "These permissions are essential for contacting emergency services and determining your location in case of emergencies."
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

  void forgotPassword() async {
    // Show dialog to get email
    String? email = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController emailController = TextEditingController();
        return AlertDialog(
          title: Text('Reset Password'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Enter your email',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, emailController.text),
              child: Text('Send Reset Link'),
            ),
          ],
        );
      },
    );

    // If email is provided, send reset link
    if (email != null && email.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      String? result = await _authService.resetPassword(email: email);
      
      setState(() {
        isLoading = false;
      });

      // Show result message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? "Password reset email sent"),
          backgroundColor: result == "Password reset email sent" 
              ? Colors.green 
              : Colors.red,
        ),
      );
    }
  }
  


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Image.asset(
               themeProvider.isDarkMode? 'lib/images/flood-neg.png':'lib/images/flood.png',
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
             Padding(
            padding: const EdgeInsets.only(right: 280.0),
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark ? Colors.indigo[900] : Colors.blue[100],
              ),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Center(
                        child: Icon(
                          Icons.nightlight_round,
                          color: isDark ? const Color.fromARGB(255, 73, 102, 127) : Colors.white,
                          size: 20,
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.wb_sunny_outlined,
                          color: isDark ? Colors.white : Colors.orange,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: isDark
                        ? const Alignment(0.8, 0.0)
                        : const Alignment(-0.8, 0.0),
                    child: GestureDetector(
                      onTap: () => themeProvider.toggleTheme(!isDark),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.indigo : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 60),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? Colors.indigo : Colors.black,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Center(
                    child: Text(
                      "Rescue\nHub.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Login to Continue",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: TextField(
                controller: emailcontroller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  suffixIcon: Icon(
                    Icons.email,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: TextField(
                controller: passwordcontroller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  hintText: "password",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                obscureText: isPasswordHidden,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Forgot Password ?",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                InkWell(
                  onTap: forgotPassword,
                  child: const Text(
                    " Click Here ",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onTap: login,
                    child: Container(
                      height: 50.0,
                      width: 200.0,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.indigo : Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80.0),
                Text(
                  "Doesn't have an Account?",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    "Sign Up here ",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}