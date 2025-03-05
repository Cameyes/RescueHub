import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:provider/provider.dart';

class AdminNotifications extends StatefulWidget {
  final String UserId;
  const AdminNotifications({super.key, required this.UserId});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  @override
  Widget build(BuildContext context) {
    final themeProvider=Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor:themeProvider.isDarkMode?Colors.grey[900]: Colors.blue[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:themeProvider.isDarkMode?Colors.black: Colors.blue[400],
        title: Center(child: Text("Notifications",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
        )),
      ),
      body: Center(
        child: Text("You have no notifications!!!",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
        )),
      ),
    );
  }
}