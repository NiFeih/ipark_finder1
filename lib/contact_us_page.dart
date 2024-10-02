import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contact Us"),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Text(
          "Contact Us Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
