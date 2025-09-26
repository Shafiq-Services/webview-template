# Flutter WebView Template

Production-ready Flutter WebView template that wraps any website with native mobile features.

## ✨ Key Features

- 🌐 **WebView Integration** - OAuth, downloads, geolocation, pull-to-refresh
- 💰 **In-App Purchases** - Auto-intercepts web payment buttons, Google Play/App Store
- 🔔 **Push Notifications** - OneSignal integration with foreground/background/terminated support
- ⚡ **Performance** - Hybrid composition, service workers, smart URL routing

## 🚀 Quick Setup

### 1. **Configure Your Website**
```dart
// lib/constants/my_app_urls.dart
static String mainUrl = '[YOUR_WEBSITE_URL]';
static String AppTitle = '[YOUR_APP_NAME]';
```

### 2. **Setup OneSignal** (Optional)
```dart
// lib/constants/my_app_urls.dart
static String oneSignalAppId = '[YOUR_ONESIGNAL_APP_ID]';
```

### 3. **Configure Platforms**
- Android: Update OneSignal metadata in `AndroidManifest.xml`
- iOS: Update `Info.plist` with background modes and permissions

### 4. **Run**
```bash
flutter pub get
flutter run
```

## 📱 Platforms
Android • iOS • Web (limited IAP)

## 📚 Documentation
Detailed docs: `.cursor/rules/web-view.mdc`

## 🔧 Main Dependencies
- `flutter_inappwebview` - WebView functionality
- `onesignal_flutter` - Push notifications
- `in_app_purchase` - IAP integration
- `permission_handler` - Device permissions

---
**Template Status**: Production ready • **License**: MIT
