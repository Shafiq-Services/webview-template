import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/notification_service.dart';

/// Initialize app features on startup
class AppInitializer {
  static Future<void> initialize() async {
    // Enable webview debugging (Android)
    await _initializeWebView();
    
    // Initialize push notifications
    await NotificationService.initialize();
  }
  
  static Future<void> _initializeWebView() async {
    if (!Platform.isAndroid) return;
    
    // Enable Chrome DevTools for webview
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    
    // Setup service worker if available
    final swAvailable = await WebViewFeature.isFeatureSupported(
      WebViewFeature.SERVICE_WORKER_BASIC_USAGE
    );
    final swInterceptAvailable = await WebViewFeature.isFeatureSupported(
      WebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST
    );
    
    if (swAvailable && swInterceptAvailable) {
      final controller = ServiceWorkerController.instance();
      await controller.setServiceWorkerClient(
        ServiceWorkerClient(
          shouldInterceptRequest: (request) async {
            return null;
          },
        ),
      );
    }
  }
}

