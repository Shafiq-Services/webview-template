import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/notification_service.dart';

void requestPermissions() async {
  try {
    await Permission.phone.request();
  } catch (e) {
    debugPrint('Error requesting phone permission: $e');
  }
}

Future<bool> requestNotificationPermissionWithDelay({int delaySeconds = 2}) async {
  try {
    await Future.delayed(Duration(seconds: delaySeconds));
    final granted = await NotificationService.requestNotificationPermission();
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

Future<bool> hasNotificationPermission() async {
  try {
    return await NotificationService.hasNotificationPermission();
  } catch (e) {
    debugPrint('Error checking notification permission: $e');
    return false;
  }
}

Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions) async {
  try {
    return await permissions.request();
  } catch (e) {
    debugPrint('Error requesting multiple permissions: $e');
    return {};
  }
}
