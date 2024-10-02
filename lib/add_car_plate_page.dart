import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/services.dart'; // For TextInputFormatter

class AddCarPlateNumberPage extends StatefulWidget {
  @override
  _AddCarPlateNumberPageState createState() => _AddCarPlateNumberPageState();
}

class _AddCarPlateNumberPageState extends State<AddCarPlateNumberPage> {
  final TextEditingController _carPlateController = TextEditingController();
  final CollectionReference carPlateCollection =  FirebaseFirestore.instance.collection('CarPlateNumbers');

  // Get the current logged-in user's uid
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _carPlateController.dispose();
    super.dispose();
  }

  void _saveCarPlateNumber() {
    String carPlateNumber = _carPlateController.text.trim();

    if (carPlateNumber.isNotEmpty && userId != null) {
      // Close the add page immediately after the user presses save
      Navigator.pop(context, true);

      // Save to Firestore with the current user's uid
      carPlateCollection.add({
        'plateNumber': carPlateNumber,
        'userId': userId,
        'lock':false,
      }).then((value) {
        // Show a snack bar after the user has been redirected to the CarPlateNumberPage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Car Plate Number Added")),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add car plate number: $error")),
        );
      });
    } else {
      // Show validation error message and do not navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a car plate number")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Car Plate Number"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _carPlateController,
              // Adding input formatters to remove spaces and ensure uppercase
              inputFormatters: [
                UpperCaseTextFormatter(), // Custom formatter to enforce uppercase and remove spaces
              ],
              decoration: InputDecoration(
                labelText: "Enter Car Plate Number",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCarPlateNumber,
              child: Text("Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom TextInputFormatter to convert input to uppercase and remove spaces
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(' ', '').toUpperCase();

    // Keep the selection position intact
    int newOffset = newText.length;
    if (newText.length < oldValue.text.length) {
      newOffset = newText.length; // Adjust selection if text shrinks
    } else {
      newOffset = newText.length; // Move to end of text
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
