import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_demo/services/iap_service.dart';

// 📋 Configuration class for subscription plans
class SubscriptionConfig {
  final String productId;
  final String displayName;
  final String fallbackPrice;
  final List<String> priceIdentifiers;
  final List<String> contextKeywords;
  
  const SubscriptionConfig({
    required this.productId,
    required this.displayName,
    required this.fallbackPrice,
    required this.priceIdentifiers,
    required this.contextKeywords,
  });
}

class SubscriptionController {
  static final SubscriptionController _instance = SubscriptionController._internal();
  factory SubscriptionController() => _instance;
  SubscriptionController._internal();

  // 🔧 === PAYMENT CONFIGURATION SECTION ===
  // 📝 Modify these variables for different projects
  
  // 🌐 Website Configuration - ONLY dishup.uk/Pricing
  static const List<String> pricingPagePaths = ['/Pricing'];
  
  // 📱 Subscription Products Configuration
  static const Map<String, SubscriptionConfig> subscriptionPlans = {
    'monthly': SubscriptionConfig(
      productId: 'monthly_premium',
      displayName: 'Monthly Premium',
      fallbackPrice: '£2.99',
      priceIdentifiers: ['£2.99', '2.99', 'monthly', 'month'],
      contextKeywords: ['Monthly', 'month', '/month'],
    ),
    'yearly': SubscriptionConfig(
      productId: 'yearly-premium',
      displayName: 'Yearly Premium', 
      fallbackPrice: '£29.00',
      priceIdentifiers: ['£29', '29.00', 'yearly', 'year'],
      contextKeywords: ['Yearly', 'year', '/year', 'Save'],
    ),
  };
  
  // 🎯 Button Detection Configuration
  static const List<String> subscriptionButtonTexts = [
    'Start 7-Day Free Trial',
    'Free Trial',
    'Start Trial',
    'Subscribe',
    'Get Premium',
    'Upgrade',
    'Buy Now',
  ];
  
  // 🔍 Parent Element Selectors (ordered by priority)
  static const List<String> parentSelectors = [
    '[data-dynamic-content="true"]',
    '.subscription-card',
    '.pricing-card', 
    '.card',
    '[class*="card"]',
    '.plan',
    '[class*="plan"]',
    'div',
  ];
  
  // 💰 Pricing Display Configuration
  static const String iapButtonPrefix = 'Subscribe with App Store';
  static const bool showFallbackPricing = true;
  static const bool enableButtonTextUpdate = false; // Set to true to update button text
  
  // 🎛️ Behavior Configuration
  static const int injectionDelayMs = 1000;
  static const bool enableFallbackToMonthly = true; // Any unmatched trial button becomes monthly
  static const bool enableDebugLogging = true;
  
  // 📊 Subscription Priority (first match wins)
  static const List<String> subscriptionPriority = ['yearly', 'monthly'];
  
  // 🔧 === END CONFIGURATION SECTION ===

  final IAPService _iapService = IAPService();
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSubscriptionActive => _iapService.isSubscriptionActive;
  String? get activeSubscriptionId => _iapService.activeSubscriptionId;

  /// Initialize the subscription system
  Future<bool> initialize() async {
    if (kDebugMode) print('🚀 Subscription Controller: Initializing...');
    
    if (_isInitialized) {
      if (kDebugMode) print('🚀 Subscription Controller: Already initialized');
      return true;
    }

    try {
      if (kDebugMode) print('🚀 Subscription Controller: Calling IAP service initialize...');
      final bool success = await _iapService.initialize();
      _isInitialized = success;

      if (kDebugMode) {
        print('🚀 Subscription Controller: IAP service initialization result: $success');
        if (success) {
          print('🚀 Subscription Controller: Available products: ${_iapService.products.length}');
          for (var product in _iapService.products) {
            print('  - ${product.id}: ${product.title} - ${product.price}');
          }
        }
      }

      // Set up callbacks
      _iapService.onSubscriptionStatusChanged = (isActive, subscriptionId) {
        if (kDebugMode) {
          print('📱 Subscription Controller: Status changed - Active: $isActive, ID: $subscriptionId');
        }
      };

      _iapService.onPurchaseError = (error) {
        if (kDebugMode) {
          print('❌ Subscription Controller: Purchase error - $error');
        }
      };

      _iapService.onPurchaseSuccess = (message) {
        if (kDebugMode) {
          print('✅ Subscription Controller: Purchase success - $message');
        }
      };

      if (kDebugMode) print('🚀 Subscription Controller: Initialization completed with result: $success');
      return success;
    } catch (e) {
      if (kDebugMode) print('❌ Subscription Controller: Initialization error: $e');
      return false;
    }
  }

  /// Purchase monthly subscription - SIMPLIFIED FOR TESTING
  Future<bool> purchaseMonthlySubscription(BuildContext context) async {
    if (kDebugMode) print('💰 Testing: Monthly purchase requested');
    
    // Check if product exists
    final monthlyConfig = subscriptionPlans['monthly']!;
    final product = _iapService.getProduct(monthlyConfig.productId);
    
    // Show snackbar for product found status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(product != null 
          ? '✅ ProductId found: ${monthlyConfig.productId}' 
          : '❌ ProductId NOT found: ${monthlyConfig.productId}'),
        backgroundColor: product != null ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    
    if (!_isInitialized || product == null) {
      return false;
    }

