import 'package:flutter/material.dart';
import 'register_page.dart';
import 'terms_conditions_text.dart'; // Import the new file

class TermsConditionsPage extends StatefulWidget {
  @override
  _TermsConditionsPageState createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    // Listen to the scroll controller to check if the user has scrolled to the bottom
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      // If at the bottom of the scroll, enable the button
      setState(() {
        _isButtonEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Spacer to move the content lower
            SizedBox(height: 40), // Adjust this value to position lower

            // Back button and Title
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.of(context).pop(), // Go back on press
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.only(left: 0.0), // Add left padding to shift left
                      child: Text(
                        "Terms & Conditions",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    termsAndConditions, // Use the imported text
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                }
                    : null, // Disabled if the user has not scrolled to the bottom
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  backgroundColor: _isButtonEnabled ? Colors.purple : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Accept and Continue",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
