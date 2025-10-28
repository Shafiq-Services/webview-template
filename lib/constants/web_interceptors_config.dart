import 'package:flutter/material.dart';
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
  static void setupInterceptors(WebElementInterceptorService service, BuildContext context, dynamic webViewController) {
    _setupClickInterceptors(service, context, webViewController);
    _setupHideElements(service);
  }

  static void _setupClickInterceptors(WebElementInterceptorService service, BuildContext context, dynamic webViewController) {
    service.registerMultipleInterceptors([
      // ───────────────────────────────────────────────────────────────────────
      // Home Page Button Interceptor
      // ───────────────────────────────────────────────────────────────────────
      WebElementInterceptor(
        url: 'galaxy2000ai',  // Matches any page on your domain
        elementSelector: '//*[@id="component-preview-container"]/div/div/main/div/div/section[3]/div/div[2]/div[1]/div[2]/button',
        selectorType: SelectorType.xpath,
        action: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Home Page\nUnited States \$15"),
              backgroundColor: Colors.blueAccent.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        disableOriginalClick: true,
        delayMs: 1500,
        maxRetries: 15,
      ),
      
      // ───────────────────────────────────────────────────────────────────────
      // Subscription Page Button Interceptor
      // ───────────────────────────────────────────────────────────────────────
      WebElementInterceptor(
        url: '/subscription',  // Matches URLs containing 'subscription'
        elementSelector: '//*[@id="component-preview-container"]/div/div/main/div/div/div/div[5]/div/div[2]/div[2]/button',
        selectorType: SelectorType.xpath,
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
        disableOriginalClick: true,
        delayMs: 1500,
        maxRetries: 15,
      ),
    ]);
  }

  static void _setupHideElements(WebElementInterceptorService service) {
    service.registerMultipleInterceptors([
      WebElementInterceptor(
        url: '/login',
        elementSelector: '//*[@id="root"]/div/div[7]/div/div[1]/div[2]/div/div[3]/div[1]', // Using XPath
        selectorType: SelectorType.xpath,
        hideElement: true,
      ),
      WebElementInterceptor(
        url: '/login',
        elementSelector: '//*[@id="root"]/div/div[7]/div/div[1]/div[2]/div/div[3]/div[2]', // Using XPath
        selectorType: SelectorType.xpath,
        hideElement: true,
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📖 QUICK REFERENCE
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // How to get XPath from browser:
  // ───────────────────────────────
  // 1. Open website in Chrome
  // 2. Press F12
  // 3. Click element picker icon (top-left)
  // 4. Click the element you want
  // 5. Right-click in Elements tab → Copy → Copy XPath
  // 6. Paste above
  //
  // Examples:
  //   url: 'galaxy2000ai'  ← Matches: https://galaxy2000ai-xxx.base44.app (all pages)
  //   url: '/subscription' ← Matches: https://domain.com/subscription only
  //   url: 'pricing'       ← Matches: any URL containing 'pricing'
  //
  //   WebElementInterceptor(
  //     url: '/page',
  //     elementSelector: '//button',
  //     selectorType: SelectorType.xpath,
  //     action: () async { /* your code */ },
  //     delayMs: 1500,      // Wait longer before searching
  //     maxRetries: 15,     // Keep trying more times
  //   )
  //
  // ═══════════════════════════════════════════════════════════════════════════
}
