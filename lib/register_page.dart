import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:async'; // For Timer
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'verification_waiting_page.dart'; // Import the new verification waiting page

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(' ', '').toUpperCase();
    int newOffset = newText.length;
    if (newText.length < oldValue.text.length) {
      newOffset = newText.length;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class CarPlateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(' ', '').toUpperCase();
    return TextEditingValue(
      text: newText,
      selection: newValue.selection.copyWith(
        baseOffset: newText.length,
        extentOffset: newText.length,
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController carPlateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Timer? _verificationTimer; // Timer for email verification expiration

  Future<void> handleRegister() async {
    String name = nameController.text.trim();
    String contact = contactController.text.trim();
    String carPlate = carPlateController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // Validation
    if (name.isEmpty || contact.isEmpty || carPlate.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showDialog("Error", "Please fill out all fields");
      return;
    } else if (password != confirmPassword) {
      _showDialog("Error", "Passwords do not match");
      return;
    } else if (!email.endsWith('@student.newinti.edu.my')) {
      _showDialog("Error", "Please use a valid student email address.");
      return; // Exit the function if the email is not valid
    }

    // Extract student ID from the email
    String studentID = email.split('@')[0];

    try {
      // Check if the car plate number already exists in Firestore
      QuerySnapshot existingCarPlates = await FirebaseFirestore.instance
          .collection('CarPlateNumbers')
          .where('plateNumber', isEqualTo: carPlate)
          .get();

      if (existingCarPlates.docs.isNotEmpty) {
        // Show error if the car plate number already exists
        _showDialog("Error", "This car plate number already exists.");
        return;
      }

      // Register the user with Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send a verification email
      User? user = userCredential.user;
      await user?.sendEmailVerification();

      // Navigate to VerificationWaitingPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerificationWaitingPage()),
      );

      // Start the timer for 5 minutes
      _verificationTimer = Timer(Duration(minutes: 5), () async {
        await user?.delete(); // Delete the user if not verified
        _showDialog("Timeout", "Your email verification link has expired. Please register again.");
      });

      // Start checking periodically if the user has verified their email
      _checkEmailVerified(user!, name, contact, carPlate, email, studentID);
    } catch (e) {
      _showDialog("Error", e.toString());
    }
  }


  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkEmailVerified(User user, String name, String contact, String carPlate, String email, String studentID) async {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      await user.reload(); // Reload user state
      user = _auth.currentUser!; // Get the updated user

      if (user.emailVerified) {
        timer.cancel(); // Stop the timer
        _verificationTimer?.cancel(); // Cancel the verification timer

        // Save user details to Firestore after email is verified
        DocumentReference userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
        await userRef.set({
          'name': name,
          'contact': contact,
          'email': email,
          'uid': user.uid,
          'studentID': studentID, // Add the studentID
          'role': 'student', // Add role
        });

        // Add the car plate number to the CarPlateNumbers collection
        await FirebaseFirestore.instance.collection('CarPlateNumbers').add({
          'plateNumber': carPlate,
          'userId': user.uid,
          'lock': false,
        });

        // Show success dialog
        _showDialog("Success", "Email verified! Your account has been successfully registered. Please wait while we navigate you to the login page");

        // Navigate to the login page after successful registration
        Future.delayed(Duration(seconds: 5), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage using pushReplacement
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [

              SizedBox(height: 40), // Increased spacer for lower positioning
              // Back button and Title
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.purple),
                    onPressed: () => Navigator.of(context).pop(), // Go back on press
                  ),
                  // Container for left padding on the title
                  Container(
                    padding: EdgeInsets.only(left: 100.0), // Slight left padding
                    child: Text(
                      "Register",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40), // Spacer to move the content lower
              _buildTextField(nameController, "Full Name", Icons.person, r'[A-Za-z ]'),
              SizedBox(height: 16.0),
              _buildTextField(contactController, "Contact Number", Icons.phone, r'[0-9]', keyboardType: TextInputType.phone),
              SizedBox(height: 16.0),
              _buildTextField(carPlateController, "Car Plate Number", Icons.directions_car, r'[A-Za-z0-9]'),
              SizedBox(height: 16.0),
              _buildTextField(emailController, "Email", Icons.email, ''),
              SizedBox(height: 16.0),
              _buildPasswordField(passwordController, "Password", _passwordVisible, () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              }),
              SizedBox(height: 16.0),
              _buildPasswordField(confirmPasswordController, "Confirm Password", _confirmPasswordVisible, () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              }),
              SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleRegister,
                  child: Text("Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, String allowedChars, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      inputFormatters: allowedChars.isNotEmpty
          ? [FilteringTextInputFormatter.allow(RegExp(allowedChars)), if (labelText == "Car Plate Number") CarPlateInputFormatter()]
          : [],
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String labelText, bool isVisible, VoidCallback toggleVisibility) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
