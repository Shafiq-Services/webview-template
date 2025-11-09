import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/payment_config.dart';

/// Complete payment service: RevenueCat + Base44 sync
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // RevenueCat state
  bool _isInitialized = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  StreamSubscription<CustomerInfo>? _subscription;
  
  // Base44 state
  static final Dio _dio = Dio();
  static dynamic _webViewController;
  
  // Callbacks
  Function(bool isActive)? onSubscriptionChanged;
  Function(String message)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;
  
  // Getters
  bool get isInitialized => _isInitialized;
  
  bool get isPremiumActive {
    return _customerInfo?.entitlements.active.containsKey(PaymentConfig.entitlementId) ?? false;
  }
  
  List<Package> get availableProducts {
    final offering = _offerings?.current ?? _offerings?.getOffering(PaymentConfig.offeringId ?? '');
    return offering?.availablePackages ?? [];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // REVENUECAT METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      await Purchases.setLogLevel(PaymentConfig.debugMode ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(PaymentConfig.revenueCatApiKey));
      await Purchases.setAttributes({'source': 'webview_app'});
      await _loadData();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      if (PaymentConfig.debugMode) print('RevenueCat initialization failed: $e');
      return false;
    }
  }
  
  Future<void> _loadData() async {
    _customerInfo = await Purchases.getCustomerInfo();
    _offerings = await Purchases.getOfferings();
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
      _customerInfo = purchaserInfo;
      
      if (PaymentConfig.debugMode) {
        print('🛒 Purchased package: ${package.storeProduct.identifier}');
        print('📦 Package identifier: ${package.identifier}');
      }
      
      // Sync with Base44 after purchase
      await _syncSubscription(purchaserInfo, productId: productId);
      
      if (purchaserInfo.entitlements.active.containsKey(PaymentConfig.entitlementId)) {
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
      _customerInfo = await Purchases.restorePurchases();
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
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BASE44 SYNC METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Set webview controller for JWT token access
  void setWebViewController(dynamic controller) {
    _webViewController = controller;
  }
  
  /// Sync subscription status to Base44 after purchase
  Future<void> _syncSubscription(CustomerInfo customerInfo, {String? productId}) async {
    if (!PaymentConfig.enableBase44Sync) return;

    try {
      final token = await _getJwtToken();
      if (token == null) {
        if (PaymentConfig.debugMode) {
          print('⚠️ Base44 sync skipped: No JWT token (user not logged in)');
        }
        return;
      }

      final customerId = customerInfo.originalAppUserId;
      final activeEntitlements = customerInfo.entitlements.active;
      
      if (activeEntitlements.isEmpty) {
        await _sendToBase44(token, customerId, null, false, null);
        return;
      }

      final entitlement = activeEntitlements.values.first;
      
      // Use provided product ID or find highest tier
      final actualProductId = productId ?? _getHighestTierProduct(activeEntitlements);
      final isActive = true;
      final expirationDate = entitlement.expirationDate;
      
      if (PaymentConfig.debugMode) {
        print('🔍 Active entitlements: ${activeEntitlements.keys.join(", ")}');
        print('🔍 Product IDs: ${activeEntitlements.values.map((e) => e.productIdentifier).join(", ")}');
        print('✅ Using product ID: $actualProductId');
      }

      await _sendToBase44(token, customerId, actualProductId, isActive, expirationDate);
    } catch (e) {
      if (PaymentConfig.debugMode) {
        print('⚠️ Base44 sync failed: $e');
      }
    }
  }

  /// Get highest tier product: Elite > Premium > Others
  String _getHighestTierProduct(Map<String, EntitlementInfo> entitlements) {
    final productIds = entitlements.values.map((e) => e.productIdentifier.toLowerCase()).toList();
    
    if (PaymentConfig.debugMode) {
      print('🔍 Finding highest tier from: $productIds');
    }
    
    if (productIds.any((id) => id.contains('elite'))) {
      return entitlements.values.firstWhere(
        (e) => e.productIdentifier.toLowerCase().contains('elite')
      ).productIdentifier;
    }
    
    if (productIds.any((id) => id.contains('premium'))) {
      return entitlements.values.firstWhere(
        (e) => e.productIdentifier.toLowerCase().contains('premium')
      ).productIdentifier;
    }
    
    return entitlements.values.first.productIdentifier;
  }

  /// Get JWT token from webview localStorage
  Future<String?> _getJwtToken() async {
    if (_webViewController == null) {
      if (PaymentConfig.debugMode) {
        print('⚠️ WebView controller not set');
      }
      return null;
    }

    try {
      final result = await _webViewController.evaluateJavascript(source: """
        (function() {
          return localStorage.getItem('token') || 
                 localStorage.getItem('base44_access_token') || 
                 localStorage.getItem('jwt') || 
                 localStorage.getItem('auth_token') || 
                 localStorage.getItem('access_token') ||
                 null;
        })();
      """);
      
      if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
        if (PaymentConfig.debugMode) {
          print('✅ Found JWT token in localStorage');
        }
        return result.toString();
      }
      
      if (PaymentConfig.debugMode) {
        print('⚠️ No JWT token found in localStorage');
      }
      return null;
    } catch (e) {
      if (PaymentConfig.debugMode) {
        print('⚠️ Failed to get JWT token: $e');
      }
      return null;
    }
  }

  /// Send subscription data to Base44 backend
  Future<void> _sendToBase44(
    String jwtToken,
    String customerId,
    String? productId,
    bool isActive,
    String? expirationDate,
  ) async {
    final payload = {
      'revenuecat_customer_id': customerId,
      'product_id': productId,
      'is_active': isActive,
      if (expirationDate != null) 'expiration_date': expirationDate,
    };
    
    if (PaymentConfig.debugMode) {
      print('📤 Sending to Base44: $payload');
    }
    
    final response = await _dio.post(
      PaymentConfig.base44Url,
      data: payload,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
          'api_key': PaymentConfig.base44ApiKey,
        },
        validateStatus: (status) => true,
      ),
    );

    if (PaymentConfig.debugMode) {
      print('📥 Base44 response [${response.statusCode}]: ${response.data}');
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (PaymentConfig.debugMode) {
        print('✅ Base44 synced: $productId ($isActive)');
      }
    } else {
      if (PaymentConfig.debugMode) {
        print('❌ Base44 sync failed with status ${response.statusCode}');
      }
    }
  }
}

