import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Note: Product IDs are now managed by SubscriptionController to avoid duplication
  
  // Available products
  List<ProductDetails> _products = [];
  
  // Subscription status
  bool _isSubscriptionActive = false;
  String? _activeSubscriptionId;
  DateTime? _subscriptionExpiry;
  
  // Getters
  bool get isSubscriptionActive => _isSubscriptionActive;
  String? get activeSubscriptionId => _activeSubscriptionId;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  List<ProductDetails> get products => _products;
  
  // Callbacks
  Function(bool isActive, String? subscriptionId)? onSubscriptionStatusChanged;
  Function(String error)? onPurchaseError;
  Function(String message)? onPurchaseSuccess;

  /// Initialize the IAP service
  Future<bool> initialize({Set<String>? productIds}) async {
    if (kDebugMode) print('🏪 IAP Service: Starting initialization...');
    
    try {
      if (kDebugMode) print('🏪 IAP Service: Checking store availability...');
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (kDebugMode) print('🏪 IAP Service: Store available: $isAvailable');
      
      if (!isAvailable) {
        if (kDebugMode) print('❌ IAP Service: Store is not available');
        return false;
      }

      // Set up purchase listener
      if (kDebugMode) print('🏪 IAP Service: Setting up purchase stream listener...');
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          if (kDebugMode) print('❌ IAP Service: Purchase stream error: $error');
          onPurchaseError?.call('Purchase stream error: $error');
        },
      );

      // Load products
      if (kDebugMode) print('🏪 IAP Service: Loading products...');
      if (productIds != null && productIds.isNotEmpty) {
        await _loadProducts(productIds);
      } else {
        if (kDebugMode) print('⚠️ IAP Service: No product IDs provided, skipping product loading');
      }
      
      // Check for existing subscriptions
      if (kDebugMode) print('🏪 IAP Service: Restoring purchases...');
      await _restorePurchases();
      
      if (kDebugMode) print('✅ IAP Service: Service initialized successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ IAP Service: Initialization error: $e');
      return false;
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts(Set<String> productIds) async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        if (kDebugMode) print('IAP: Error loading products: ${response.error}');
        return;
      }
      
      _products = response.productDetails;
      if (kDebugMode) {
        print('IAP: Loaded ${_products.length} products');
        for (var product in _products) {
          print('IAP: Product - ID: ${product.id}, Price: ${product.price}, Title: ${product.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('IAP: Error loading products: $e');
    }
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    if (kDebugMode) print('💳 IAP Service: Purchase requested for product: $productId');
    
    try {
      if (kDebugMode) print('💳 IAP Service: Searching for product in loaded products...');
      if (kDebugMode) print('💳 IAP Service: Available products: ${_products.map((p) => p.id).toList()}');
      
      ProductDetails? product;
      try {
        product = _products.firstWhere((p) => p.id == productId);
        if (kDebugMode) print('💳 IAP Service: Found product: ${product.id} - ${product.title}');
      } catch (e) {
        if (kDebugMode) print('❌ IAP Service: Product not found in loaded products: $productId');
        onPurchaseError?.call('Product not found: $productId');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      if (kDebugMode) print('💳 IAP Service: Starting purchase for: ${product.id}');
      if (kDebugMode) print('💳 IAP Service: Product details - Title: ${product.title}, Price: ${product.price}');
      
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (kDebugMode) print('💳 IAP Service: Purchase initiation result: $success');
      
      if (!success) {
        if (kDebugMode) print('❌ IAP Service: Failed to initiate purchase');
        onPurchaseError?.call('Failed to initiate purchase');
        return false;
      }
      
      if (kDebugMode) print('✅ IAP Service: Purchase initiated successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ IAP Service: Purchase error: $e');
      onPurchaseError?.call('Purchase error: $e');
      return false;
    }
  }

  /// Handle purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (kDebugMode) {
        print('IAP: Purchase update - Status: ${purchaseDetails.status}, Product: ${purchaseDetails.productID}');
      }
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          if (kDebugMode) print('IAP: Purchase pending for ${purchaseDetails.productID}');
          break;
          
        case PurchaseStatus.purchased:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;
          
        case PurchaseStatus.error:
          if (kDebugMode) print('IAP: Purchase error: ${purchaseDetails.error}');
          onPurchaseError?.call(purchaseDetails.error?.message ?? 'Unknown purchase error');
          break;
          
        case PurchaseStatus.restored:
          await _handleRestoredPurchase(purchaseDetails);
          break;
          
        case PurchaseStatus.canceled:
          if (kDebugMode) print('IAP: Purchase canceled for ${purchaseDetails.productID}');
          onPurchaseError?.call('Purchase was canceled');
          break;
      }
      
      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (kDebugMode) print('IAP: Purchase successful for ${purchaseDetails.productID}');
      
      // Verify the purchase (you should implement server-side verification in production)
      final bool isValid = await _verifyPurchase(purchaseDetails);
      
      if (isValid) {
        await _activateSubscription(purchaseDetails.productID);
        await _savePurchaseLocally(purchaseDetails);
        
        onPurchaseSuccess?.call('Subscription activated successfully!');
        
        if (kDebugMode) print('IAP: Subscription activated for ${purchaseDetails.productID}');
      } else {
        onPurchaseError?.call('Purchase verification failed');
      }
    } catch (e) {
      if (kDebugMode) print('IAP: Error handling successful purchase: $e');
      onPurchaseError?.call('Error processing purchase: $e');
    }
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    if (kDebugMode) print('IAP: Purchase restored for ${purchaseDetails.productID}');
    await _handleSuccessfulPurchase(purchaseDetails);
  }

  /// Verify purchase (implement proper server-side verification in production)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // For development, we'll accept all purchases as valid
    // In production, you should verify purchases with your backend server
    // or with Google Play/App Store directly
    
    if (kDebugMode) print('IAP: Verifying purchase (development mode - always true)');
    return true;
  }

  /// Activate subscription
  Future<void> _activateSubscription(String productId) async {
    _isSubscriptionActive = true;
    _activeSubscriptionId = productId;
    
    // Set expiry date based on subscription type (generic approach)
    if (productId.contains('monthly')) {
      _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
    } else if (productId.contains('yearly') || productId.contains('year')) {
      _subscriptionExpiry = DateTime.now().add(const Duration(days: 365));
    } else {
      // Default to monthly if type cannot be determined
      _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
    }
    
    // Notify listeners
    onSubscriptionStatusChanged?.call(_isSubscriptionActive, _activeSubscriptionId);
  }

  /// Save purchase locally
  Future<void> _savePurchaseLocally(PurchaseDetails purchaseDetails) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', true);
    await prefs.setString('subscription_id', purchaseDetails.productID);
    await prefs.setString('purchase_id', purchaseDetails.purchaseID ?? '');
    await prefs.setInt('purchase_date', DateTime.now().millisecondsSinceEpoch);
    
    if (_subscriptionExpiry != null) {
      await prefs.setInt('subscription_expiry', _subscriptionExpiry!.millisecondsSinceEpoch);
    }
  }

  /// Restore purchases
  Future<void> _restorePurchases() async {
    try {
      if (kDebugMode) print('IAP: Restoring purchases...');
      
      // First check local storage
      await _loadLocalSubscriptionStatus();
      
      // Then check with the store
      await _inAppPurchase.restorePurchases();
      
      if (kDebugMode) print('IAP: Purchase restoration completed');
    } catch (e) {
      if (kDebugMode) print('IAP: Error restoring purchases: $e');
    }
  }

  /// Load subscription status from local storage
  Future<void> _loadLocalSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSubscriptionActive = prefs.getBool('subscription_active') ?? false;
      _activeSubscriptionId = prefs.getString('subscription_id');
      
      final expiryTimestamp = prefs.getInt('subscription_expiry');
      if (expiryTimestamp != null) {
        _subscriptionExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        
        // Check if subscription has expired
        if (_subscriptionExpiry!.isBefore(DateTime.now())) {
          _isSubscriptionActive = false;
          _activeSubscriptionId = null;
          _subscriptionExpiry = null;
          await _clearLocalSubscription();
        }
      }
      
      if (kDebugMode) {
        print('IAP: Local subscription status - Active: $_isSubscriptionActive, ID: $_activeSubscriptionId');
      }
    } catch (e) {
      if (kDebugMode) print('IAP: Error loading local subscription status: $e');
    }
  }

  /// Clear local subscription data
  Future<void> _clearLocalSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subscription_active');
    await prefs.remove('subscription_id');
    await prefs.remove('purchase_id');
    await prefs.remove('purchase_date');
    await prefs.remove('subscription_expiry');
  }

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if store is available
  Future<bool> isStoreAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  /// Dispose the service
  void dispose() {
    _subscription.cancel();
  }
}
