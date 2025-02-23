import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/intro_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:food_delivery_app/components/theme_provider.dart'; // Import ThemeProvider
import 'package:food_delivery_app/service/language_provider.dart'; // Import LanguageProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Firebase App Check (if needed)
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Provide the ThemeProvider
        ChangeNotifierProvider(create: (_) => LanguageProvider()), // Provide the LanguageProvider
      ],
      child: Consumer<ThemeProvider>( // Listen for changes in theme
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
              primaryColor: themeProvider.isDarkMode ? Colors.indigo : Colors.blue,
            ),
            home: const IntroPage(), // Your initial screen
          );
        },
      ),
    );
  }
}