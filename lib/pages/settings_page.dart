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
  'home': 'Home',
  'notifications': 'Notifications',
  'notifyempty': 'You have no new notifications!',
  'welcome': 'Welcome',
  'shelter': 'Shelters',
  'food': 'Foods',
  'cloth': 'Clothes',
  'fire': 'Fire Rescue Service',
  'volunteer': 'Volunteers',
  'ambulance': 'Ambulance',
  'medical': 'Medical Assistance',
  'blood': 'Blood Donors',
  'preparedness': 'Preparedness',
  'fitfor': 'Fit for',
  'preference': 'Preference',
  'leaverev': 'Leave a review',
  'writerev': 'Write a Review',
  'subrev': 'Submit Review',
  'booknow': 'Book Now',
  'datecre': 'Date Created',
  'description': 'Description',
  'rev': 'Reviews',
  'norev': 'No Reviews yet',
  'emptyrev': 'Reviews cannot be empty',
  'onerev': 'You can Only Submit One Review',
  'floods': 'Flood',
  'floodsdesc': 'Thrissur is prone to floods during the monsoon season, particularly in low-lying areas and near rivers.',
  'prep': 'Preparedness Points',
  'floodspt1': 'Keep emergency kit with essential supplies',
  'floodspt2': 'Know your evacuation routes to higher ground',
  'floodspt3': 'Keep important documents in a waterproof container',
  'floodspt4': 'Keep your mobile phones charged',
  'floodspt5': 'Monitor local weather updates regularly',
  'sftips': 'Safety Tips',
  'floodtsip1': 'Move to higher ground immediately when warned',
  'floodstip2': 'Avoid walking through flood waters',
  'floodstip3': 'Do not drive through flooded areas',
  'floodstip4': 'Follow instructions from local authorities',
  'rescuevid':'Rescue Tips Videos',
  // Landslides
  'landslides': 'Landslides',
  'landslidesdesc': 'Risk of landslides in hilly areas, especially during heavy rainfall.',
  'landslidespt1': 'Identify safe zones in your area',
  'landslidespt2': 'Watch for warning signs like cracks in the ground',
  'landslidespt3': 'Have an emergency evacuation plan',
  'landslidespt4': 'Keep emergency supplies ready',
  'landslidestip1': 'Evacuate immediately if warned',
  'landslidestip2': 'Move to pre-identified safe locations',
  'landslidestip3': 'Stay alert during heavy rains',

  // Lightning
  'lightning': 'Lightning',
  'lightningdesc': 'Frequent lightning strikes during pre-monsoon and monsoon seasons.',
  'lightningpt1': 'Install lightning arresters',
  'lightningpt2': 'Unplug electronic devices during storms',
  'lightningpt3': 'Identify safe indoor locations',
  'lightningpt4': 'Monitor weather warnings',
  'lightningtip1': 'Stay indoors during thunderstorms',
  'lightningtip2': 'Avoid open areas and tall objects',
  'lightningtip3': 'Stay away from windows and electrical equipment',

  // Earthquakes
  'earthquakes': 'Earthquakes',
  'earthquakesdesc': 'Occasional mild seismic activity in the region.',
  'earthquakespt1': 'Secure heavy furniture to walls',
  'earthquakespt2': 'Identify safe spots in each room',
  'earthquakespt3': 'Keep emergency supplies accessible',
  'earthquakespt4': 'Know how to shut off utilities',
  'earthquakestip1': 'Drop, cover, and hold on',
  'earthquakestip2': 'Stay away from windows',
  'earthquakestip3': 'Be prepared for aftershocks',

  // Cyclones
  'cyclones': 'Cyclones',
  'cyclonesdesc': 'Seasonal cyclonic activity affecting coastal areas.',
  'cyclonespt1': 'Strengthen house structure',
  'cyclonespt2': 'Keep emergency supplies ready',
  'cyclonespt3': 'Know evacuation routes',
  'cyclonespt4': 'Have battery-powered radio',
  'cyclonestip1': 'Stay updated with weather alerts',
  'cyclonestip2': 'Secure loose objects outside',
  'cyclonestip3': 'Follow evacuation orders promptly',

  // Disease Outbreaks
  'disease outbreaks': 'Disease Outbreaks',
  'disease outbreaksdesc': 'Risk of waterborne diseases during floods and epidemics.',
  'disease outbreakspt1': 'Maintain hygiene supplies',
  'disease outbreakspt2': 'Know local health facilities',
  'disease outbreakspt3': 'Keep vaccination records updated',
  'disease outbreakspt4': 'Store essential medicines',
  'disease outbreakstip1': 'Practice good hygiene',  // Changed from 'diseaseoutbreakstip1'
  'disease outbreakstip2': 'Boil drinking water',    // Changed from 'diseaseoutbreakstip2'
  'disease outbreakstip3': 'Seek medical help promptly',  // Changed from 'diseaseoutbreakstip3'

  // Heat Waves
  'heat waves': 'Heat Waves',
  'heat wavesdesc': 'Palakkad is known for extreme heat conditions due to the Palakkad Gap.',
  'heat wavespt1': 'Install proper ventilation systems',
  'heat wavespt2': 'Keep hydration supplies ready',
  'heat wavespt3': 'Have backup power for cooling',
  'heat wavespt4': 'Create cool zones in home',
  'heat wavestip1': 'Stay hydrated',
  'heat wavestip2': 'Avoid outdoor activities during peak hours',
  'heat wavestip3': 'Use light-colored, loose clothing',
  'heat wavestip4': 'Check on vulnerable neighbors',

  // Drought
  'drought': 'Drought',
  'droughtdesc': 'Regular drought conditions affecting agriculture and water supply.',
  'droughtpt1': 'Implement water conservation methods',
  'droughtpt2': 'Install rainwater harvesting systems',
  'droughtpt3': 'Maintain water storage facilities',
  'droughtpt4': 'Plan for alternative water sources',
  'droughttip1': 'Use water efficiently',
  'droughttip2': 'Collect and store rainwater',
  'droughttip3': 'Follow water usage restrictions',

  // Forest Fires
  'forest fires': 'Forest Fires',
  'forest firesdesc': 'Risk of forest fires during summer months.',
  'forest firespt1': 'Create fire breaks around properties',
  'forest firespt2': 'Keep emergency supplies ready',
  'forest firespt3': 'Have evacuation plan ready',
  'forest firespt4': 'Maintain communication devices',
  'forest firestip1': 'Report fires immediately',
  'forest firestip2': 'Follow evacuation orders promptly',
  'forest firestip3': 'Keep surrounding areas clear of dry vegetation',

  // Agricultural Pests
  'agricultural pests': 'Agricultural Pests',
  'agricultural pestsdesc': 'Seasonal pest infestations affecting crops.',
  'agricultural pestspt1': 'Monitor crop health regularly',
  'agricultural pestspt2': 'Maintain pest control supplies',
  'agricultural pestspt3': 'Have crop insurance',
  'agricultural pestspt4': 'Know agricultural experts contacts',
  'agricultural peststip1': 'Implement integrated pest management',
  'agricultural peststip2': 'Use appropriate pesticides safely',
  'agricultural peststip3': 'Report unusual pest activity',

  // Wind Storms
  'wind storms': 'Wind Storms',
  'wind stormsdesc': 'Strong winds through Palakkad Gap causing damage.',
  'wind stormspt1': 'Secure loose structures',
  'wind stormspt2': 'Trim weak tree branches',
  'wind stormspt3': 'Install wind barriers',
  'wind stormspt4': 'Maintain emergency supplies',
  'wind stormstip1': 'Stay indoors during storms',
  'wind stormstip2': 'Keep away from windows',
  'wind stormstip3': 'Park vehicles in safe areas',

  // Soil Erosion
  'soil erosion': 'Soil Erosion',
  'soil erosiondesc': 'Severe soil erosion affecting agricultural lands.',
  'soil erosionpt1': 'Implement soil conservation methods',
  'soil erosionpt2': 'Plant soil-binding vegetation',
  'soil erosionpt3': 'Build retention walls',
  'soil erosionpt4': 'Monitor soil health',
  'soil erosiontip1': 'Practice contour farming',
  'soil erosiontip2': 'Maintain ground cover',
  'soil erosiontip3': 'Report severe erosion',

  // Urban Floods
  'urban floods': 'Urban Floods',
  'urban floodsdesc': 'Urban flooding due to heavy rainfall and poor drainage.',
  'urban floodspt1': 'Know your building\'s flood risk',
  'urban floodspt2': 'Keep emergency supplies at higher levels',
  'urban floodspt3': 'Have backup power arrangements',
  'urban floodspt4': 'Know evacuation routes and safe zones',
  'urban floodstip1': 'Move vehicles to higher ground',
  'urban floodstip2': 'Avoid underground parking during heavy rain',
  'urban floodstip3': 'Follow local authority instructions',

  // Coastal Hazards
  'coastal hazards': 'Coastal Hazards',
  'coastal hazardsdesc': 'Risk of storm surges and coastal erosion.',
  'coastal hazardspt1': 'Know high-tide timings',
  'coastal hazardspt2': 'Keep emergency kit ready',
  'coastal hazardspt3': 'Have evacuation plan ready',
  'coastal hazardspt4': 'Monitor weather warnings',
  'coastal hazardstip1': 'Move away from coastal areas during warnings',
  'coastal hazardstip2': 'Secure boats and property',
  'coastal hazardstip3': 'Follow coast guard instructions',

  // Industrial Accidents
  'industrial accidents': 'Industrial Accidents',
  'industrial accidentsdesc': 'Risk of industrial accidents due to high concentration of industries.',
  'industrial accidentspt1': 'Know nearby industrial zones',
  'industrial accidentspt2': 'Keep emergency contacts ready',
  'industrial accidentspt3': 'Have masks and protective gear',
  'industrial accidentspt4': 'Know evacuation routes',
  'industrial accidentstip1': 'Stay indoors during chemical leaks',
  'industrial accidentstip2': 'Follow emergency broadcast instructions',
  'industrial accidentstip3': 'Keep windows closed during incidents',

  // Air Pollution
  'air pollution': 'Air Pollution',
  'air pollutiondesc': 'Health risks due to industrial emissions, vehicle exhaust, and wildfire smoke.',
  'air pollutionpt1': 'Check air quality index (AQI) regularly',
  'air pollutionpt2': 'Wear N95 masks in high pollution areas',
  'air pollutionpt3': 'Use air purifiers indoors',
  'air pollutionpt4': 'Seal windows and doors during smog events',
  'air pollutiontip1': 'Limit outdoor activities during high pollution levels',
  'air pollutiontip2': 'Stay hydrated and avoid strenuous exercise',
  'air pollutiontip3': 'Use public transport or carpool to reduce emissions',

  // Building Collapse
  'building collapse': 'Building Collapse',
  'building collapsedesc': 'Risk in old buildings and construction zones.',
  'building collapsept1': 'Know building safety codes',
  'building collapsept2': 'Identify structural weaknesses',
  'building collapsept3': 'Have evacuation plan',
  'building collapsept4': 'Keep emergency supplies',
  'building collapsetip1': 'Evacuate if cracks appear',
  'building collapsetip2': 'Report structural issues',
  'building collapsetip3': 'Follow safety guidelines',

  // Transportation Accidents
  'transportation accidents': 'Transportation Accidents',
  'transportation accidentsdesc': 'Risks due to heavy traffic and transport hubs.',
  'transportation accidentspt1': 'Know alternative routes',
  'transportation accidentspt2': 'Keep first aid kit ready',
  'transportation accidentspt3': 'Have emergency contacts',
  'transportation accidentspt4': 'Know nearby hospitals',
  'transportation accidentstip1': 'Follow traffic rules',
  'transportation accidentstip2': 'Stay alert in traffic',
  'transportation accidentstip3': 'Report accidents promptly',
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
          'fire':'Fire Rescue Service',
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
          'preference':'Preference',
          'leaverev':'Leave a review',
          'writerev':'Write a Review',
          'subrev':'Submit Review',
          'booknow':'Book Now',
          'datecre':'Date Created',
          'description':'Description',
          'rev':'Reviews',
          'norev':'No Reviews yet',
          'emptyrev':'Reviews cannot be empty',
          'onerev':'You can Only Submit One Review',
          'rescuevid':'Rescue Tips Videos',
          'flood': 'Flood',
  'flooddesc': 'Thrissur is prone to floods during the monsoon season, particularly in low-lying areas and near rivers.',
  'prep': 'Preparedness Points',
  'floodpt1': 'Keep emergency kit with essential supplies',
  'floodpt2': 'Know your evacuation routes to higher ground',
  'floodpt3': 'Keep important documents in a waterproof container',
  'floodpt4': 'Keep your mobile phones charged',
  'floodpt5': 'Monitor local weather updates regularly',
  'sftips': 'Safety Tips',
  'floodtip1': 'Move to higher ground immediately when warned',
  'floodtip2': 'Avoid walking through flood waters',
  'floodtip3': 'Do not drive through flooded areas',
  'floodtip4': 'Follow instructions from local authorities',

  // Landslides
  'landslides': 'Landslides',
  'landslidesdesc': 'Risk of landslides in hilly areas, especially during heavy rainfall.',
  'landslidespt1': 'Identify safe zones in your area',
  'landslidespt2': 'Watch for warning signs like cracks in the ground',
  'landslidespt3': 'Have an emergency evacuation plan',
  'landslidespt4': 'Keep emergency supplies ready',
  'landslidestip1': 'Evacuate immediately if warned',
  'landslidestip2': 'Move to pre-identified safe locations',
  'landslidestip3': 'Stay alert during heavy rains',

  // Lightning
  'lightning': 'Lightning',
  'lightningdesc': 'Frequent lightning strikes during pre-monsoon and monsoon seasons.',
  'lightningpt1': 'Install lightning arresters',
  'lightningpt2': 'Unplug electronic devices during storms',
  'lightningpt3': 'Identify safe indoor locations',
  'lightningpt4': 'Monitor weather warnings',
  'lightningtip1': 'Stay indoors during thunderstorms',
  'lightningtip2': 'Avoid open areas and tall objects',
  'lightningtip3': 'Stay away from windows and electrical equipment',

  // Earthquakes
  'earthquakes': 'Earthquakes',
  'earthquakesdesc': 'Occasional mild seismic activity in the region.',
  'earthquakespt1': 'Secure heavy furniture to walls',
  'earthquakespt2': 'Identify safe spots in each room',
  'earthquakespt3': 'Keep emergency supplies accessible',
  'earthquakespt4': 'Know how to shut off utilities',
  'earthquakestip1': 'Drop, cover, and hold on',
  'earthquakestip2': 'Stay away from windows',
  'earthquakestip3': 'Be prepared for aftershocks',

  // Cyclones
  'cyclones': 'Cyclones',
  'cyclonesdesc': 'Seasonal cyclonic activity affecting coastal areas.',
  'cyclonespt1': 'Strengthen house structure',
  'cyclonespt2': 'Keep emergency supplies ready',
  'cyclonespt3': 'Know evacuation routes',
  'cyclonespt4': 'Have battery-powered radio',
  'cyclonestip1': 'Stay updated with weather alerts',
  'cyclonestip2': 'Secure loose objects outside',
  'cyclonestip3': 'Follow evacuation orders promptly',

  // Disease Outbreaks
  'disease outbreaks': 'Disease Outbreaks',
  'disease outbreaksdesc': 'Risk of waterborne diseases during floods and epidemics.',
  'disease outbreakspt1': 'Maintain hygiene supplies',
  'disease outbreakspt2': 'Know local health facilities',
  'disease outbreakspt3': 'Keep vaccination records updated',
  'disease outbreakspt4': 'Store essential medicines',
  'disease outbreakstip1': 'Practice good hygiene',  // Changed from 'diseaseoutbreakstip1'
  'disease outbreakstip2': 'Boil drinking water',    // Changed from 'diseaseoutbreakstip2'
  'disease outbreakstip3': 'Seek medical help promptly',  // Changed from 'diseaseoutbreakstip3'

  // Heat Waves
  'heat waves': 'Heat Waves',
  'heat wavesdesc': 'Palakkad is known for extreme heat conditions due to the Palakkad Gap.',
  'heat wavespt1': 'Install proper ventilation systems',
  'heat wavespt2': 'Keep hydration supplies ready',
  'heat wavespt3': 'Have backup power for cooling',
  'heat wavespt4': 'Create cool zones in home',
  'heat wavestip1': 'Stay hydrated',
  'heat wavestip2': 'Avoid outdoor activities during peak hours',
  'heat wavestip3': 'Use light-colored, loose clothing',
  'heat wavestip4': 'Check on vulnerable neighbors',

  // Drought
  'drought': 'Drought',
  'droughtdesc': 'Regular drought conditions affecting agriculture and water supply.',
  'droughtpt1': 'Implement water conservation methods',
  'droughtpt2': 'Install rainwater harvesting systems',
  'droughtpt3': 'Maintain water storage facilities',
  'droughtpt4': 'Plan for alternative water sources',
  'droughttip1': 'Use water efficiently',
  'droughttip2': 'Collect and store rainwater',
  'droughttip3': 'Follow water usage restrictions',

  // Forest Fires
  'forest fires': 'Forest Fires',
  'forest firesdesc': 'Risk of forest fires during summer months.',
  'forest firespt1': 'Create fire breaks around properties',
  'forest firespt2': 'Keep emergency supplies ready',
  'forest firespt3': 'Have evacuation plan ready',
  'forest firespt4': 'Maintain communication devices',
  'forest firestip1': 'Report fires immediately',
  'forest firestip2': 'Follow evacuation orders promptly',
  'forest firestip3': 'Keep surrounding areas clear of dry vegetation',

  // Agricultural Pests
  'agricultural pests': 'Agricultural Pests',
  'agricultural pestsdesc': 'Seasonal pest infestations affecting crops.',
  'agricultural pestspt1': 'Monitor crop health regularly',
  'agricultural pestspt2': 'Maintain pest control supplies',
  'agricultural pestspt3': 'Have crop insurance',
  'agricultural pestspt4': 'Know agricultural experts contacts',
  'agricultural peststip1': 'Implement integrated pest management',
  'agricultural peststip2': 'Use appropriate pesticides safely',
  'agricultural peststip3': 'Report unusual pest activity',

  // Wind Storms
  'wind storms': 'Wind Storms',
  'wind stormsdesc': 'Strong winds through Palakkad Gap causing damage.',
  'wind stormspt1': 'Secure loose structures',
  'wind stormspt2': 'Trim weak tree branches',
  'wind stormspt3': 'Install wind barriers',
  'wind stormspt4': 'Maintain emergency supplies',
  'wind stormstip1': 'Stay indoors during storms',
  'wind stormstip2': 'Keep away from windows',
  'wind stormstip3': 'Park vehicles in safe areas',

  // Soil Erosion
  'soil erosion': 'Soil Erosion',
  'soil erosiondesc': 'Severe soil erosion affecting agricultural lands.',
  'soil erosionpt1': 'Implement soil conservation methods',
  'soil erosionpt2': 'Plant soil-binding vegetation',
  'soil erosionpt3': 'Build retention walls',
  'soil erosionpt4': 'Monitor soil health',
  'soil erosiontip1': 'Practice contour farming',
  'soil erosiontip2': 'Maintain ground cover',
  'soil erosiontip3': 'Report severe erosion',

  // Urban Floods
  'urban floods': 'Urban Floods',
  'urban floodsdesc': 'Urban flooding due to heavy rainfall and poor drainage.',
  'urban floodspt1': 'Know your building\'s flood risk',
  'urban floodspt2': 'Keep emergency supplies at higher levels',
  'urban floodspt3': 'Have backup power arrangements',
  'urban floodspt4': 'Know evacuation routes and safe zones',
  'urban floodstip1': 'Move vehicles to higher ground',
  'urban floodstip2': 'Avoid underground parking during heavy rain',
  'urban floodstip3': 'Follow local authority instructions',

  // Coastal Hazards
  'coastal hazards': 'Coastal Hazards',
  'coastal hazardsdesc': 'Risk of storm surges and coastal erosion.',
  'coastal hazardspt1': 'Know high-tide timings',
  'coastal hazardspt2': 'Keep emergency kit ready',
  'coastal hazardspt3': 'Have evacuation plan ready',
  'coastal hazardspt4': 'Monitor weather warnings',
  'coastal hazardstip1': 'Move away from coastal areas during warnings',
  'coastal hazardstip2': 'Secure boats and property',
  'coastal hazardstip3': 'Follow coast guard instructions',

  // Industrial Accidents
  'industrial accidents': 'Industrial Accidents',
  'industrial accidentsdesc': 'Risk of industrial accidents due to high concentration of industries.',
  'industrial accidentspt1': 'Know nearby industrial zones',
  'industrial accidentspt2': 'Keep emergency contacts ready',
  'industrial accidentspt3': 'Have masks and protective gear',
  'industrial accidentspt4': 'Know evacuation routes',
  'industrial accidentstip1': 'Stay indoors during chemical leaks',
  'industrial accidentstip2': 'Follow emergency broadcast instructions',
  'industrial accidentstip3': 'Keep windows closed during incidents',

  // Air Pollution
  'air pollution': 'Air Pollution',
  'air pollutiondesc': 'Health risks due to industrial emissions, vehicle exhaust, and wildfire smoke.',
  'air pollutionpt1': 'Check air quality index (AQI) regularly',
  'air pollutionpt2': 'Wear N95 masks in high pollution areas',
  'air pollutionpt3': 'Use air purifiers indoors',
  'air pollutionpt4': 'Seal windows and doors during smog events',
  'air pollutiontip1': 'Limit outdoor activities during high pollution levels',
  'air pollutiontip2': 'Stay hydrated and avoid strenuous exercise',
  'air pollutiontip3': 'Use public transport or carpool to reduce emissions',

  // Building Collapse
  'building collapse': 'Building Collapse',
  'building collapsedesc': 'Risk in old buildings and construction zones.',
  'building collapsept1': 'Know building safety codes',
  'building collapsept2': 'Identify structural weaknesses',
  'building collapsept3': 'Have evacuation plan',
  'building collapsept4': 'Keep emergency supplies',
  'building collapsetip1': 'Evacuate if cracks appear',
  'building collapsetip2': 'Report structural issues',
  'building collapsetip3': 'Follow safety guidelines',

  // Transportation Accidents
  'transportation accidents': 'Transportation Accidents',
  'transportation accidentsdesc': 'Risks due to heavy traffic and transport hubs.',
  'transportation accidentspt1': 'Know alternative routes',
  'transportation accidentspt2': 'Keep first aid kit ready',
  'transportation accidentspt3': 'Have emergency contacts',
  'transportation accidentspt4': 'Know nearby hospitals',
  'transportation accidentstip1': 'Follow traffic rules',
  'transportation accidentstip2': 'Stay alert in traffic',
  'transportation accidentstip3': 'Report accidents promptly',
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
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Changing language to $language...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
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

    // Close the loading dialog
    Navigator.of(context).pop();
  } catch (e) {
    // Close the loading dialog
    Navigator.of(context).pop();

    // Show error dialog if something goes wrong
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Failed to change language. Please try again.'),
          actions: [
            TextButton(
              child: Text('OK'),
               onPressed: () { Navigator.of(context).pop(); },
            ),
          ],
        );
      },
    );
  }
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