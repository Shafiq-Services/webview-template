import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/notification_model.dart';

/// Complete notification service: OneSignal + Local storage
class NotificationService {
  static const String _notificationsKey = 'notifications';
  static bool _isInitialized = false;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ONESIGNAL METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Initialize OneSignal with error handling
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        debugPrint('OneSignal already initialized');
        return;
      }

      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      }

      OneSignal.initialize(Changes.oneSignalAppId);
      OneSignal.LiveActivities.setupDefault();
      _setupNotificationListeners();
      
      _isInitialized = true;
      debugPrint('OneSignal initialized successfully');
      
    } catch (e) {
      debugPrint('OneSignal initialization failed: $e');
    }
  }
  
  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final result = await OneSignal.Notifications.requestPermission(true);
      debugPrint('OneSignal permission result: $result');
      return result;
    } catch (e) {
      debugPrint('OneSignal permission request failed: $e');
      return false;
    }
  }
  
  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    try {
      return await OneSignal.Notifications.permission;
    } catch (e) {
      debugPrint('OneSignal permission check failed: $e');
      return false;
    }
  }
  
  /// Set up notification listeners
  static void _setupNotificationListeners() {
    try {
      OneSignal.Notifications.addPermissionObserver((state) {
        debugPrint('OneSignal permission state changed: $state');
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((OSNotificationWillDisplayEvent event) {
        debugPrint('Foreground notification received: ${event.notification.title}');
        
        try {
          _saveNotificationLocally(event.notification);
          event.preventDefault();
          event.notification.display();
        } catch (e) {
          debugPrint('Error handling foreground notification: $e');
        }
      });

      OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
        debugPrint('Notification clicked: ${event.notification.title}');
        
        try {
          _saveNotificationLocally(event.notification);
          _handleNotificationClick(event.notification);
        } catch (e) {
          debugPrint('Error handling notification click: $e');
        }
      });

    } catch (e) {
      debugPrint('Error setting up OneSignal listeners: $e');
    }
  }
  
  /// Handle notification click actions
  static void _handleNotificationClick(OSNotification notification) {
    try {
      final additionalData = notification.additionalData;
      
      if (additionalData != null && additionalData.isNotEmpty) {
        debugPrint('Notification additional data: $additionalData');
      }
    } catch (e) {
      debugPrint('Error handling notification click action: $e');
    }
  }
  
  /// Get OneSignal user ID
  static Future<String?> getUserId() async {
    try {
      return await OneSignal.User.pushSubscription.id;
    } catch (e) {
      debugPrint('Error getting OneSignal user ID: $e');
      return null;
    }
  }
  
  /// Set custom user tags
  static Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      debugPrint('OneSignal user tags set: $tags');
    } catch (e) {
      debugPrint('Error setting OneSignal user tags: $e');
    }
  }
  
  /// Remove user tags
  static Future<void> removeUserTags(List<String> tags) async {
    try {
      OneSignal.User.removeTags(tags);
      debugPrint('OneSignal user tags removed: $tags');
    } catch (e) {
      debugPrint('Error removing OneSignal user tags: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL STORAGE METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Save notification to local history
  static void _saveNotificationLocally(OSNotification notification) {
    try {
      final notificationModel = NotificationModel(
        title: notification.title ?? 'No Title',
        description: notification.body ?? 'No Description',
        receivedTime: DateTime.now(),
      );
      
      saveNotification(notificationModel);
    } catch (e) {
      debugPrint('Error saving notification locally: $e');
    }
  }

  static Future<void> saveNotification(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    notifications.add(notification);
    
    final notificationsJson = notifications
        .map((notification) => notification.toJson())
        .toList();
    
    await prefs.setString(_notificationsKey, jsonEncode(notificationsJson));
  }

  static Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson == null) {
      return [];
    }
    
    final List<dynamic> decodedJson = jsonDecode(notificationsJson);
    return decodedJson
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }
}
