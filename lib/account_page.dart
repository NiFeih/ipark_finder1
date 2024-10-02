import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account"),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Text(
          "Account Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
