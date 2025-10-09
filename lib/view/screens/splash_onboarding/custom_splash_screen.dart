import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/my_app_colors.dart';
import '../webview_screens/home_screen.dart';
// import '../../../utils/permissions.dart'; // ❌ Not needed
// import 'onboarding_screen.dart'; // ❌ Onboarding not needed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Direct navigation to HomeScreen (no onboarding)
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Timer(
        const Duration(milliseconds: 2500),
            () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        },
      );
    });

    // ❌ Removed notification permission request at startup
    // _requestNotificationPermission();
  }

  // ❌ Not needed anymore
  // void _requestNotificationPermission() async {
  //   try {
  //     await requestNotificationPermissionWithDelay(delaySeconds: 2);
  //   } catch (e) {
  //     print('Error requesting notification permission: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.konboardingBgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Splash image only
            Image.asset(
              'assets/app_icons/splash.png',
              height: 150.0,
              width: 150.0,
            ),

            // ❌ No app title or share button shown
            // const SizedBox(height: 20.0),
            // Text(
            //   Changes.AppTitle,
            //   style: TextStyle(
            //     fontSize: 24.0,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
