import 'package:flutter/material.dart';
import 'package:galaxy2000_ai/controllers/subscription_controller.dart';
import '../services/web_element_interceptor_service.dart';
import '../models/web_element_interceptor_model.dart';

/// This file manages all web element interceptions
/// You can intercept button clicks and hide unwanted elements.

/// HOW TO USE:
/// 1. Open your website in Chrome browser
/// 2. Press F12 to open DevTools
/// 3. Click the element selector icon (top-left) or press Ctrl+Shift+C
/// 4. Click the button/element you want to intercept on the webpage
/// 5. In the Elements tab, right-click the highlighted HTML
/// 6. Select: Copy → Copy XPath
/// 7. Paste it below in the configuration
///
/// ════════════════════════════════════════════════════════════════════════════

class WebInterceptorsConfig {
  static void setupInterceptors(
    WebElementInterceptorService service,
    BuildContext context,
    dynamic webViewController, [
    SubscriptionController? subscriptionController,
  ]) {
    _setupClickInterceptors(service, context, webViewController, subscriptionController);
    _setupHideElements(service);
  }

  static void _setupClickInterceptors(
    WebElementInterceptorService service,
    BuildContext context,
    dynamic webViewController,
    SubscriptionController? subscriptionController,
  ) {
    service.registerMultipleInterceptors([
      WebElementInterceptor(
        url: 'galaxy2000ai',
        elementSelector: '//*[@id="component-preview-container"]/div/div/main/div/div/section[3]/div/div[2]/div[1]/div[2]/button',
        action: () async {
          await subscriptionController!.purchaseProduct("monthly_premium", context);
        },
      ),

      WebElementInterceptor(
        url: '/subscription',
        elementSelector: '//*[@id="component-preview-container"]/div/div/main/div/div/div/div[5]/div/div[2]/div[2]/button',
        action: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Subscription Page\nUnited States \$15"),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    ]);
  }

  static void _setupHideElements(WebElementInterceptorService service) {
    service.registerMultipleInterceptors([
      WebElementInterceptor(url: '/login', elementSelector: '//*[@id="root"]/div/div[7]/div/div[1]/div[2]/div/div[3]/div[1]'),

      WebElementInterceptor(url: '/login', elementSelector: '//*[@id="root"]/div/div[7]/div/div[1]/div[2]/div/div[3]/div[2]'),
    ]);
  }

  // Example usage:
  //   WebElementInterceptor(
  //     url: '/page',
  //     elementSelector: '//button',
  //     action: () async {
  //       await subscriptionController!.purchaseProduct("your_product_id", context);
  //     },
  //   )
}
