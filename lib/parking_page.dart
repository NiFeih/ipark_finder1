import 'package:flutter/material.dart';

class ParkingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Parking"),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Parking Page - Display Parking Information Here",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            // Add your parking-related widgets here, e.g., parking lot map
          ],
        ),
      ),
    );
  }
}
