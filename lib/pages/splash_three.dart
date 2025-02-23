import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/login_page.dart';

class SplashThree extends StatefulWidget {
  const SplashThree({super.key});

  @override
  State<SplashThree> createState() => _SplashThreeState();
}

class _SplashThreeState extends State<SplashThree> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/videos/beach_waves.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Your existing top content
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 60),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Center(
                    child: Text(
                      "Rescue\nHub.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
            const Text(
              "Features",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Your feature containers
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 11, 128, 223),
                    Color.fromARGB(255, 234, 232, 232)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                blendMode: BlendMode.multiply,
                child: Container(
                  height: 200,
                  width: 300,
                  color: Colors.white,
                  child: const Center(
                    child: Text(
                      "Disaster Preparedness",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 224, 231, 237),
                    Color.fromARGB(255, 164, 48, 5)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                blendMode: BlendMode.multiply,
                child: Container(
                  height: 200,
                  width: 300,
                  color: Colors.white,
                  child: const Center(
                    child: Text(
                      "Multilingual Functionality",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Spacer to push the bottom content down
            const Spacer(),
            // Bottom content with dots and continue button
            Column(
              children: [
                // Your dots indicator will be here
                const SizedBox(height: 20),
                // Continue button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const loginScreen()),
                    );
                  },
                  child: Container(
                    height: 50.0,
                    width: 350.0,
                    margin: const EdgeInsets.only(bottom: 30.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.blue,
                    ),
                    child: const Center(
                      child: Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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