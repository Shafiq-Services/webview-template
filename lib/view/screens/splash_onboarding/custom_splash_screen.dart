import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_config.dart';
import '../../../utils/permissions.dart';
import '../webview_screens/home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

      // Request notification permission with delay during splash screen
      // This runs asynchronously and doesn't block the splash screen navigation
      _requestNotificationPermission();

      Timer(
        Duration(milliseconds: 2500),
            () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return HomeScreen();
            },
          ),
        ),
      );
    });

    super.initState();
  }

  /// Request notification permission with delay (non-blocking)
  void _requestNotificationPermission() async {
    try {
      // Request notification permission with a 2-second delay
      await requestNotificationPermissionWithDelay(delaySeconds: 2);
    } catch (e) {
      // Handle error silently to avoid disrupting app flow
      print('Error requesting notification permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff09ddae),
      body: Center(
        child: Image.asset('assets/app_icons/splash.png'),
      ),
    );
  }
}