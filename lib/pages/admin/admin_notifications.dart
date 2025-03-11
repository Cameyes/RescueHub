import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminNotifications extends StatefulWidget {
  final String UserId;
  
  const AdminNotifications({super.key, required this.UserId});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  late Stream<QuerySnapshot> notificationsStream;

  @override
  void initState() {
    super.initState();
    notificationsStream = FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: widget.UserId)
        .snapshots();
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing notification: $e')),
      );
    }
  }

  Widget _buildNotificationContent(Map<String, dynamic> notification) {
    if (notification['type'] == 'admin_shelter_approval') {
      return ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.check_circle_outline, color: Colors.white),
        ),
        title: Text(notification['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, hh:mm a').format(
                (notification['timestamp'] as Timestamp).toDate()
              ),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Default notification display
    return ListTile(
      title: Text(notification['title']),
      subtitle: Text(notification['message']),
      trailing: Text(
        DateFormat('MMM dd, hh:mm a').format(
          (notification['timestamp'] as Timestamp).toDate()
        ),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        title: const Center(
          child: Text(
            "Admin Notifications",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: themeProvider.isDarkMode 
          ? Colors.grey.shade800 
          : const Color.fromARGB(255, 170, 245, 245),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "You have no new notifications!",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Dismissible(
                  key: Key(notificationId),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteNotification(notificationId);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                          ? Colors.grey.shade700 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildNotificationContent(notification),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}