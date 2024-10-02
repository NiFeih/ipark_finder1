import 'package:flutter/material.dart';

class ChangePasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Password"),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Text(
          "Change Password Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
