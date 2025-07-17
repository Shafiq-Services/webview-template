// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:webview_template/constants/my_app_urls.dart';
// import 'package:webview_template/models/notification_model.dart';
// import 'package:webview_template/services/notification_service.dart';

// class OneSignalNotification {
//   static Future<void> initialize() async {
//     // Set log level
//     OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
//     OneSignal.Debug.setAlertLevel(OSLogLevel.none);

//     // Initialize OneSignal with your app ID
//     OneSignal.initialize(
//       //"f12af213-0b75-4b7d-a30b-f6ebe93d1db5",
//       Changes.oneSignalAppId
//     );

//     // Set up default live activities if needed
//     OneSignal.LiveActivities.setupDefault();

//     // Request push notification permission
//     OneSignal.Notifications.requestPermission(true).then((value) {
//       print('::: value promptUserForPushNotificationPermission: $value');
//     });

//     // Handle notification received
//     OneSignal.Notifications.addPermissionObserver((state) {
//       print("Has permission " + state.toString());
//     }); 

//     OneSignal.Notifications.addForegroundWillDisplayListener((OSNotificationWillDisplayEvent event) {
//       print('::: Foreground notification received: ${event.notification.title}');
//       final notification = event.notification;
//       if (notification != null) {
//         final notificationModel = NotificationModel(
//           title: notification.title ?? 'No Title',
//           description: notification.body ?? 'No Description',
//           receivedTime: DateTime.now(),
//         );
//         NotificationService.saveNotification(notificationModel);
//       }
//     });

//     // Handle notification clicks
//     // OneSignal.Notifications.addClickListener((event) {
//     //   print('::: Notification clicked: ${event.notification.title}');
//     //   final notification = event.notification;
//     //   if (notification != null) {
//     //     final notificationModel = NotificationModel(
//     //       title: notification.title ?? 'No Title',
//     //       description: notification.body ?? 'No Description',
//     //       receivedTime: DateTime.now(),
//     //     );
//     //     NotificationService.saveNotification(notificationModel);
//     //   }
//     // });
//   }
// }
