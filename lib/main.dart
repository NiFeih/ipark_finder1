import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import Local Notifications
import 'login_page.dart'; // Ensure login.dart is correctly imported

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This is a background handler for receiving notifications
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyCSyYjfCZvkc0K4Ai1L4heQH4zw7MtGsaY',
        appId: '1:55426688816:android:6876cdb5e5e898e387caf5',
        messagingSenderId: '55426688816',
        projectId: 'iparkfinder-d049e',
        storageBucket: 'iparkfinder-d049e',
      ),
    );
  } catch (e) {
    print('Firebase is already initialized: $e');
  }

  FirebaseAuth.instance.setLanguageCode('en');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions
  NotificationSettings settings = await messaging.requestPermission();
  print('User granted permission: ${settings.authorizationStatus}');

  // Get the FCM token
  String? fcmToken = await messaging.getToken();
  print("FCM Token: $fcmToken");

  runApp(MyApp(fcmToken: fcmToken));
}

class MyApp extends StatefulWidget {
  final String? fcmToken;

  MyApp({this.fcmToken});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Your app icon

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForNotifications() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      firestore.collection('Notifications')
          .where('uid', isEqualTo: user.uid)
          .where('sent', isEqualTo: false) // Check for unsent notifications
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            // Show the notification
            _showNotification(change.doc.data()!);
            // Optionally update the document to set sent to true
            change.doc.reference.update({'sent': true});
          }
        }
      });
    }
  }

  void _showNotification(Map<String, dynamic> notification) async {
    String title = notification['title'];
    String message = notification['message'];

    // Create a notification details object
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id', // Unique channel ID
      'your_channel_name', // Channel name
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      message,
      platformChannelSpecifics,
      payload: 'item x', // Optional payload
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(), // Keep the login page as the home widget
    );
  }
}
