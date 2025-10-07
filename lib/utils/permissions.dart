import 'package:permission_handler/permission_handler.dart';
import 'package:webview_demo/services/one_signal_notification.dart';
import 'package:flutter/foundation.dart';

/// Request basic permissions needed by the app
void requestPermissions() async {
  try {
    await Permission.phone.request();
  } catch (e) {
    debugPrint('Error requesting phone permission: $e');
  }

  // Additional permissions can be requested here
  // Map<Permission, PermissionStatus> statuses = await [
  //   Permission.camera,
  //   Permission.storage,
  //   Permission.microphone,
  //   Permission.phone,
  // ].request();
  // if (statuses[Permission.camera]!.isGranted &&
  //     statuses[Permission.storage]!.isGranted &&
  //     statuses[Permission.microphone]!.isGranted &&
  //     statuses[Permission.phone]!.isGranted) {
  //   // All permissions granted, proceed with the functionality.
  //   print('All permissions granted!');
  // } else {
  //   // Permissions not granted, handle accordingly.
  //   print('Some or all permissions not granted!');
  // }
}

/// Request notification permission via OneSignal with delay
Future<bool> requestNotificationPermissionWithDelay({int delaySeconds = 2}) async {
  try {
    // Wait for specified delay before requesting notification permission
    await Future.delayed(Duration(seconds: delaySeconds));
    
    // Request notification permission through OneSignal
    final granted = await OneSignalNotification.requestNotificationPermission();
    
    if (granted) {
      debugPrint('Notification permission granted');
    } else {
      debugPrint('Notification permission denied');
    }
    
    return granted;
  } catch (e) {
    debugPrint('Error requesting notification permission: $e');
    return false;
  }
}

/// Check if notification permission is granted
Future<bool> hasNotificationPermission() async {
  try {
    return await OneSignalNotification.hasNotificationPermission();
  } catch (e) {
    debugPrint('Error checking notification permission: $e');
    return false;
  }
}

/// Request multiple permissions at once
Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(List<Permission> permissions) async {
  try {
    final statuses = await permissions.request();
    return statuses;
  } catch (e) {
    debugPrint('Error requesting multiple permissions: $e');
    return {};
  }
}
