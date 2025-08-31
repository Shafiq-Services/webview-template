# Flutter WebView Template

Production-ready Flutter WebView template that wraps any website with native mobile features.

## ✨ Key Features

- 🌐 **WebView Integration** - OAuth, downloads, geolocation, pull-to-refresh
- 💰 **In-App Purchases** - Auto-intercepts web payment buttons, Google Play/App Store
- 🎨 **User Experience** - Splash screen, onboarding, error handling, notifications
- ⚡ **Performance** - Hybrid composition, service workers, smart URL routing

## 🚀 Quick Setup

### 1. **Configure Your Website**
```dart
// lib/constants/my_app_urls.dart
static String mainUrl = '[YOUR_WEBSITE_URL]';
static String AppTitle = '[YOUR_APP_NAME]';
```

### 2. **Setup In-App Purchases** (Optional)
```dart
// lib/controllers/subscription_controller.dart
'monthly': SubscriptionConfig(productId: '[YOUR_MONTHLY_PRODUCT_ID]'),
'yearly': SubscriptionConfig(productId: '[YOUR_YEARLY_PRODUCT_ID]'),
```

### 3. **Customize JavaScript** (For IAP)
- Update button detection in `getPricingPageJavaScript()`
- Modify HTML selectors for your payment page

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
- `in_app_purchase` - IAP integration
- `connectivity_plus` - Network checking
- `permission_handler` - Device permissions

---
**Template Status**: Production ready • **License**: MIT
