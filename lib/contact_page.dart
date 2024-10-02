import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  final TextEditingController carPlateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding for the entire page
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Title
            Text(
              "Contact",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Instructional text
            Text(
              "Someone’s car blocking you?\nType the car plate number below to contact them!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 40),

            // Text Field for car plate number
            TextField(
              controller: carPlateController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter car plate number',
              ),
            ),
            SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity, // Full width button
              child: ElevatedButton(
                onPressed: () {
                  String carPlate = carPlateController.text.trim();
                  if (carPlate.isNotEmpty) {
                    _findOwnerContact(carPlate, context); // Call the function to find the contact
                  } else {
                    _showDialog(context, "Error", "Please enter a valid car plate number.");
                  }
                },
                child: Text(
                  "Submit",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple, // Button color
                  padding: EdgeInsets.symmetric(vertical: 14), // Button padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _findOwnerContact(String carPlateNumber, BuildContext context) async {
    try {
      // Query the CarPlateNumbers collection to find the car plate
      QuerySnapshot carPlateQuerySnapshot = await FirebaseFirestore.instance
          .collection('CarPlateNumbers') // Query the top-level CarPlateNumbers collection
          .where('plateNumber', isEqualTo: carPlateNumber)
          .get();

      if (carPlateQuerySnapshot.docs.isNotEmpty) {
        // Get the first result (you can adjust this if multiple matches are possible)
        DocumentSnapshot carPlateDoc = carPlateQuerySnapshot.docs.first;

        // Extract the userId from the car plate document
        String userId = carPlateDoc['userId'];

        // Fetch the user details from the Users collection using the userId
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

        if (userSnapshot.exists) {
          String ownerContact = userSnapshot['contact'] ?? 'No contact info available';

          // Show the contact info in a dialog
          _showDialog(context, "Contact Info", "Phone Number: $ownerContact");
        } else {
          _showDialog(context, "Error", "User not found for the given car plate number.");
        }
      } else {
        _showDialog(context, "Error", "No user found for car plate number: $carPlateNumber.");
      }
    } catch (e) {
      _showDialog(context, "Error", "Something went wrong: ${e.toString()}");
    }
  }


  // Helper function to show dialog
  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}
