import 'package:flutter/material.dart';

/// Basic app settings. Edit URLs, scheme, and `deliveryMilestone` per client delivery.
class AppConfig {
  static const int deliveryMilestone = 1;

  static const String appName = 'WebView App';
  static String mainUrl = 'https://galaxy2000ai-71288d7b.base44.app/';
  static String startPointUrl = 'https://galaxy2000ai-71288d7b.base44.app/';
  static String mediaFolderName = 'WebView App';

  static const String customScheme = 'myapp';
  static const List<String> deepLinkDomains = [
    'galaxy2000ai-71288d7b.base44.app',
  ];

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sha.innosphere';
  static const String appStoreUrl = 'https://apps.apple.com/app/id0000000000';

  static String oneSignalAppId = '761f1b58-0317-42a1-a0d5-aac3fcecd870';

  /// M4: POST endpoint for “public share link” (optional). Empty = do not inject recipe-share JS.
  static String shareRecipeApiUrl = '';

  static const Color primaryColor = Color.fromARGB(255, 26, 26, 26);
  static const Color mainColor = Color.fromARGB(255, 123, 175, 212);
  static const Color secondaryColor = Color.fromARGB(255, 255, 255, 255);
  static const Color onboardingBgColor = Color(0xff2f1361);
}

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
