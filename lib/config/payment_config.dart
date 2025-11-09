import 'dart:io' show Platform;

/// 💳 PAYMENT CONFIG - RevenueCat + Base44 keys
class PaymentConfig {
  // RevenueCat API Keys
  static String get revenueCatApiKey {
    if (Platform.isIOS) {
      return 'appl_BWvEKUFiKgkPYzZUGEmzzdPxxVq';
    } else {
      return 'goog_FbovjihPwaPafkQIPLugeUIrwXc';
    }
  }
  
  static const String entitlementId = 'Monthly Subscriptions';
  static const String? offeringId = null;
  static const bool debugMode = true;
  
  // Base44 Backend
  static const String base44Url = 'https://cardcenter.base44.app/api/apps/6869bab8229b302d84a0dd9e/functions/updateSubscriptionFromRevenueCat';
  static const String base44ApiKey = '7c10fba6d5ac485d849772f00ebee10f';
  static const bool enableBase44Sync = true;
}
