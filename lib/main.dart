import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Ensure login.dart is correctly imported

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyCSyYjfCZvkc0K4Ai1L4heQH4zw7MtGsaY',
      appId: '1:55426688816:android:6876cdb5e5e898e387caf5',
      messagingSenderId: '55426688816',
      projectId: 'iparkfinder-d049e',
      storageBucket: 'iparkfinder-d049e.appspot.com',
    ),
  );
  // Set locale for Firebase Authentication
  FirebaseAuth.instance.setLanguageCode('en');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),  // Set LoginPage as the home widget
    );
  }
}
