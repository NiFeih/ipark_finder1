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
  final CollectionReference carPlateCollection = FirebaseFirestore.instance.collection('CarPlateNumbers');

  @override
  void dispose() {
    _carPlateController.dispose();
    super.dispose();
  }

  Future<void> _saveCarPlateNumber() async {
    String carPlateNumber = _carPlateController.text.trim();

    if (carPlateNumber.isNotEmpty) {
      // Check if the car plate number already exists in the database
      QuerySnapshot existingPlates = await carPlateCollection.where('plateNumber', isEqualTo: carPlateNumber).get();

      if (existingPlates.docs.isNotEmpty) {
        // Show validation error if the car plate number already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Car plate number already exists.")),
        );
        return;
      }

      // Close the add page immediately after the user presses save
      Navigator.pop(context, true);

      // Save to Firestore
      carPlateCollection.add({
        'plateNumber': carPlateNumber,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'lock': false,
      }).then((value) {
        // Show a snack bar after adding the car plate number
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Increased space to bring the title and back button lower
            SizedBox(height: 40), // Adjust this value as needed

            // Back button and Title
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // Title with padding to slightly shift to the left
                Container(
                  padding: EdgeInsets.only(left: 30.0), // Adjust the left padding as needed
                  child: Text(
                    "Add Car Plate Number",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40), // Additional space before the input field

            // Input field for car plate number
            TextField(
              controller: _carPlateController,
              // Adding input formatters to remove spaces and ensure uppercase
              inputFormatters: [
                UpperCaseTextFormatter(), // Custom formatter to enforce uppercase and remove spaces
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), // Allow both uppercase and lowercase letters and numbers
              ],
              decoration: InputDecoration(
                labelText: "Enter Car Plate Number",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCarPlateNumber,
              child: Text("Add", style: TextStyle(color: Colors.white)), // Change button text color to white
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(vertical: 14.0),
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
