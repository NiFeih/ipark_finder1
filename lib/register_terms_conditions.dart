import 'package:flutter/material.dart';
import 'register_page.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "TNC",
          style: TextStyle(color: Colors.purple),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              "Terms & Conditions",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
                    // Sample Terms and Conditions text
                    '''
Terms and Conditions for IICP Park Finder

Effective Date: [Insert Date]

Welcome to IICP Park Finder! By registering and using our app, you agree to comply with and be bound by the following terms and conditions.

1. Acceptance of Terms
By registering for and using IICP Park Finder, you acknowledge that you have read, understood, and agree to be bound by these terms and conditions, as well as any applicable laws and regulations.

2. User Responsibilities
When registering for IICP Park Finder, you agree to provide accurate and complete information, including but not limited to your name, email, phone number, and vehicle plate number. You are responsible for maintaining the security of your account and for any activities that occur under your account.

3. Data Collection and Use
By using IICP Park Finder, you consent to the collection and use of the following personal information:

Location Data: Used to provide relevant parking lot availability based on your current location.
Vehicle Plate Number: Collected to identify your vehicle in relation to parking spaces.
Email and Phone Number: Used for account creation, authentication, and communication purposes.
Password: Used for secure access to your account.
We will only use this information in accordance with our [Privacy Policy], and we will not share your personal data with third parties except as required by law or for the purposes of providing app services.

4. Third-Party Services
IICP Park Finder uses the Woosmap API to enhance our location-based services. By using the app, you agree to Woosmap’s terms and conditions and privacy policy. We are not responsible for any issues that arise from the use of third-party services.

5. Camera Access
IICP Park Finder does not require access to your device's camera. All vehicle detection is handled via external cameras in the parking lot.

6. Payment Terms
IICP Park Finder is provided free of charge, and no payment is required for using the app. We do not offer any in-app purchases or premium features at this time.

7. Privacy Policy
Your privacy is important to us. Please review our [Privacy Policy] to understand how we collect, use, and protect your information. By using IICP Park Finder, you consent to our data collection practices as outlined in the Privacy Policy.

8. Accuracy of Information
While IICP Park Finder strives to provide accurate and up-to-date information regarding parking availability, we do not guarantee the accuracy or reliability of the parking data displayed in the app. The availability of parking spaces may change due to unforeseen circumstances.

9. Disclaimer of Warranties
IICP Park Finder is provided "as-is" without any warranties, either expressed or implied, including but not limited to accuracy, fitness for a particular purpose, or non-infringement. We do not guarantee the uninterrupted or error-free operation of the app.

10. Limitation of Liability
In no event shall IICP Park Finder, its developers, or affiliates be liable for any indirect, incidental, special, or consequential damages arising from your use of the app, including but not limited to damages for loss of data, accuracy of information, or parking availability.

11. User Conduct
You agree not to use IICP Park Finder:

To provide false information or impersonate others.
To upload or share any unlawful, harmful, or offensive content.
In any way that may disrupt the services provided by IICP Park Finder or the experience of other users.
To engage in any activity that violates Malaysian laws or regulations.
12. Changes to the Terms
We reserve the right to modify these terms and conditions at any time. Any changes will be posted within the app, and continued use after the posting of changes constitutes your acceptance of the updated terms.

13. Termination of Use
We may terminate your access to IICP Park Finder at any time for any reason, including but not limited to your violation of these terms and conditions or applicable laws.

14. Governing Law
These terms shall be governed by and construed in accordance with the laws of Malaysia, without regard to its conflict of law provisions.''',
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
