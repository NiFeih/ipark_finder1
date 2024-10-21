import 'package:flutter/material.dart';
import 'parking_page.dart';  // Import the Parking Page
import 'contact_page.dart';  // Import the Contact Page
import 'inbox_page.dart';    // Import the Inbox Page
import 'settings_page.dart'; // Import the Settings Page

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    ParkingPage(),   // Parking page is the default home page
    ContactPage(),
    InboxPage(),     // The newly replaced Inbox Page
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.local_parking),
            label: 'Parking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_phone),
            label: 'Contact',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),  // Updated icon for Inbox
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,  // Highlight the selected item with purple
        unselectedItemColor: Colors.grey,  // Set the unselected items to light gray
        onTap: _onItemTapped,  // Handle the tap event
        showUnselectedLabels: true,  // Show labels for unselected items
        type: BottomNavigationBarType.fixed,  // Ensure labels are shown for unselected items
      ),
    );
  }
}