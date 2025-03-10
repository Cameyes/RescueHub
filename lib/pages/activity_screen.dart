import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:provider/provider.dart';

class ActivityScreen extends StatefulWidget {
  final String userId;
  const ActivityScreen({super.key,required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {

    final themeprovider=Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeprovider.isDarkMode?Colors.grey[800]:Colors.white,
      appBar: AppBar(
        backgroundColor: themeprovider.isDarkMode?Colors.grey[900]:Colors.blue,
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            "Your Activity",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}