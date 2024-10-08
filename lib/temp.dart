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

  // Function to send the email verification and wait for verification
  Future<void> sendEmailVerification(String email) async {
    try {
      // Check if email exists by fetching sign-in methods
      await _auth.fetchSignInMethodsForEmail(email).then((signInMethods) async {
        if (signInMethods.isEmpty) {
          throw FirebaseAuthException(code: 'user-not-found');
        }

        // Sign in the user anonymously or by some other means (you can modify based on your logic)
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: 'your-temporary-password');
        User? user = userCredential.user;

        if (user != null && !user.emailVerified) {
          // Send email verification
          await user.sendEmailVerification();

          setState(() {
            isEmailSent = true;
            isWaitingForVerification = true; // Start waiting for verification
          });

          // Check if email is verified periodically
          await _checkEmailVerified(user);
        }
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          isEmailValid = false; // Email doesn't exist
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No account found with this email. Please check and try again.")),
        );
      } else {
        print("Error sending verification email: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send verification email. Try again later.")),
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
                "A verification email has been sent to ${emailController.text}. Please check your inbox.",
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
                  sendEmailVerification(email);
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
