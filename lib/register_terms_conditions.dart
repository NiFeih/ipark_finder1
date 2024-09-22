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
                    '''Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus imperdiet, nulla et dictum interdum, nisi lorem egestas odio, vitae scelerisque enim ligula venenatis dolor. Maecenas nisl est, ultrices nec congue eget, auctor vitae massa. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla facilisi. Nullam vehicula, arcu a facilisis malesuada, dui ligula vehicula metus, id pharetra sapien orci eu magna.

                    Integer lacinia mi orci, in finibus velit sodales eu. Duis bibendum interdum venenatis. Nam sit amet eros et ligula scelerisque vehicula. Etiam nec eros dapibus, ultricies mauris ac, fermentum velit. Etiam aliquet nisl ut efficitur congue. Curabitur tempus at nisl vitae lacinia. Aenean iaculis massa in risus convallis, ut convallis lectus eleifend. Nulla luctus neque id magna sollicitudin, nec sagittis metus fringilla.

                    Praesent ac sapien interdum, venenatis ex et, ullamcorper elit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nullam fermentum vehicula neque, nec pellentesque ligula fringilla ac. In non mi non nisi feugiat rutrum. Ut sollicitudin nibh nec lectus ultrices, ac consectetur eros dignissim. Donec ac consequat sapien. Nulla sit amet turpis orci. Nullam vitae metus et libero gravida sodales non eget ligula.

                    Vestibulum euismod, mauris et consectetur aliquet, massa est consequat orci, id auctor mauris nisi quis est. Mauris venenatis urna ut leo aliquam tristique. Nullam mollis efficitur ligula, sit amet egestas sem condimentum sit amet. Etiam volutpat nulla nec ipsum condimentum, at viverra velit auctor. Ut quis tortor dolor. Nullam tempus urna at arcu posuere laoreet. Phasellus euismod lorem vel fringilla varius.''',
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
