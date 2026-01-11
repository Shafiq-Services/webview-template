import 'package:flutter/material.dart';

/// 📱 APP CONFIG - Basic app settings
class AppConfig {
  // Basic Settings
  static const String appName = 'PAIR - Long Distance Dating';
  static String mainUrl = 'https://convo-connect-6fcd3499.base44.app/';
  static String startPointUrl = 'https://convo-connect-6fcd3499.base44.app/';
  static String mediaFolderName = 'PAIR';
  
  // OneSignal
  static String oneSignalAppId = '666fc920-be76-4409-9584-c6abcfe26c5e';
  
  // Colors
  static const Color primaryColor = Color.fromARGB(255, 255, 255, 255);
  static const Color mainColor = Color.fromARGB(255, 255, 255, 255);
  static const Color secondaryColor = Color.fromARGB(255, 0, 0, 0);
  static const Color onboardingBgColor = Color(0xff2f1361);
}

// Backwards compatibility
class Changes {
  static String get mainUrl => AppConfig.mainUrl;
  static set mainUrl(String value) => AppConfig.mainUrl = value;
  static String get startPointUrl => AppConfig.startPointUrl;
  static set startPointUrl(String value) => AppConfig.startPointUrl = value;
  static String get AppTitle => AppConfig.appName;
  static String get androidMediaStoreFolderName => AppConfig.mediaFolderName;
  static String get oneSignalAppId => AppConfig.oneSignalAppId;
}

class MyColors {
  static const kprimaryColor = AppConfig.primaryColor;
  static const kmainColor = AppConfig.mainColor;
  static const ksecondaryColor = AppConfig.secondaryColor;
  static const konboardingBgColor = AppConfig.onboardingBgColor;
}
