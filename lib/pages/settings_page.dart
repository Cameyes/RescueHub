import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/login_page.dart';
import 'package:food_delivery_app/service/auth.dart';
import 'package:food_delivery_app/service/language_provider.dart';
import 'package:food_delivery_app/service/localization_service.dart';
import 'package:food_delivery_app/service/translation_service.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import ThemeProvider

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  
  String selectedLanguage = "English"; 
  
  final AuthService _auth=AuthService();
  final TranslationService translationService = TranslationService();

  Map<String, String> translations = {
    'settings': 'App Settings',
    'darkMode': 'Dark Mode',
    'language': 'Language',
    'logout': 'Logout',
    'home':'Home',
    'notifications':'Notifications',
    'notifyempty':'You have no new notifications!',
    'welcome':'Welcome',
    'shelter':'Shelters',
    'food':'Foods',
    'cloth':'Clothes',
    'volunteer':'Volunteers',
    'ambulance':'Ambulance',
    'medical':'Medical Assistance',
    'blood':'Blood Donors',
    'preparedness':'Preparedness',
    'fitfor':'Fit for',
    'preference':'Preference'
  };

    @override
  void initState() {
    super.initState();
    loadLanguagePreference();
  }

  Future<void> loadLanguagePreference() async {
  // Retrieve the saved language preference from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';

  // Update the LanguageProvider with the new locale
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  final languageCode = getLanguageCode(savedLanguage);
  languageProvider.changeLocale(Locale(languageCode));

  // Update the selectedLanguage state
  setState(() {
    selectedLanguage = savedLanguage;
  });

  // Translate UI strings if the language is not English
  if (languageCode != 'en') {
    final localizationService = LocalizationService();
    final translatedStrings = await localizationService.translateScreenStrings(
      translations,
      languageCode,
    );

    languageProvider.updateTranslations(translatedStrings);
  }
}

  String getLanguageCode(String language) {
    switch (language) {
      case 'Hindi':
        return 'hi';
      case 'Malayalam':
        return 'ml';
      case 'Tamil':
        return 'ta';
      default:
        return 'en';
    }
  }

  Future<void> translateUI(String languageCode) async {
    if (languageCode == 'en') {
      setState(() {
        translations = {
          'app settings': 'App Settings',
          'darkMode': 'Dark Mode',
          'language': 'Language',
          'logout': 'Logout',
          'home':'Home',
          'notifications':'Notifications',
          'notifyempty':'You have no new notifications!',
          'welcome':'Welcome',
          'shelter':'Shelters',
          'food':'Foods',
          'cloth':'Cloths',
          'volunteer':'Volunteers',
          'ambulance':'Ambulance',
          'medical':'Medical Assistance',
          'blood':'Blood Donors',
          'preparedness':'Preparedness',
          'fitfor':'Fit for',
          'preference':'Preference'
        };
      });
      return;
    }

    List<Future<String>> translationFutures = translations.entries.map(
    (entry) => translationService.translateText(entry.value, languageCode),
  ).toList();

  List<String> translatedValues = await Future.wait(translationFutures);

  setState(() {
    translations = {
      for (int i = 0; i < translations.keys.length; i++)
        translations.keys.elementAt(i): translatedValues[i],
    };
  });
  }


  void handleSignOut() async{
    try{
      await _auth.signOut();
      Navigator.pushReplacement(context,
       MaterialPageRoute(builder: (_)=>const loginScreen()));
    }
     catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e'))
      );
    }
  }
  
  void showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () async{
                await _changeLanguage('English');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Hindi'),
              onTap: () async{
                 await _changeLanguage('Hindi');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Malayalam'),
              onTap: () async{
                await _changeLanguage('Malayalam');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Tamil'),
              onTap: () async{
                await _changeLanguage('Tamil');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeLanguage(String language) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('selectedLanguage', language);

    // Update the selectedLanguage state
  setState(() {
    selectedLanguage = language;
  });


  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  languageProvider.changeLocale(Locale(getLanguageCode(language)));

  final localizationService = LocalizationService();
  final translatedStrings = await localizationService.translateScreenStrings(
    translations,
    getLanguageCode(language),
  );

  languageProvider.updateTranslations(translatedStrings);
}

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider using Provider.of
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      body: Column(
        children: [
          Container(
            color: themeProvider.isDarkMode ? Colors.black : Colors.blue,
            width: double.infinity,
            height: 100,
            child: Center(
              child: Text(
                 languageProvider.translations['settings'] ?? 'App Settings',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  languageProvider.translations['darkMode'] ?? 'Dark Mode',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 24,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: themeProvider.isDarkMode ? Colors.indigo[900] : Colors.blue[100],
                  ),
                  child: Stack(
                    children: [
                      // Background icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Center(
                            child: Icon(
                              Icons.nightlight_round,
                              color: themeProvider.isDarkMode ? Colors.grey : Colors.white,
                              size: 20,
                            ),
                          ),
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.orange,
                            size: 20,
                          ),
                        ],
                      ),
                      // Animated switch circle
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: themeProvider.isDarkMode
                            ? const Alignment(0.8, 0.0)
                            : const Alignment(-0.8, 0.0),
                        child: GestureDetector(
                          onTap: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeProvider.isDarkMode ? Colors.indigo : Colors.white,
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
            ],
          ),
          Divider(
                color: themeProvider.isDarkMode?Colors.white:Colors.black, // Line color
                thickness: 1,       // Line thickness
                    // Right spacing
              ),
              GestureDetector(
            onTap: showLanguageSelector,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                          languageProvider.translations['language']?? "Language",
                      style: TextStyle(
                        color: themeProvider.isDarkMode?Colors.white:Colors.black,
                        fontSize: 22),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        selectedLanguage,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.grey),
                      ),
                       Icon(
                        Icons.arrow_drop_down,
                        color: themeProvider.isDarkMode?Colors.white:Colors.black,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
                color: themeProvider.isDarkMode?Colors.white:Colors.black, // Line color
                thickness: 1,       // Line thickness
                    // Right spacing
              ),
              GestureDetector(
            onTap: handleSignOut,
            child:  Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    languageProvider.translations['logout']??"LogOut",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                    ),
                  ),
                ),
                Icon(Icons.logout,color: Colors.red,)
              ],
            ),
          ),
          Divider(
                color: themeProvider.isDarkMode?Colors.white:Colors.black, // Line color
                thickness: 1,       // Line thickness
                    // Right spacing
              )
        ],
      ),
    );
  }
}