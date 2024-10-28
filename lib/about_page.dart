import 'package:flutter/material.dart';
import 'terms_conditions_text.dart'; // Import the terms and conditions text

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
            SizedBox(height: 40), // Additional space before the terms and conditions text

            // Display the terms and conditions text
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    termsAndConditions, // Use the imported terms and conditions text
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
