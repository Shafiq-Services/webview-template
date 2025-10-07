import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:webview_demo/models/notification_model.dart';

class NotificationService {
  static const String _notificationsKey = 'notifications';

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