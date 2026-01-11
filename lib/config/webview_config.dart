import 'package:flutter/material.dart';
import '../controllers/subscription_controller.dart';
import '../services/web_element_interceptor_service.dart';
import '../models/web_element_interceptor_model.dart';
import '../utils/subscription_helpers.dart';

/// 🌐 WEBVIEW CONFIG - Subscription buttons + UI hiding
class WebViewConfig {
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 SUBSCRIPTION BUTTONS - Map XPath to RevenueCat product IDs
  // ═══════════════════════════════════════════════════════════════════════════
  
  static final subscriptionButtons = {
    '/subscription': [
      SubscriptionButton(
        xpath: '//*[@id="root"]/div[1]/main/div/div/div[2]/div[2]/div[4]/button',
        productId: 'monthly_premium',
        displayName: 'Premium Subscription',
      ),
      SubscriptionButton(
        xpath: '//*[@id="root"]/div[1]/main/div/div/div[2]/div[3]/div[2]/button',
        productId: 'monthly_elite',
        displayName: 'Elite Subscription',
      ),
    ],
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 HIDE ELEMENTS - XPath of elements to hide
  // ═══════════════════════════════════════════════════════════════════════════
  
  static final hideElements = [
    HideElement(url: '/', xpath: '//*[@id="root"]/div[1]/section[1]/div[2]/div[1]/div[2]'),
    HideElement(url: '/', xpath: '//*[@id="root"]/div[1]/section[2]'),
    HideElement(url: '/', xpath: '//*[@id="root"]/div[1]/section[3]'),
    HideElement(url: '/login', xpath: '//*[@id="root"]/div/div[7]/div/div[1]/div[2]/div/div[3]/div[1]'),
    HideElement(url: '/login', xpath: '//*[@id="root"]/div/div[7]/div/div[1]/div[2]/div/div[3]/div[2]'),
  ];
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Setup method (don't modify)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static void setupInterceptors(
    WebElementInterceptorService service,
    BuildContext context,
    dynamic webViewController, [
    SubscriptionController? subscriptionController,
  ]) {
    final allInterceptors = <WebElementInterceptor>[];
    
    // Register subscription buttons
    subscriptionButtons.forEach((url, buttons) {
      for (var btn in buttons) {
        allInterceptors.add(
          createSubscriptionButton(
            url: url,
            elementSelector: btn.xpath,
            buttonName: btn.productId,
            displayName: btn.displayName,
            context: context,
            subscriptionController: subscriptionController,
          ),
        );
      }
    });
    
    // Register hide elements
    // for (var element in hideElements) {
    //   allInterceptors.add(
    //     WebElementInterceptor(
    //       url: element.url,
    //       elementSelector: element.xpath,
    //     ),
    //   );
    // }
    
    service.registerMultipleInterceptors(allInterceptors);
  }
}

// Data classes
class SubscriptionButton {
  final String xpath;
  final String productId;
  final String displayName;
  
  SubscriptionButton({
    required this.xpath,
    required this.productId,
    required this.displayName,
  });
}

class HideElement {
  final String url;
  final String xpath;
  
  HideElement({
    required this.url,
    required this.xpath,
  });
}

// Backwards compatibility
class WebInterceptorsConfig {
  static void setupInterceptors(
    WebElementInterceptorService service,
    BuildContext context,
    dynamic webViewController, [
    SubscriptionController? subscriptionController,
  ]) {
    WebViewConfig.setupInterceptors(service, context, webViewController, subscriptionController);
  }
}
