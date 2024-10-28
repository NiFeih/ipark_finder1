import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isEmailSent = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Directly send the password reset email without checking if the email exists
      await _auth.sendPasswordResetEmail(email: email);
      setState(() {
        isEmailSent = true; // Update UI to reflect the email has been sent
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Firebase will handle non-existent users, show feedback to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No account found with this email. Please check and try again.")),
        );
      } else {
        print("Error sending password reset email: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send email. Try again later.")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong. Please try again later.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Set the color for the back button and other icons
        iconTheme: IconThemeData(color: Colors.purple), // Change back button color to purple
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 25), // Adjust top padding as needed
            child: Text(
              "Forgot Password",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Adjust the height of the AppBar if needed
        toolbarHeight: 80, // Change this to lower or raise the AppBar height
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEmailSent
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email, size: 80, color: Colors.purple),
              SizedBox(height: 20),
              Text(
                "A password reset email has been sent to ${emailController.text}. Please check your inbox.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // New text above the TextField
            Text(
              "Please enter your student email to reset your password.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), // Space between the text and TextField
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String email = emailController.text.trim();
                if (email.isNotEmpty) {
                  sendPasswordResetEmail(email);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter your email")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple, // Button background color
                foregroundColor: Colors.white, // Button text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Squarish button
                ),
              ),
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }




  @override
  void dispose() {
    emailController.dispose(); // Dispose of controller
    super.dispose();
  }
}
