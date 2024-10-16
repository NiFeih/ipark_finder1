import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationWaitingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verification"),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => _showConfirmationDialog(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.0),
            Center(
              child: Text(
                "The verification link has been sent to \n your student email. \n Please verify your email.",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Exit"),
        content: Text("Are you sure you want to exit the verification screen? This will delete your account."),
        actions: [
          TextButton(
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;

              if (user != null) {
                try {
                  await user.delete(); // Delete user account
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Pop the current page
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete account: $e")),
                  );
                }
              } else {
                Navigator.of(context).pop(); // If no user, just pop
                Navigator.of(context).pop(); // Pop the current page
              }
            },
            child: Text("Yes"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Just close the dialog
            child: Text("No"),
          ),
        ],
      ),
    );
  }
}
