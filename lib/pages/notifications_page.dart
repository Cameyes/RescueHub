import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/service/language_provider.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Stream<QuerySnapshot> notificationsStream;

  @override
  void initState() {
    super.initState();
    notificationsStream = FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: widget.userId)
        //.orderBy("timestamp", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider=Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor:themeProvider.isDarkMode?Colors.black: Colors.white,
        title:  Center(
          child: Text(
            languageProvider.translations['notifications']??"Notifications",
            style: TextStyle(
              color:themeProvider.isDarkMode?Colors.white: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor:themeProvider.isDarkMode?Colors.grey.shade800: const Color.fromARGB(255, 170, 245, 245),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return  Center(
              child: Text(
                languageProvider.translations['notifyempty']??"You have no new notifications!",
                style: TextStyle(
                  color:themeProvider.isDarkMode?Colors.white: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(notification['title'] ?? "No Title"),
                subtitle: Text(notification['message'] ?? "No Message"),
                trailing: Text(
                  (notification['timestamp'] as Timestamp).toDate().toString(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
