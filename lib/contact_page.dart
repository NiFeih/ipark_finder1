import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController carPlateController = TextEditingController();
  bool showPlateNumber = false;

  @override
  void initState() {
    super.initState();
    _loadShowPlateNumber(); // Load the show value from Firestore when the page loads
  }

  Future<void> _loadShowPlateNumber() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user's show value from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        setState(() {
          showPlateNumber = userSnapshot['show'] ?? false;
        });
      }
    } catch (e) {
      print("Error loading showPlateNumber: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 40),
              Text(
                "Contact",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 80),
              Text(
                "Show your plate number if you double park \nso that people can find you!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      "Show my plate number",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Switch(
                      value: showPlateNumber,
                      onChanged: (value) {
                        setState(() {
                          showPlateNumber = value;
                        });
                        _updateShowPlateNumber(value);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),
              Text(
                "Someone’s car blocking you?\nType the car plate number below to contact them!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: carPlateController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter car plate number',
                ),
                onChanged: (value) {
                  String formattedValue = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
                  carPlateController.value = TextEditingValue(
                    text: formattedValue,
                    selection: TextSelection.collapsed(offset: formattedValue.length),
                  );
                },
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String carPlate = carPlateController.text.trim();
                    if (carPlate.isNotEmpty) {
                      _findOwnerContact(carPlate, context);
                    } else {
                      _showDialog(context, "Error", "Please enter a valid car plate number.");
                    }
                  },
                  child: Text(
                    "Submit",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateShowPlateNumber(bool value) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Update the 'show' field in the 'Users' document
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .update({'show': value});
  }

  Future<void> _findOwnerContact(String carPlateNumber, BuildContext context) async {
    try {
      // Query the CarPlateNumbers collection to find the car plate
      QuerySnapshot carPlateQuerySnapshot = await FirebaseFirestore.instance
          .collection('CarPlateNumbers')
          .where('plateNumber', isEqualTo: carPlateNumber)
          .get();

      if (carPlateQuerySnapshot.docs.isNotEmpty) {
        DocumentSnapshot carPlateDoc = carPlateQuerySnapshot.docs.first;
        String userId = carPlateDoc['userId'];

        // Fetch the user details from the Users collection using the userId and check if show is true
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

        if (userSnapshot.exists && userSnapshot['show'] == true) {
          String ownerContact = userSnapshot['contact'] ?? 'No contact info available';
          _showCallDialog(context, ownerContact);
        } else {
          _showDialog(context, "Error", "User does not have their contact info visible.");
        }
      } else {
        _showDialog(context, "Error", "No user found for car plate number: $carPlateNumber.");
      }
    } catch (e) {
      _showDialog(context, "Error", "Something went wrong: ${e.toString()}");
    }
  }

  void _showCallDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Contact Info"),
        content: Text("Phone Number: $phoneNumber"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
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
