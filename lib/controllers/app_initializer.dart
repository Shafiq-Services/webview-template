import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../config/app_config.dart';
import '../services/notification_service.dart';
import '../services/deep_link_service.dart';

/// Initialize app features on startup (gated by delivery milestone)
class AppInitializer {
  static Future<void> initialize() async {
    await _initializeWebView();

    // Deep link handling (shared recipe links, app invites)
    await DeepLinkService().initialize();

    // M2: Push notification configuration
    if (AppConfig.deliveryMilestone >= 2) {
      await NotificationService.initialize();
    }
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

