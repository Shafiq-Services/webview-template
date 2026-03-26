import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// Initialize OneSignal with error handling (Android + iOS).
  /// iOS: Ensure Push Notifications capability and aps-environment in entitlements are set.
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        debugPrint('OneSignal already initialized');
        return;
      }

      // Enable verbose logging in debug mode
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);

      debugPrint('🔔 OneSignal: Initializing with App ID: ${Changes.oneSignalAppId}');
      
      OneSignal.initialize(Changes.oneSignalAppId);
      OneSignal.LiveActivities.setupDefault();
      
      // Android: high-priority notification channel
      if (Platform.isAndroid) {
        await _configureAndroidNotificationChannel();
      }
      // iOS: uses app icon from bundle for notification; ensure Runner has Push capability.
      
      _setupNotificationListeners();
      
      _isInitialized = true;
      debugPrint('🔔 OneSignal initialized successfully');
      
      // Log subscription status after a delay to allow registration.
      // Use Subscription ID in OneSignal dashboard: Messages > Send Test Message > by Subscription ID.
      Future.delayed(const Duration(seconds: 3), () async {
        final subscriptionId = OneSignal.User.pushSubscription.id;
        final token = OneSignal.User.pushSubscription.token;
        debugPrint('🔔 OneSignal Subscription ID: $subscriptionId');
        debugPrint('🔔 OneSignal Push Token: $token');
        debugPrint('🔔 OneSignal Opted In: ${OneSignal.User.pushSubscription.optedIn}');
      });
      
    } catch (e) {
      debugPrint('🔔 OneSignal initialization failed: $e');
    }
  }
  
  /// Configure Android notification channel for high-priority alerts
  static Future<void> _configureAndroidNotificationChannel() async {
    try {
      // Create high-importance notification channel using platform channel
      const platform = MethodChannel('com.onesignal.notification_channel');
      
      try {
        await platform.invokeMethod('createHighPriorityChannel', {
          'channelId': 'high_importance_channel',
          'channelName': 'Messages',
          'channelDescription': 'High priority notifications for messages',
          'importance': 4, // IMPORTANCE_HIGH
          'enableVibration': true,
          'enableSound': true,
        });
        debugPrint('🔔 Android high-priority notification channel created');
      } catch (e) {
        // Channel creation via platform channel not available, that's OK
        // OneSignal will create channel automatically when notification arrives
        debugPrint('🔔 Using default OneSignal notification channel');
      }
    } catch (e) {
      debugPrint('🔔 Error configuring Android notification channel: $e');
    }
  }
  
  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      debugPrint('🔔 OneSignal: Requesting notification permission...');
      final result = await OneSignal.Notifications.requestPermission(true);
      debugPrint('🔔 OneSignal permission result: $result');
      
      // Log device info after permission
      final subscriptionId = OneSignal.User.pushSubscription.id;
      final token = OneSignal.User.pushSubscription.token;
      debugPrint('🔔 OneSignal Subscription ID: $subscriptionId');
      debugPrint('🔔 OneSignal Push Token: $token');
      
      return result;
    } catch (e) {
      debugPrint('🔔 OneSignal permission request failed: $e');
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
        debugPrint('🔔 OneSignal permission state changed: $state');
      });

      // Foreground notification handler - ALWAYS display with sound
      OneSignal.Notifications.addForegroundWillDisplayListener((OSNotificationWillDisplayEvent event) {
        debugPrint('🔔 Foreground notification received: ${event.notification.title}');
        debugPrint('🔔 Notification body: ${event.notification.body}');
        debugPrint('🔔 Notification sound: ${event.notification.sound}');
        
        try {
          // Save notification locally for history
          _saveNotificationLocally(event.notification);
          
          // IMPORTANT: Do NOT call preventDefault() - let the notification display normally
          // This ensures the notification shows with sound, vibration, and heads-up alert
          // The notification will be displayed automatically by OneSignal
          
          // If you want to customize display, use display() after preventDefault()
          // But for high-priority alerts, let it display naturally
          event.notification.display();
          
          debugPrint('🔔 Notification displayed successfully');
        } catch (e) {
          debugPrint('🔔 Error handling foreground notification: $e');
        }
      });

      // Notification click handler
      OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
        debugPrint('🔔 Notification clicked: ${event.notification.title}');
        
        try {
          _saveNotificationLocally(event.notification);
          _handleNotificationClick(event.notification);
        } catch (e) {
          debugPrint('🔔 Error handling notification click: $e');
        }
      });
      
      // Subscription observer - track when user subscribes/unsubscribes
      OneSignal.User.pushSubscription.addObserver((state) {
        debugPrint('🔔 Push subscription changed:');
        debugPrint('🔔   - ID: ${state.current.id}');
        debugPrint('🔔   - Token: ${state.current.token}');
        debugPrint('🔔   - Opted In: ${state.current.optedIn}');
      });

    } catch (e) {
      debugPrint('🔔 Error setting up OneSignal listeners: $e');
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
  
  // Track last set external ID to avoid duplicate calls
  static String? _lastExternalId;
  
  /// Set external user ID (email) for targeting notifications
  /// This links the device to a specific user so notifications can be sent to them
  static Future<void> setExternalUserId(String? email) async {
    if (email == null || email.isEmpty) {
      debugPrint('🔔 OneSignal: No email provided for external user ID');
      return;
    }
    
    // Clean the email (remove quotes if present from JS)
    final cleanEmail = email.replaceAll('"', '').replaceAll("'", '').trim();
    
    if (cleanEmail.isEmpty || cleanEmail == 'null') {
      debugPrint('🔔 OneSignal: Invalid email for external user ID');
      return;
    }
    
    // Avoid setting the same ID multiple times
    if (_lastExternalId == cleanEmail) {
      debugPrint('🔔 OneSignal: External user ID already set to $cleanEmail');
      return;
    }
    
    try {
      debugPrint('🔔 OneSignal: Setting external user ID to: $cleanEmail');
      OneSignal.login(cleanEmail);
      _lastExternalId = cleanEmail;
      debugPrint('🔔 OneSignal: External user ID set successfully');
    } catch (e) {
      debugPrint('🔔 OneSignal: Failed to set external user ID: $e');
    }
  }
  
  /// Remove external user ID (call on logout)
  static Future<void> removeExternalUserId() async {
    try {
      debugPrint('🔔 OneSignal: Removing external user ID');
      OneSignal.logout();
      _lastExternalId = null;
      debugPrint('🔔 OneSignal: External user ID removed');
    } catch (e) {
      debugPrint('🔔 OneSignal: Failed to remove external user ID: $e');
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
