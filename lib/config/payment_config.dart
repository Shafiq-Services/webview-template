import 'dart:io' show Platform;

/// RevenueCat and backend sync — replace placeholders per project.
class PaymentConfig {
  static String get revenueCatApiKey {
    if (Platform.isIOS) {
      return 'appl_REPLACE_ME';
    }
    return 'goog_REPLACE_ME';
  }

  static const String entitlementId = 'premium';
  static const String? offeringId = null;
  static const bool debugMode = true;
  static const bool testInterceptorsOnly = false;

  static String get annualProductId =>
      Platform.isIOS ? 'yearly_ios' : 'yearly:yearly-base';
  static String get monthlyProductId =>
      Platform.isIOS ? 'monthly_ios' : 'monthly:monthly-base';

  static const String base44Url =
      'https://YOUR_PROJECT.base44.app/api/functions/updateSubscriptionFromRevenueCat';
  static const String base44ApiKey = 'YOUR_BASE44_API_KEY';
  static const bool enableBase44Sync = false;
}
