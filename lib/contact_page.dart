import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class ContactPage extends StatefulWidget {
  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController carPlateController = TextEditingController();
  bool showPlateNumber = false; // Toggle state for showing car plate numbers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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

            // Toggle Switch for showing plate number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Show my plate number",
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: showPlateNumber,
                  onChanged: (value) {
                    setState(() {
                      showPlateNumber = value; // Update the toggle state
                    });
                    // Optionally, update the Firestore document here
                    _updateShowPlateNumber(value);
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // Text Field for car plate number
            TextField(
              controller: carPlateController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter car plate number',
              ),
              onChanged: (value) {
                // Convert to uppercase and remove invalid characters
                String formattedValue = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
                carPlateController.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(offset: formattedValue.length), // Keep the cursor at the end
                );
              },
            ),
            SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
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

  // Update the Firestore document for showing plate number
  Future<void> _updateShowPlateNumber(bool value) async {
    // Get the current user's ID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Update the 'show' field in Firestore
    await FirebaseFirestore.instance
        .collection('CarPlateNumbers')
        .where('userId', isEqualTo: uid) // Ensure you are updating the correct document
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'show': value});
      }
    });
  }

  Future<void> _findOwnerContact(String carPlateNumber, BuildContext context) async {
    try {
      // Query the CarPlateNumbers collection to find the car plate
      QuerySnapshot carPlateQuerySnapshot = await FirebaseFirestore.instance
          .collection('CarPlateNumbers')
          .where('plateNumber', isEqualTo: carPlateNumber)
          .where('show', isEqualTo: true) // Only get documents where show is true
          .get();

      if (carPlateQuerySnapshot.docs.isNotEmpty) {
        DocumentSnapshot carPlateDoc = carPlateQuerySnapshot.docs.first;
        String userId = carPlateDoc['userId'];

        // Fetch the user details from the Users collection using the userId
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

        if (userSnapshot.exists) {
          String ownerContact = userSnapshot['contact'] ?? 'No contact info available';
          _showCallDialog(context, ownerContact); // Show the contact info dialog
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

  // Show a dialog to call the owner's phone number
  void _showCallDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Contact Info"),
        content: Text("Phone Number: $phoneNumber"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Attempt to launch the phone dialer
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: phoneNumber,
              );
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              } else {
                _showDialog(context, "Error", "Could not launch dialer.");
              }
            },
            child: Text("Call"),
          ),
        ],
      ),
    );
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
