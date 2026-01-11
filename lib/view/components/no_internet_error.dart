import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';

import '../screens/webview_screens/home_screen.dart';

class NoInternetErrorScreen extends StatefulWidget {
  NoInternetErrorScreen();

  @override
  State<NoInternetErrorScreen> createState() => _NoInternetErrorScreenState();
}

class _NoInternetErrorScreenState extends State<NoInternetErrorScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F0E8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Headline
                Text(
                  'Not Connected to Wi-Fi',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf1bcb5),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // Body text
                Text(
                  'Please check your internet connection to continue.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),

                // Try Again Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFf1bcb5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
