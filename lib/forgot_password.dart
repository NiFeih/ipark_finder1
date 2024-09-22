import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'reset_password.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isEmailSent = false;
  bool isEmailValid = true;
  bool isWaitingForVerification = false;
  late Timer emailVerificationTimer;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to send the password reset email and wait for verification
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Check if email is registered with email/password sign-in method
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.contains('password')) {
        // Email is valid and registered using email/password, proceed with password reset
        await _auth.sendPasswordResetEmail(email: email);
        setState(() {
          isEmailSent = true; // Change UI to reflect email has been sent
          isWaitingForVerification = true; // Start waiting for verification
        });
        // Optional: Call email verification check
        await _checkEmailVerified(_auth.currentUser!);
      } else {
        // If no sign-in methods or not using password authentication
        setState(() {
          isEmailValid = false; // Mark email as invalid
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No account found with this email. Please check and try again.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          isEmailValid = false; // Email doesn't exist
        });
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

  // Function to periodically check if the email is verified
  Future<void> _checkEmailVerified(User user) async {
    emailVerificationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await user.reload(); // Reload user state
      user = _auth.currentUser!;

      if (user.emailVerified) {
        timer.cancel(); // Stop the timer when email is verified
        setState(() {
          isWaitingForVerification = false; // Stop waiting for verification
        });

        // Navigate to the Reset Password page once email is verified
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordPage()),
        );
      }
    });
  }

  // Build the waiting screen for email verification
  Widget _buildVerificationWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.0),
          Text(
            "Waiting for email verification...",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          Text(
            "Please verify your email in your inbox.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWaitingForVerification
            ? _buildVerificationWaitingScreen() // Show waiting screen
            : isEmailSent
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
            Text(
              "Forgot Password",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                errorText: isEmailValid ? null : "Email not found",
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
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailVerificationTimer?.cancel(); // Ensure the timer is canceled
    emailController.dispose(); // Dispose of controller
    super.dispose();
  }
}
