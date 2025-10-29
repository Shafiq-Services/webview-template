import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenue_cat_service.dart';

/// 🚀 SIMPLE Subscription Controller
/// 
/// This controller provides easy methods for WebView projects:
/// - Initialize RevenueCat
/// - Purchase monthly/yearly (or any package)
/// - Check premium status
/// - Restore purchases
/// 
/// RevenueCat dashboard handles all the product configuration!
class SubscriptionController {
  static final SubscriptionController _instance = SubscriptionController._internal();
  factory SubscriptionController() => _instance;
  SubscriptionController._internal();

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 MINIMAL STATE
  // ═══════════════════════════════════════════════════════════════════════════
  
  final RevenueCatService _service = RevenueCatService();
  bool _isInitialized = false;
  BuildContext? _context;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔍 SIMPLE GETTERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool get isInitialized => _isInitialized;
  bool get isPremiumActive => _service.isPremiumActive;
  List<Package> get availableProducts => _service.availableProducts;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚀 SIMPLE INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Initialize RevenueCat - Just call this once in your app
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      final success = await _service.initialize();
      _isInitialized = success;
      
      if (success) {
        // Set up simple callbacks
        _service.onSubscriptionChanged = (isActive) {
          if (kDebugMode) print('📱 Premium status changed: $isActive');
        };
        
        _service.onPurchaseSuccess = (message) {
          _showMessage('✅ $message', Colors.green);
        };
        
        _service.onPurchaseError = (error) {
          _showMessage('❌ $error', Colors.red);
        };
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) print('❌ SubscriptionController initialization exception: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💳 ULTRA-SIMPLE PURCHASE - Just pass productId!
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Purchase any product by ID - RevenueCat handles everything!
  /// 
  /// Usage:
  /// await controller.purchaseProduct("monthly_premium", context);
  /// await controller.purchaseProduct("yearly_premium", context);
  Future<bool> purchaseProduct(String productId, BuildContext context) async {
    _context = context;
    return await _service.purchaseProduct(productId);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🚀 CONVENIENCE METHODS (Optional - for common cases)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Purchase monthly subscription (if your product ID is "monthly_premium")
  Future<bool> purchaseMonthlySubscription(BuildContext context) async {
    return await purchaseProduct("monthly_premium", context);
  }

  /// Purchase yearly subscription (if your product ID is "yearly_premium")
  Future<bool> purchaseYearlySubscription(BuildContext context) async {
    return await purchaseProduct("yearly_premium", context);
  }
  
  /// Restore purchases
  Future<bool> restorePurchases(BuildContext context) async {
    _context = context;
    _showMessage('🔄 Restoring purchases...', Colors.blue);
    
    final success = await _service.restorePurchases();
    
    if (success) {
      final message = isPremiumActive 
          ? '✅ Subscription restored!' 
          : 'ℹ️ No active subscriptions found';
      final color = isPremiumActive ? Colors.green : Colors.orange;
      _showMessage(message, color);
    }
    
    return success;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 ULTRA-SIMPLE DATA ACCESS - Get price by productId
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get product price by ID
  /// 
  /// Usage:
  /// String price = controller.getProductPrice("monthly_premium");
  String getProductPrice(String productId) {
    return _service.getProductPrice(productId);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 HELPER METHOD
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Show message to user
  void _showMessage(String message, MaterialColor color) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🗑️ CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Dispose the controller
  void dispose() {
    _service.dispose();
  }
}
