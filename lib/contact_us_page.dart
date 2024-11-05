import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Import this for Clipboard

class ContactUsPage extends StatelessWidget {
  // Method to open phone dialer
  void _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Method to open email app
  void _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Method to copy email to clipboard
  void _copyToClipboard(String email) {
    Clipboard.setData(ClipboardData(text: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spacer to bring the title and back button lower
            SizedBox(height: 40),

            // Back button and Title
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Container(
                  padding: EdgeInsets.only(left: 80.0),
                  child: Text(
                    "Contact Us",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // AFM Label and Level
            Center(
              child: Column(
                children: [
                  Text(
                    "Admin & Facilities Management",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Level 2",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            // Helpdesk Section
            Row(
              children: [
                Icon(Icons.phone, color: Colors.purple),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _launchPhone("046310138"),
                    child: Text.rich(
                      TextSpan(
                        text: "Helpdesk:\n",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: "046310138",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey),

            // Email Section
            Row(
              children: [
                Icon(Icons.email, color: Colors.purple),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _launchEmail("_iicp.afm@newinti.edu.my"),
                    onLongPress: () {
                      _copyToClipboard("_iicp.afm@newinti.edu.my");
                      // Optionally show a snackbar to inform the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Email copied to clipboard!")),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Email:\n",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: "_iicp.afm@newinti.edu.my",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey),

            // Operating Hours Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time, color: Colors.purple),
                SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "Operation Hours:\n",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: "Monday to Friday\n8:00 AM to 6:00 PM\n*Except Public Holidays and Weekends",
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
