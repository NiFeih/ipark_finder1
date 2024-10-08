import 'package:flutter/material.dart';
import 'account_page.dart';
import 'about_page.dart';
import 'contact_us_page.dart';
import 'change_password_page.dart';
import 'car_plate_number_page.dart'; // Import the car plate number page

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.purple, // Set the app bar color
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text("Profile"),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          Divider(), // Add a divider between items
          ListTile(
            title: Text("Change Password"),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text("Car Plate Number"),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CarPlateNumberPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text("Contact Us"),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactUsPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text("About IICP Park Finder"),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            },
          ),

          Divider(),
          ListTile(
            title: Text("Log Out"),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Action will be added later
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}
