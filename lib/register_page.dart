import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:async'; // For Timer
import 'package:flutter/services.dart'; // For TextInputFormatter

// Custom TextInputFormatter to remove spaces and convert to uppercase
class CarPlateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove spaces and convert to uppercase
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
  bool isWaitingForVerification = false;

  Future<void> handleRegister() async {
    String name = nameController.text.trim();
    String contact = contactController.text.trim();
    String carPlate = carPlateController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || contact.isEmpty || carPlate.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Please fill out all fields"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else if (password != confirmPassword) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Passwords do not match"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else {
      try {
        // Register the user with Firebase Authentication
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Send a verification email
        User? user = userCredential.user;
        await user?.sendEmailVerification();

        // Indicate that we are waiting for email verification
        setState(() {
          isWaitingForVerification = true;
        });

        // Start checking periodically if the user has verified their email
        _checkEmailVerified(user!, name, contact, carPlate, email);

      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _checkEmailVerified(User user, String name, String contact, String carPlate, String email) async {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      await user.reload(); // Reload user state
      user = _auth.currentUser!;

      if (user.emailVerified) {
        timer.cancel(); // Stop the timer
        setState(() {
          isWaitingForVerification = false;
        });

        // Save user details to Firestore after email is verified
        DocumentReference userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
        await userRef.set({
          'name': name,
          'contact': contact,
          'email': email,
          'uid': user.uid,
        });

        // Add the car plate number to the CarPlateNumbers collection (top-level collection)
        await FirebaseFirestore.instance.collection('CarPlateNumbers').add({
          'plateNumber': carPlate,
          'userId': user.uid, // Link the car plate to the user
        });

        // Show success dialog and navigate to login page
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Success"),
            content: Text("Email verified! Your account has been successfully registered."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog

                  // Navigate to the LoginPage using pushReplacement
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Register",
          style: TextStyle(color: Colors.purple),
        ),
        centerTitle: true,
      ),
      body: isWaitingForVerification
          ? _buildVerificationWaitingScreen()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              _buildTextField(nameController, "Full Name", Icons.person),
              SizedBox(height: 16.0),
              _buildTextField(contactController, "Contact Number", Icons.phone, keyboardType: TextInputType.phone),
              SizedBox(height: 16.0),
              _buildTextField(carPlateController, "Car Plate Number", Icons.directions_car),
              SizedBox(height: 16.0),
              _buildTextField(emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
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
                  child: Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      inputFormatters: labelText == "Contact Number"
          ? [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // Allow only numbers for contact number
        FilteringTextInputFormatter.digitsOnly,
      ]
          : labelText == "Car Plate Number"
          ? [
        CarPlateInputFormatter(), // Apply the custom formatter to car plate number
      ]
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
