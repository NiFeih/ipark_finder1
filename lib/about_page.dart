import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Spacer to bring the title and back button lower
            SizedBox(height: 40), // Adjust this value to position the title lower

            // Back button and Title
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.of(context).pop(), // Go back on press
                ),
                Container(
                  padding: EdgeInsets.only(left: 20.0), // Adjust the left padding as needed
                  child: Text(
                    "About IICP Park Finder",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40), // Additional space before the about information

            // Center the about text
            Center(
              child: Text(
                "About IICP Park Finder",
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
