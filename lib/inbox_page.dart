import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InboxPage extends StatefulWidget {
  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inbox"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No notifications found",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final title = notification['title'];
              final message = notification['message'];
              final read = notification['read'];

              return Card(
                color: read ? Colors.white : Colors.grey[300],
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    // Update the notification's read status to true
                    await firestore.collection('Notifications').doc(notification.id).update({'read': true});

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailPage(
                          notificationId: notification.id,
                          title: title,
                          message: message,
                          timestamp: notification['timestamp'].toDate(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Get the notifications stream for the current user
  Stream<QuerySnapshot> getNotificationsStream() {
    User? user = auth.currentUser;
    if (user != null) {
      return firestore
          .collection('Notifications')
          .where('uid', isEqualTo: user.uid)
          .snapshots();
    } else {
      return Stream.empty();
    }
  }
}

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
