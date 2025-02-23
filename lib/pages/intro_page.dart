import 'package:flutter/material.dart';

import 'package:food_delivery_app/pages/splash_screen_slider.dart';


class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  bool istap=false;
  
  
  void toggleTap() {
    setState(() {
      istap = !istap; // Toggle the tap state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Image.asset('lib/images/flood.png',
              height: 480,
              fit: BoxFit.cover,),
            ),
            const SizedBox(height: 10,),
            const Text("Welcome to RescueHub",
            style: TextStyle(
              color: Colors.black,
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
            ),),
            const SizedBox(height:10,),
            const Text("Safety is just a tap away.",
            style: TextStyle(
              color:Colors.black,
              fontSize: 18.0,
              fontWeight:FontWeight.bold,
            ),),
            const SizedBox(height:200.0),
            GestureDetector(
              child: Container(
                height: 50.0,
                width: 350.0,
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: istap?Colors.green:Colors.blue,
                ),
                //color: Colors.blue,
                child: Center(
                  child: Text("Continue",
                  style: TextStyle(
                    color: istap?Colors.white:Colors.white,
                     fontSize: 22.0,
                     fontWeight: FontWeight.bold,
                  ),),
                ),
              ),
              onTap: (){
                toggleTap();
                Navigator.push(context, MaterialPageRoute(builder: (context)=>SplashScreenSlider()));
              },
            )
          ],
        ),
      ),      
    );
  }
}