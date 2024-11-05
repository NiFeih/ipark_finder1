import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for the database
import 'package:flutter/services.dart';


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance; // Firestore instance

  // Controllers for editing user details
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  FocusNode nameFocusNode = FocusNode();
  FocusNode phoneFocusNode = FocusNode();

  bool isEditingName = false;
  bool isEditingPhone = false;
  bool showSaveCancelButtons = false;

  String originalName = "";
  String originalPhone = "";

  @override
  void initState() {
    super.initState();
    getUserProfile(); // Fetch user profile data when the widget initializes
  }

  // Fetch user data from Firestore
  Future<void> getUserProfile() async {
    User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          originalName = userDoc['name'];
          originalPhone = userDoc['contact'];
          nameController.text = originalName;
          emailController.text = user.email!;
          phoneController.text = originalPhone;
        });
      }
    }
  }

  // Update user profile data in Firestore
  Future<void> updateUserProfile() async {
    User? user = auth.currentUser;
    if (user != null) {
      await firestore.collection('Users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'contact': phoneController.text.trim(),
      });
    }
  }

  // Cancel the edit and restore original values
  void cancelEdit() {
    setState(() {
      nameController.text = originalName;
      phoneController.text = originalPhone;
      isEditingName = false;
      isEditingPhone = false;
      showSaveCancelButtons = false;
    });
  }

  // Save changes made to the profile
  void saveChanges() {
    updateUserProfile();
    setState(() {
      originalName = nameController.text.trim();
      originalPhone = phoneController.text.trim();
      isEditingName = false;
      isEditingPhone = false;
      showSaveCancelButtons = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 40), // Spacer to move the back button and title lower

            // Back button
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Container(
                  padding: EdgeInsets.only(left: 100.0),
                  child: Text(
                    "Profile",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40), // Additional spacer

            // Display Name with Edit Icon
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(fontSize: 20),
                      border: InputBorder.none,
                    ),
                    readOnly: !isEditingName,
                  ),
                ),
                IconButton(
                  icon: Icon(isEditingName ? Icons.check : Icons.edit),
                  onPressed: () {
                    setState(() {
                      isEditingName = !isEditingName;
                      if (isEditingName) {
                        nameFocusNode.requestFocus();
                      } else {
                        nameFocusNode.unfocus();
                        updateUserProfile();
                      }
                      showSaveCancelButtons = isEditingName || isEditingPhone;
                    });
                  },
                ),
              ],
            ),
            Divider(),

            // Display Email (Email should not be editable)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(fontSize: 20),
                      border: InputBorder.none,
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            Divider(),

            // Display Phone Number with Edit Icon
            // Display Phone Number with Edit Icon
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    focusNode: phoneFocusNode,
                    keyboardType: TextInputType.number, // Set keyboard to numeric
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly // Allow only digits
                    ],
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(fontSize: 20),
                      border: InputBorder.none,
                    ),
                    readOnly: !isEditingPhone,
                  ),
                ),
                IconButton(
                  icon: Icon(isEditingPhone ? Icons.check : Icons.edit),
                  onPressed: () {
                    setState(() {
                      isEditingPhone = !isEditingPhone;
                      if (isEditingPhone) {
                        phoneFocusNode.requestFocus();
                      } else {
                        phoneFocusNode.unfocus();
                        updateUserProfile();
                      }
                      showSaveCancelButtons = isEditingName || isEditingPhone;
                    });
                  },
                ),
              ],
            ),
            Divider(),


            // Show Save and Cancel buttons when editing
            if (showSaveCancelButtons) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: cancelEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text("Save"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
