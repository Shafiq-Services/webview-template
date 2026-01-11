import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure iOS notifications for high priority
    configureNotifications(application: application)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func configureNotifications(application: UIApplication) {
    // Set notification delegate to handle foreground notifications
    UNUserNotificationCenter.current().delegate = self
    
    // Request notification authorization with all options
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert, .provisional]
    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
      if let error = error {
        print("🔔 iOS Notification authorization error: \(error)")
      } else {
        print("🔔 iOS Notification authorization granted: \(granted)")
      }
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    print("🔔 iOS Notifications configured for high priority")
  }
  
  // Handle foreground notifications - ALWAYS show with sound
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("🔔 iOS Foreground notification received: \(notification.request.content.title)")
    
    // Show notification with banner, sound, and badge even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge, .list])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  // Handle notification tap
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("🔔 iOS Notification tapped: \(response.notification.request.content.title)")
    completionHandler()
  }
}
