import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Variable to control password visibility
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Re-authenticate the user
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );

        await user.reauthenticateWithCredential(credential); // Re-authenticate
        await user.updatePassword(newPassword); // Change password
        print("Password changed successfully.");
        return true; // Indicate success
      } catch (e) {
        print("Error changing password: $e");

        // Dismiss the loading indicator
        Navigator.of(context).pop();

        // Show error message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text("Old password is incorrect. Please try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
        return false; // Indicate failure
      }
    }
    return false; // In case user is null
  }

  void handleChangePassword() async {
    String oldPassword = oldPasswordController.text.trim();
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Please fill out all fields."),
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
      return;
    }

    if (newPassword.length < 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("New password must be at least 6 characters."),
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
      return;
    }

    if (newPassword != confirmPassword) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("New password and confirm password do not match."),
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
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Attempt to change password
    bool success = await changePassword(oldPassword, newPassword);

    if (success) {
      // Dismiss the loading indicator
      Navigator.of(context).pop();

      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Success"),
          content: Text("Password changed successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Navigate back to previous page
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Back button and Title
            SizedBox(height: 40), // Spacer to move the back button and title lower
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.of(context).pop(), // Go back on press
                ),
                // Title with padding to slightly shift to the left
                Container(
                  padding: EdgeInsets.only(left: 50.0), // Adjust the left padding as needed
                  child: Text(
                    "Change Password",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40), // Additional spacer

            // Password fields
            TextField(
              controller: oldPasswordController,
              decoration: InputDecoration(
                labelText: "Old Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _oldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _oldPasswordVisible = !_oldPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_oldPasswordVisible,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _newPasswordVisible = !_newPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_newPasswordVisible,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_confirmPasswordVisible,
            ),
            SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity, // Increase the width of the button
              child: ElevatedButton(
                onPressed: handleChangePassword,
                child: Text("Change Password", style: TextStyle(color: Colors.white)), // Change button text color to white
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
    );
  }
}
