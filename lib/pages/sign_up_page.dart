import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/login_page.dart';
import 'package:food_delivery_app/service/auth.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController namecontroller = TextEditingController();
  String SelectedRole = "User";
  bool isLoading = false;
  bool isPasswordHidden = false;

  final AuthService _authService = AuthService();

  void _signup() async {
    setState(() {
      isLoading = true;
    });
    String? result = await _authService.signup(
      name: namecontroller.text,
      email: emailcontroller.text,
      password: passwordcontroller.text,
      role: SelectedRole,
    );
    setState(() {
      isLoading = false;
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("SignUp Successful! Now turn to Login"),
        ),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const loginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("SignUp Failed $result,"),
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
            const SizedBox(height: 10),
            Text(
              "Sign-Up for a New Account!",
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
                    borderSide: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  hintText: "Email",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: TextField(
                controller: namecontroller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  hintText: "name",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
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
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  hintText: "password",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                obscureText: isPasswordHidden,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: isDark ? Colors.grey[850] : Colors.white,
                ),
                child: DropdownButtonFormField(
                  value: SelectedRole,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: "Role",
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                  dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                  items: ["Admin", "User"].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      SelectedRole = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onTap: _signup,
                    child: Container(
                      height: 50.0,
                      width: 200.0,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.indigo : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Sign Up",
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
                  "Already have an Account?",
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
                      MaterialPageRoute(builder: (context) => const loginScreen()),
                    );
                  },
                  child: const Text(
                    "Login Here ",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}