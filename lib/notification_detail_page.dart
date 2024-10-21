import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final String notificationId;
  final String title;
  final String message;
  final DateTime timestamp;

  NotificationDetailPage({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Details"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Sent on: ${timestamp.toLocal()}",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
