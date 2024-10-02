import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About IICP Park Finder"),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Text(
          "About IICP Park Finder",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
