import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'account_page.dart';
import 'about_page.dart';
import 'contact_us_page.dart';
import 'change_password_page.dart';
import 'car_plate_number_page.dart'; // Import the car plate number page
import 'login_page.dart'; // Import your LoginPage

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Title centered at the top
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 16.0), // Add some padding at the top
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 32, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      "Profile",
                      style: TextStyle(fontSize: 18), // Increased font size
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.purple, // Change icon color to purple
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                  ),
                  Divider(), // Add a divider between items
                  ListTile(
                    title: Text(
                      "Change Password",
                      style: TextStyle(fontSize: 18), // Increased font size
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.purple, // Change icon color to purple
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text(
                      "Car Plate Number",
                      style: TextStyle(fontSize: 18), // Increased font size
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.purple, // Change icon color to purple
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CarPlateNumberPage()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text(
                      "Contact Us",
                      style: TextStyle(fontSize: 18), // Increased font size
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.purple, // Change icon color to purple
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ContactUsPage()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text(
                      "About IICP Park Finder",
                      style: TextStyle(fontSize: 18), // Increased font size
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.purple, // Change icon color to purple
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutPage()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text(
                      "Log Out",
                      style: TextStyle(fontSize: 18), // Increased font size
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.purple, // Change icon color to purple
                    ),
                    onTap: () {
                      _confirmLogout(context); // Call the logout confirmation
                    },
                  ),
                  Divider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Log Out"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _logout(context); // Call the logout function
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Change to your LoginPage widget
    );
  }
}
