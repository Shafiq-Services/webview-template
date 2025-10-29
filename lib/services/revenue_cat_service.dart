import 'dart:async';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/revenue_cat_config.dart';

/// RevenueCat service for handling subscriptions and purchases
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  StreamSubscription<CustomerInfo>? _subscription;
  
  // Callbacks
  Function(bool isActive)? onSubscriptionChanged;
  Function(String message)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;
  
  bool get isInitialized => _isInitialized;
  
  bool get isPremiumActive {
    return _customerInfo?.entitlements.active.containsKey(RevenueCatConfig.premiumEntitlementId) ?? false;
  }
  
  List<Package> get availableProducts {
    final offering = _offerings?.current ?? _offerings?.getOffering(RevenueCatConfig.offeringId ?? '');
    return offering?.availablePackages ?? [];
  }
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      await Purchases.setLogLevel(RevenueCatConfig.debugMode ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(RevenueCatConfig.apiKey));
      await Purchases.setAttributes(RevenueCatConfig.userAttributes);
      await _loadData();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      if (RevenueCatConfig.debugMode) print('RevenueCat initialization failed: $e');
      return false;
    }
  }
  
  Future<void> _loadData() async {
    _customerInfo = await Purchases.getCustomerInfo();
    _offerings = await Purchases.getOfferings();
    
    if (RevenueCatConfig.autoRestorePurchases) {
      await Purchases.restorePurchases();
    }
  }
  
  Future<bool> purchaseProduct(String productId) async {
    if (!_isInitialized) {
      onPurchaseError?.call('RevenueCat not initialized');
      return false;
    }
    
    try {
      final package = availableProducts.cast<Package?>().firstWhere(
        (p) => p?.storeProduct.identifier == productId,
        orElse: () => null,
      );
      
      if (package == null) {
        onPurchaseError?.call('Product not found: $productId');
        return false;
      }
      
      final purchaserInfo = await Purchases.purchasePackage(package);
      
      if (purchaserInfo.entitlements.active.containsKey(RevenueCatConfig.premiumEntitlementId)) {
        onPurchaseSuccess?.call('Subscription activated!');
        return true;
      } else {
        onPurchaseError?.call('Subscription not activated');
        return false;
      }
      
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      } else {
        onPurchaseError?.call(e.message ?? 'Purchase failed');
        return false;
      }
    } catch (e) {
      onPurchaseError?.call('Error: $e');
      return false;
    }
  }
  
  Future<bool> restorePurchases() async {
    if (!_isInitialized) return false;
    
    try {
      await Purchases.restorePurchases();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  String getProductPrice(String productId) {
    final package = availableProducts.cast<Package?>().firstWhere(
      (p) => p?.storeProduct.identifier == productId,
      orElse: () => null,
    );
    return package?.storeProduct.priceString ?? 'Not available';
  }
  
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