    try {
      if (kDebugMode) print('💰 Testing: Calling IAP service for monthly');
      final bool success = await _iapService.purchaseSubscription(monthlyConfig.productId);
      
      // Show snackbar for payment result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '✅ Payment Success: Monthly subscription' 
            : '❌ Payment Failed: Monthly subscription'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      return success;
    } catch (e) {
      if (kDebugMode) print('❌ Testing: Monthly purchase exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Payment Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  /// Purchase yearly subscription - SIMPLIFIED FOR TESTING
  Future<bool> purchaseYearlySubscription(BuildContext context) async {
    if (kDebugMode) print('💰 Testing: Yearly purchase requested');
    
    // Check if product exists
    final yearlyConfig = subscriptionPlans['yearly']!;
    final product = _iapService.getProduct(yearlyConfig.productId);
    
    // Show snackbar for product found status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(product != null 
          ? '✅ ProductId found: ${yearlyConfig.productId}' 
          : '❌ ProductId NOT found: ${yearlyConfig.productId}'),
        backgroundColor: product != null ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    
    if (!_isInitialized || product == null) {
      return false;
    }

    try {
      if (kDebugMode) print('💰 Testing: Calling IAP service for yearly');
      final bool success = await _iapService.purchaseSubscription(yearlyConfig.productId);
      
      // Show snackbar for payment result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '✅ Payment Success: Yearly subscription' 
            : '❌ Payment Failed: Yearly subscription'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      return success;
    } catch (e) {
      if (kDebugMode) print('❌ Testing: Yearly purchase exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Payment Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  /// Get subscription price by plan key
  String getSubscriptionPrice(String planKey) {
    final config = subscriptionPlans[planKey];
    if (config == null) return 'Price not available';
    
    final product = _iapService.getProduct(config.productId);
    return product?.price ?? config.fallbackPrice;
  }
  
  /// Get monthly subscription price
  String getMonthlyPrice() {
    return getSubscriptionPrice('monthly');
  }

  /// Get yearly subscription price
  String getYearlyPrice() {
    return getSubscriptionPrice('yearly');
  }

  /// Check subscription status
  bool checkSubscriptionStatus() {
    return _iapService.isSubscriptionActive;
  }

  // 🗑️ Removed all dialog methods - using snackbars only for testing

  /// Get JavaScript code to inject into WebView for pricing page - SIMPLIFIED FOR TESTING
  String getPricingPageJavaScript() {
    if (kDebugMode) print('🔧 Generating SIMPLIFIED JavaScript for testing');
    
    return '''
(function() {
  console.log('🧪 DishUP IAP: TESTING MODE - Simple button override');
  
  // Simple purchase functions for testing
  function purchaseMonthlySubscription() {
    console.log('🧪 Monthly subscription clicked - calling Flutter');
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('purchaseMonthlySubscription');
    }
  }
  
  function purchaseYearlySubscription() {
    console.log('🧪 Yearly subscription clicked - calling Flutter');
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('purchaseYearlySubscription');
    }
  }
  
  
  // SIMPLIFIED button override for testing
  function overridePricingButtons() {
    if (window.dishupButtonsProcessed) {
      console.log('🧪 Buttons already processed, skipping');
      return;
    }
    
    // Only run on exact dishup.uk/Pricing page
    if (!window.location.href.includes('dishup.uk/Pricing')) {
      console.log('🧪 Not on dishup.uk/Pricing page, skipping');
      return;
    }
    
    console.log('🧪 TESTING: Finding subscription buttons on dishup.uk/Pricing');
    
    const buttons = document.querySelectorAll('button');
    console.log('🧪 Found', buttons.length, 'buttons total');
    
    let buttonsOverridden = 0;
    
    buttons.forEach((button, index) => {
      const buttonText = button.textContent || '';
      const parentCard = button.closest('[data-dynamic-content="true"]') || button.closest('div');
      const parentText = parentCard ? parentCard.textContent : '';
      
      // Look for subscription buttons
      if (buttonText.includes('Start 7-Day Free Trial')) {
        console.log('🧪 Found subscription button', index, ':', buttonText.substring(0, 50));
        
        // Determine if monthly or yearly based on parent text
        const isMonthly = parentText.includes('Monthly') && !parentText.includes('Yearly');
        const isYearly = parentText.includes('Yearly');
        
        console.log('🧪 Button context - Monthly:', isMonthly, 'Yearly:', isYearly);
        
        // Override the button
        button.addEventListener('click', function(e) {
          e.preventDefault();
          e.stopPropagation();
          
          if (isMonthly) {
            console.log('🧪 Monthly button clicked!');
            purchaseMonthlySubscription();
          } else if (isYearly) {
            console.log('🧪 Yearly button clicked!');
            purchaseYearlySubscription();
          } else {
            console.log('🧪 Unknown button clicked - defaulting to monthly');
            purchaseMonthlySubscription();
          }
        }, { capture: true });
        
        buttonsOverridden++;
      }
    });
    
    window.dishupButtonsProcessed = true;
    console.log('🧪 TESTING: Overridden', buttonsOverridden, 'subscription buttons');
  }
  
  // Run immediately for testing
  if (!window.dishupIAPInitialized) {
    window.dishupIAPInitialized = true;
    
    // Run with delay to ensure page is loaded
    setTimeout(() => {
      overridePricingButtons();
    }, 1000);
    
    console.log('🧪 TESTING: IAP override script loaded');
  }
})();
''';
  }

  // 🗑️ Removed complex helper methods - using simplified approach for testing

  /// Dispose the controller
  void dispose() {
    _iapService.dispose();
  }
}
