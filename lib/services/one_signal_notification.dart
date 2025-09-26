import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:webview_demo/constants/my_app_urls.dart';
import 'package:webview_demo/models/notification_model.dart';
import 'package:webview_demo/services/notification_service.dart';

class OneSignalNotification {
  static bool _isInitialized = false;
  
  /// Initialize OneSignal with error handling and non-blocking setup
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        debugPrint('OneSignal already initialized');
        return;
      }

      // Set log level for debugging (disable in production)
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      }

      // Initialize OneSignal with app ID
      OneSignal.initialize(Changes.oneSignalAppId);
      
      // Set up live activities for iOS (optional)
      OneSignal.LiveActivities.setupDefault();
      
      // Set up notification listeners
      _setupNotificationListeners();
      
      _isInitialized = true;
      debugPrint('OneSignal initialized successfully');
      
    } catch (e) {
      debugPrint('OneSignal initialization failed: $e');
      // Don't throw error to prevent app crash
    }
  }
  
  /// Request notification permission with proper error handling
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
      final permission = await OneSignal.Notifications.permission;
      return permission;
    } catch (e) {
      debugPrint('OneSignal permission check failed: $e');
      return false;
    }
  }
  
  /// Set up notification listeners for all states
  static void _setupNotificationListeners() {
    try {
      // Listen to permission changes
      OneSignal.Notifications.addPermissionObserver((state) {
        debugPrint('OneSignal permission state changed: $state');
      });

      // Handle foreground notifications (when app is open and active)
      OneSignal.Notifications.addForegroundWillDisplayListener((OSNotificationWillDisplayEvent event) {
        debugPrint('Foreground notification received: ${event.notification.title}');
        
        try {
          _saveNotificationLocally(event.notification);
          // Display the notification in foreground
          event.preventDefault();
          event.notification.display();
        } catch (e) {
          debugPrint('Error handling foreground notification: $e');
        }
      });

      // Handle notification clicks (works in all app states: foreground, background, terminated)
      OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
        debugPrint('Notification clicked: ${event.notification.title}');
        
        try {
          _saveNotificationLocally(event.notification);
          // Handle navigation or custom actions here if needed
          _handleNotificationClick(event.notification);
        } catch (e) {
          debugPrint('Error handling notification click: $e');
        }
      });

    } catch (e) {
      debugPrint('Error setting up OneSignal listeners: $e');
    }
  }
  
  /// Save notification to local storage for notification history
  static void _saveNotificationLocally(OSNotification notification) {
    try {
      final notificationModel = NotificationModel(
        title: notification.title ?? 'No Title',
        description: notification.body ?? 'No Description',
        receivedTime: DateTime.now(),
      );
      
      // Save to local storage asynchronously
      NotificationService.saveNotification(notificationModel);
    } catch (e) {
      debugPrint('Error saving notification locally: $e');
    }
  }
  
  /// Handle notification click actions
  static void _handleNotificationClick(OSNotification notification) {
    try {
      // Extract custom data if needed
      final additionalData = notification.additionalData;
      
      if (additionalData != null && additionalData.isNotEmpty) {
        debugPrint('Notification additional data: $additionalData');
        // Handle custom navigation or actions based on additional data
        // Example: Navigate to specific page, open URL, etc.
      }
    } catch (e) {
      debugPrint('Error handling notification click action: $e');
    }
  }
  
  /// Get OneSignal user ID (for targeting specific users)
  static Future<String?> getUserId() async {
    try {
      final subscription = await OneSignal.User.pushSubscription.id;
      return subscription;
    } catch (e) {
      debugPrint('Error getting OneSignal user ID: $e');
      return null;
    }
  }
  
  /// Set custom user tags (for segmentation)
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
}
