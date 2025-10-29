/// RevenueCat configuration
/// Products, pricing, and offerings are managed in RevenueCat Dashboard
class RevenueCatConfig {
  /// RevenueCat API Key - replace with your production key
  static const String apiKey = 'test_KCykjzRlhMTaEvuTItjxViCopkX';
  
  /// Primary entitlement identifier
  static const String premiumEntitlementId = 'premium';
  
  /// Offering identifier (null = use default offering)
  static const String? offeringId = null;
  
  static const bool debugMode = false;
  static const bool autoRestorePurchases = true;
  
  static const Map<String, String> userAttributes = {
    'source': 'webview_app',
  };
}

enum SubscriptionStatus {
  active,
  expired,
  inactive,
  unknown,
}
