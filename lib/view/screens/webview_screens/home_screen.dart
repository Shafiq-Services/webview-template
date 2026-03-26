import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dio/dio.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import '../../../config/app_config.dart';
import '../../../config/payment_config.dart';
import '../../../config/webview_config.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../utils/error_handlers.dart';
import '../../../utils/internet_connectivity.dart';
import '../../../services/web_element_interceptor_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/deep_link_service.dart';

/// Viewport-fit=cover so web app gets env(safe-area-inset-*) for top (header below status bar).
const String _viewportFitCoverScript = r'''
(function() {
  var m = document.querySelector('meta[name=viewport]');
  if (m) {
    var c = m.getAttribute('content') || '';
    if (c.indexOf('viewport-fit=cover') === -1)
      m.setAttribute('content', (c ? c + ', ' : '') + 'viewport-fit=cover');
  } else {
    var meta = document.createElement('meta');
    meta.name = 'viewport';
    meta.content = 'width=device-width, initial-scale=1, viewport-fit=cover';
    document.head.appendChild(meta);
  }
})();
''';

/// Android only: neutralize safe-area for bottom nav and top header so layout matches browser.
/// Injects <style> + MutationObserver for SPA. iOS: no injection; behavior unchanged.
/// Verification: getComputedStyle(document.querySelector('header.sticky.top-0')).paddingTop === '0px'
///              getComputedStyle(document.querySelector('.safe-area-bottom')).paddingBottom === '0px'
const String _androidDisableSafeAreaBottomPaddingScript = r'''
(function() {
  var styleId = 'webview-template-android-safe-area-override';
  function fixNow() {
    var bottomList = document.querySelectorAll('.safe-area-bottom');
    for (var i = 0; i < bottomList.length; i++) {
      bottomList[i].style.setProperty('padding-bottom', '0', 'important');
    }
    var headerList = document.querySelectorAll('header.sticky.top-0');
    for (var j = 0; j < headerList.length; j++) {
      headerList[j].style.setProperty('padding-top', '0', 'important');
    }
  }
  if (!document.getElementById(styleId)) {
    var style = document.createElement('style');
    style.id = styleId;
    style.textContent = '.safe-area-bottom { padding-bottom: 0 !important; } header.sticky.top-0 { padding-top: 0 !important; }';
    (document.head || document.documentElement).appendChild(style);
  }
  fixNow();
  var observer = new MutationObserver(function() { fixNow(); });
  observer.observe(document.documentElement, { childList: true, subtree: true });
  setTimeout(function() { observer.disconnect(); }, 2000);
})();
''';

/// M1 only: Strictly disable camera and image pickers until M2. Stubs getUserMedia and blocks image/capture file inputs.
const String _disableCameraAndImagePickerScript = r'''
(function() {
  if (typeof navigator === 'undefined' || !navigator.mediaDevices) return;
  var reject = function() {
    return Promise.reject(new DOMException('Camera and image picker are disabled until the next app update.', 'NotAllowedError'));
  };
  if (navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia = reject;
  }
  if (navigator.mediaDevices.getDisplayMedia) {
    navigator.mediaDevices.getDisplayMedia = reject;
  }
  function isImageOrCaptureFileInput(input) {
    if (!input || input.tagName !== 'INPUT' || input.type !== 'file') return false;
    var accept = (input.getAttribute('accept') || '').toLowerCase();
    return input.hasAttribute('capture') || accept.indexOf('image') !== -1;
  }
  document.addEventListener('click', function(e) {
    var el = e.target;
    while (el && el !== document) {
      if (el.tagName === 'INPUT' && isImageOrCaptureFileInput(el)) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return false;
      }
      if (el.tagName === 'LABEL') {
        var control = el.control || (el.htmlFor ? document.getElementById(el.htmlFor) : el.querySelector('input[type=file]'));
        if (control && isImageOrCaptureFileInput(control)) {
          e.preventDefault();
          e.stopImmediatePropagation();
          return false;
        }
      }
      el = el.parentNode;
    }
  }, true);
  document.addEventListener('change', function(e) {
    if (e.target && isImageOrCaptureFileInput(e.target)) {
      e.target.value = '';
      e.preventDefault();
      e.stopImmediatePropagation();
    }
  }, true);
})();
''';

/// M4: Polyfill navigator.share so the web app's share calls open the native share sheet.
const String _nativeSharePolyfillScript = r'''
(function() {
  if (window._nativeSharePolyfill) return;
  window._nativeSharePolyfill = true;
  navigator.share = function(data) {
    return new Promise(function(resolve, reject) {
      try {
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler('native_share', JSON.stringify(data || {}));
          resolve();
        } else {
          reject(new DOMException('Share not available', 'AbortError'));
        }
      } catch(e) {
        reject(e);
      }
    });
  };
  navigator.canShare = function() { return true; };
})();
''';

/// M4: Optional recipe/share-page API — set [AppConfig.shareRecipeApiUrl] (POST with Bearer token).
String _recipeShareInterceptScriptFor(String apiUrl) {
  final u = jsonEncode(apiUrl);
  return '''
(function() {
  if (window._recipeShareIntercepted) return;
  window._recipeShareIntercepted = true;
  var _shareUrlCache = {};
  var apiUrl = $u;
  document.addEventListener('click', function(e) {
    var t = e.target;
    var btn = t.closest ? (t.closest('button[aria-label="Share recipe"]') || t.closest('[aria-label="Share recipe"]')) : null;
    if (!btn) return;
    e.preventDefault();
    e.stopImmediatePropagation();
    e.stopPropagation();
    (async function() {
      try {
        var token = localStorage.getItem('base44_access_token') || localStorage.getItem('token');
        var params = new URLSearchParams(window.location.search);
        var recipeId = params.get('id');
        var titleEl = document.querySelector('[class*="font-extrabold"]') || document.querySelector('h3') || document.querySelector('h1');
        var title = (titleEl ? titleEl.textContent.trim() : '') || 'Recipe';
        if (!recipeId || !token) return;
        var url = _shareUrlCache[recipeId];
        if (!url) {
          var resp = await fetch(apiUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
            body: JSON.stringify({ recipeId: recipeId })
          });
          var data = await resp.json();
          url = data.publicUrl || (data.data && data.data.publicUrl) || '';
          if (url) _shareUrlCache[recipeId] = url;
        }
        if (url && window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler('native_share', JSON.stringify({
            title: title,
            text: 'Check out this recipe: ' + title + '!',
            url: url
          }));
        }
      } catch(err) { console.log('Share error: ' + err); }
    })();
  }, true);
})();
''';
}

/// Intercepts the Subscribe CTA in the "Choose plan" dialog on /selectplan.
/// Detects which plan (annual/monthly) the user selected by checking the
/// border-cornflower class, then calls the dialog_plan_purchase Flutter handler
/// with the correct product ID.
const String _dialogSubscribeInterceptScript = r'''
(function() {
  function interceptDialog() {
    var dialog = document.querySelector('div[role="dialog"]');
    if (!dialog) return;

    var subscribeBtn = null;
    for (var i = 0; i < dialog.children.length; i++) {
      var child = dialog.children[i];
      if (child.tagName === 'BUTTON' &&
          child.className.indexOf('bg-cornflower') !== -1 &&
          child.className.indexOf('absolute') === -1) {
        subscribeBtn = child;
        break;
      }
    }

    if (!subscribeBtn || subscribeBtn._flutterDialogIntercepted) return;

    var clone = subscribeBtn.cloneNode(true);
    subscribeBtn.parentNode.replaceChild(clone, subscribeBtn);
    clone._flutterDialogIntercepted = true;
    clone.style.cursor = 'pointer';

    clone.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopImmediatePropagation();

      var spaceDiv = dialog.querySelector('[class*="space-y-3"]');
      var isMonthly = false;
      if (spaceDiv) {
        for (var j = 0; j < spaceDiv.children.length; j++) {
          if (spaceDiv.children[j].tagName === 'BUTTON') {
            isMonthly = spaceDiv.children[j].className.indexOf('border-cornflower') !== -1;
            break;
          }
        }
      }

      var ids = window.__RC_PRODUCT_IDS || {};
      var productId = isMonthly ? (ids.monthly || '') : (ids.annual || '');

      console.log('Dialog subscribe: ' + productId);
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('dialog_plan_purchase', productId);
      }
    }, true);
  }

  if (document.body) {
    new MutationObserver(function() { interceptDialog(); })
      .observe(document.body, { childList: true, subtree: true });
  }
  setTimeout(interceptDialog, 1500);
})();
''';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key}) {}
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //web view
  late InAppWebViewController _webViewController;
  late PullToRefreshController _pullToRefreshController;
  final InAppBrowser browser = InAppBrowser();
  bool hasGeolocationPermission = false;

  // Subscription controller
  final SubscriptionController _subscriptionController = SubscriptionController();
  
  // Web element interceptor service
  final WebElementInterceptorService _interceptorService = WebElementInterceptorService();
  
  bool _isPageLoaded = false;
  // ignore: unused_field
  int _progress = 0; // Reserved for progress indicator feature
  // ignore: unused_field
  bool _isLoading = false; // Reserved for loading state feature
  Timer? _debounceTimer;
  StreamSubscription<String>? _deepLinkSub;
  @override
  void initState() {
    super.initState();
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: MyColors.kmainColor,
        backgroundColor: Colors.white, // Adding background color for better visibility
        size: PullToRefreshSize.DEFAULT, // Ensures consistent size across platforms
      ),
      onRefresh: () async {
        try {
          if (Platform.isAndroid) {
            await _webViewController.reload();
          } else if (Platform.isIOS) {
            final url = await _webViewController.getUrl();
            if (url != null) {
              await _webViewController.loadUrl(urlRequest: URLRequest(url: url));
            }
          }
        } catch (e) {
          print("Pull to refresh error: $e");
        } finally {
          _pullToRefreshController.endRefreshing();
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CheckInternetConnection.checkInternetFunction();
    });

    // Listen for deep links while app is running (warm start)
    _deepLinkSub = DeepLinkService().linkStream.listen((url) {
      if (kDebugMode) print('🔗 Loading deep link in WebView: $url');
      _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    });
  }

  /// Called from onWebViewCreated once the controller is available.
  void _setupInterceptorsAndHandlers(InAppWebViewController controller) async {
    final subscriptionEnabled = (Platform.isAndroid && AppConfig.deliveryMilestone >= 3) ||
        (Platform.isIOS && AppConfig.deliveryMilestone >= 5);
    if (subscriptionEnabled && !PaymentConfig.testInterceptorsOnly) {
      await _subscriptionController.initialize();
      if (!mounted) return;
      WebInterceptorsConfig.setupInterceptors(_interceptorService, context, controller, _subscriptionController);
    } else if (subscriptionEnabled) {
      WebInterceptorsConfig.setupInterceptors(_interceptorService, context, controller, _subscriptionController);
    } else {
      WebInterceptorsConfig.setupInterceptors(_interceptorService, context, controller, null);
    }
    _interceptorService.setupHandlers(controller);

    // Dialog "Choose plan" Subscribe CTA: detects selected plan and triggers purchase
    if (subscriptionEnabled) {
      controller.addJavaScriptHandler(
        handlerName: 'dialog_plan_purchase',
        callback: (args) async {
          final rawId = args.isNotEmpty ? args[0].toString() : '';
          final isMonthly = rawId.contains('monthly');
          final productId = isMonthly
              ? PaymentConfig.monthlyProductId
              : PaymentConfig.annualProductId;
          final displayName = isMonthly
              ? 'Monthly Subscription'
              : 'Yearly Subscription';

          if (PaymentConfig.testInterceptorsOnly) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Intercepted: $displayName\nProduct: $productId'),
                  backgroundColor: Colors.green.shade700,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
            return;
          }
          await _subscriptionController.purchaseProduct(productId, context);
        },
      );
      controller.addJavaScriptHandler(
        handlerName: 'restore_purchases',
        callback: (args) async {
          if (PaymentConfig.testInterceptorsOnly) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restore purchases (test mode)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
          await _subscriptionController.restorePurchases(context);
        },
      );
      _interceptorService.registerUrlScript('/selectplan', _dialogSubscribeInterceptScript);
    }

    // M4: Recipe share button interceptor + native share handler
    if (AppConfig.deliveryMilestone >= 4) {
      controller.addJavaScriptHandler(
        handlerName: 'native_share',
        callback: (args) async {
          try {
            final raw = args.isNotEmpty ? args[0] : '{}';
            final data = raw is String
                ? Map<String, dynamic>.from(jsonDecode(raw))
                : Map<String, dynamic>.from(raw);
            final title = data['title']?.toString() ?? '';
            final text = data['text']?.toString() ?? '';
            final url = data['url']?.toString() ?? '';

            final parts = <String>[];
            if (text.isNotEmpty) parts.add(text);
            if (url.isNotEmpty) parts.add(url);
            final shareContent = parts.isNotEmpty ? parts.join('\n') : title;

            if (shareContent.isNotEmpty) {
              await SharePlus.instance.share(
                ShareParams(text: shareContent, subject: title),
              );
            }
          } catch (e) {
            if (kDebugMode) print('⚠️ Native share error: $e');
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _pullToRefreshController.dispose();
    _interceptorService.dispose();
    super.dispose();
  }

  List<UserScript> _initialUserScripts() {
    final subIap = (Platform.isAndroid && AppConfig.deliveryMilestone >= 3) ||
        (Platform.isIOS && AppConfig.deliveryMilestone >= 5);
    final rcIdsJson = jsonEncode({
      'monthly': PaymentConfig.monthlyProductId,
      'annual': PaymentConfig.annualProductId,
    });
    return [
      UserScript(
        source: _viewportFitCoverScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
      if (Platform.isAndroid)
        UserScript(
          source: _androidDisableSafeAreaBottomPaddingScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      if (AppConfig.deliveryMilestone < 2)
        UserScript(
          source: _disableCameraAndImagePickerScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      if (subIap)
        UserScript(
          source: '(function(){window.__RC_PRODUCT_IDS=$rcIdsJson;})();',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      if (AppConfig.deliveryMilestone >= 4)
        UserScript(
          source: _nativeSharePolyfillScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      if (AppConfig.deliveryMilestone >= 4 &&
          AppConfig.shareRecipeApiUrl.isNotEmpty)
        UserScript(
          source: _recipeShareInterceptScriptFor(AppConfig.shareRecipeApiUrl),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        bool canGoBack = await _webViewController.canGoBack();
        if (canGoBack) {
          _webViewController.goBack();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: MyColors.kprimaryColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(backgroundColor: MyColors.kprimaryColor, elevation: 0),
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: RefreshIndicator(
            color: MyColors.kmainColor,
            onRefresh: () async {
              await _webViewController.reload();
            },
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(DeepLinkService().consumePendingLink() ?? Changes.mainUrl),
              ),
              initialUserScripts:
                  UnmodifiableListView<UserScript>(_initialUserScripts()),
              pullToRefreshController: _pullToRefreshController,
              onWebViewCreated: (controller) {
                _webViewController = controller;
                // M3 (Android) / M4 (iOS): payment service needs WebView for subscription
                if (!PaymentConfig.testInterceptorsOnly &&
                    ((Platform.isAndroid && AppConfig.deliveryMilestone >= 3) ||
                    (Platform.isIOS && AppConfig.deliveryMilestone >= 5))) {
                  PaymentService().setWebViewController(controller);
                }
                _setupInterceptorsAndHandlers(controller);
              },
              onLoadStart: (controller, url) {
                _isLoading = true;
                _debounceTimer?.cancel();
                setState(() {
                  Changes.mainUrl = url?.toString() ?? '';
                });
              },

              onLoadStop: (controller, url) async {
                Changes.mainUrl = url?.toString() ?? '';

                await controller.evaluateJavascript(source: _viewportFitCoverScript);
                if (Platform.isAndroid) {
                  await controller.evaluateJavascript(source: _androidDisableSafeAreaBottomPaddingScript);
                }
                if (AppConfig.deliveryMilestone < 2) {
                  await controller.evaluateJavascript(source: _disableCameraAndImagePickerScript);
                }
                if (AppConfig.deliveryMilestone >= 4) {
                  await controller.evaluateJavascript(source: _nativeSharePolyfillScript);
                  if (AppConfig.shareRecipeApiUrl.isNotEmpty) {
                    await controller.evaluateJavascript(
                      source: _recipeShareInterceptScriptFor(
                          AppConfig.shareRecipeApiUrl),
                    );
                  }
                }

                // M2: Push notification – pass OneSignal App ID and sync user for notifications
                if (AppConfig.deliveryMilestone >= 2) {
                  await controller.evaluateJavascript(
                    source: 'window.ONESIGNAL_APP_ID = "${AppConfig.oneSignalAppId}";'
                  );
                  await _syncUserEmailWithOneSignal(controller);
                }

                await _interceptorService.injectInterceptors(controller, url);
              },



              onProgressChanged: (controller, progress) {
                _progress = progress;

                if (progress == 100) {
                  // Cancel previous timer
                  _debounceTimer?.cancel();

                  // Delay FAB appearance (e.g., 10 seconds)
                  _debounceTimer = Timer(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _isPageLoaded = true;  // FAB shows after 10s
                        _isLoading = false;
                      });
                    }
                  });
                }
                setState(() {
                  // _progress = progress / 100;
                  // _progressText = progress;  // to show inside of loading
                  // if (_progress > 0.8) {
                  //   setState(() {
                  //     _isLoading = false;
                  //   });
                  //}
                });
              },
              onReceivedError: (controller, request, error) {
                if (kDebugMode) {
                  print(':::url: ${request.url} message ${error.description} code ${error.hashCode} type ${error.type} error ${error.toString()}');
                }

                print('error hashcode: ${error.hashCode}');
                //Navigator.pop(context);
                if (error.description == 'net::ERR_INTERNET_DISCONNECTED') {
                  handleErrorCode(error.description, context);
                }
              },
              // <---------------------------- new code added ---------------------------->
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                print("🔗 onUpdateVisitedHistory =============>: $url");
                if (url.toString().contains("/dashboard")) {
                  print("✅ Redirected to dashboard: $url");
                  // Initialize OneSignal when user reaches dashboard
                  // OneSignalNotification.initialize();
                }
                // Inject element interceptors and URL-conditioned scripts (e.g. addrecipe camera)
                _interceptorService.injectInterceptors(controller, url);
              },
              onConsoleMessage: (controller, consoleMessage) {
                print("JS Console: ${consoleMessage.message}");
              },

              shouldOverrideUrlLoading: (controller, navAction) async {
                final url = navAction.request.url?.toString() ?? '';
                if (kDebugMode) print("🔗 shouldOverrideUrlLoading: $url");

                // M3: Block Stripe checkout redirects (web uses Stripe, app uses RevenueCat)
                final blockedHosts = <String>{'buy.stripe.com', 'checkout.stripe.com'};
                // Store subscription management URLs → open externally
                final externalHosts = <String>{'play.google.com', 'apps.apple.com'};
                if (url.startsWith('http')) {
                  final host = Uri.parse(url).host.toLowerCase();
                  if (blockedHosts.contains(host)) {
                    if (kDebugMode) print('🚫 Blocked Stripe redirect: $url');
                    return NavigationActionPolicy.CANCEL;
                  }
                  if (externalHosts.contains(host)) {
                    if (kDebugMode) print('🔗 Opening store management externally: $url');
                    await _launchExternalUrl(url);
                    return NavigationActionPolicy.CANCEL;
                  }
                }

                // Domains that MUST stay inside WebView (OAuth + your site)
                final allowInAppHosts = <String>{
                  // your app/site domains
                  Uri.parse(Changes.startPointUrl).host,
                  // Google OAuth flow
                  'accounts.google.com',
                  'accounts.youtube.com',
                  'oauth.googleusercontent.com',
                  'apis.google.com',
                  'ssl.gstatic.com',
                  'gstatic.com',
                  // sometimes used in embedded flows
                  'content.googleapis.com',
                  'www.googleapis.com',
                };

                bool isHttp = url.startsWith('http://') || url.startsWith('https://');
                if (isHttp) {
                  final host = Uri.parse(url).host.toLowerCase();

                  // Keep OAuth + your site inside WebView
                  if (allowInAppHosts.contains(host)) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  // Also allow normal in-site navigation by prefix (if you use subpaths)
                  if (url.startsWith(Changes.startPointUrl)) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  // For everything else HTTP(S), default to ALLOW (do NOT force external)
                  // unless you specifically want to deep-link. This preserves cookies/sessions.
                  return NavigationActionPolicy.ALLOW;
                }

                // Non-HTTP schemes -> try external apps
                final lower = url.toLowerCase();
                if (lower.startsWith('mailto:') ||
                    lower.startsWith('tel:') ||
                    lower.startsWith('intent://') ||
                    lower.startsWith('itms-apps://') ||
                    lower.startsWith('tg://') ||
                    lower.startsWith('sms:')) {
                  try {
                    await _launchExternalUrl(url);
                    return NavigationActionPolicy.CANCEL;
                  } catch (_) {
                    return NavigationActionPolicy.CANCEL;
                  }
                }

                // Fallback
                return NavigationActionPolicy.ALLOW;
              },
              // <---------------------------- new code added ---------------------------->
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                supportMultipleWindows: true,
                cacheEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                supportZoom: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                useShouldOverrideUrlLoading: true,
                useOnDownloadStart: true,
                useHybridComposition: true,
                sharedCookiesEnabled: true,
                thirdPartyCookiesEnabled: true,
                domStorageEnabled: true,
                applicationNameForUserAgent: Changes.AppTitle,
                userAgent: Platform.isIOS
                    ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) '
                      'Version/17.0 Mobile/15E148 Safari/604.1 ${Changes.AppTitle}/1.0'
                    : 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) '
                      'Chrome/91.0.4472.120 Mobile Safari/537.36 ${Changes.AppTitle}/1.0',
              ),
              // M2: Camera, image pickers, media – strictly deny until milestone 2 (blocks getUserMedia permission prompts)
              onPermissionRequest: (controller, request) async {
                if (AppConfig.deliveryMilestone < 2) {
                  return PermissionResponse(resources: request.resources, action: PermissionResponseAction.DENY);
                }
                return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
              },
              // M2: Geolocation and other permission prompts
              onGeolocationPermissionsShowPrompt: (controller, origin) async {
                if (AppConfig.deliveryMilestone < 2) {
                  return GeolocationPermissionShowPromptResponse(origin: origin, allow: false, retain: false);
                }
                if (hasGeolocationPermission) {
                  return GeolocationPermissionShowPromptResponse(origin: origin, allow: true, retain: true);
                } else {
                  var status = await Permission.locationWhenInUse.request();
                  if (status.isGranted) {
                    hasGeolocationPermission = true;
                    return GeolocationPermissionShowPromptResponse(origin: origin, allow: true, retain: true);
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Location Permission Required'),
                        content: Text('This app needs access to your location to show it on the map.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              hasGeolocationPermission = false;
                              controller.evaluateJavascript(
                                source: 'navigator.geolocation.getCurrentPosition = function(success, error) { error({code: 1}); };',
                              );
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              hasGeolocationPermission = true;
                              Geolocator.openAppSettings();
                            },
                            child: Text('Open Settings'),
                          ),
                        ],
                      ),
                    );
                    return GeolocationPermissionShowPromptResponse(origin: origin, allow: false, retain: true);
                  }
                }
              },
              onDownloadStartRequest: (controller, downloadStartRequest) async {
                final url = downloadStartRequest.url.toString();
                final filename = downloadStartRequest.suggestedFilename;

                // Debug print
                print('Download requested: $url');
                print('Filename: $filename');

                // Get cookies from CookieManager
                final cookieManager = CookieManager.instance();
                final cookies = await cookieManager.getCookies(url: WebUri(url));
                final cookieHeader = cookies.map((c) => "${c.name}=${c.value}").join("; ");

                print('Cookies found: ${cookies.length}');
                print('Cookie header: $cookieHeader');

                // Create headers with cookies
                final headers = {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                  'Accept': '*/*',
                  'Accept-Encoding': 'gzip, deflate, br',
                  'Connection': 'keep-alive',
                  'Referer': url,
                  if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
                };

                print('Using headers: $headers'); // Debug print

                await _downloadFile(url, filename, headers);
              },
              // Positioned.fill(
            ),
          ),
        ),
        floatingActionButton: _isPageLoaded
            ? FloatingActionButton(
                backgroundColor: MyColors.kmainColor,
                child: const Icon(Icons.share, color: Colors.black),
                onPressed: () async {
                  final currentUrl = await _webViewController.getUrl();
                  if (currentUrl != null && mounted) {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: currentUrl.toString(),
                        subject: 'Check out this page!',
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No webpage loaded to share')),
                    );
                  }
                },
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  Future<void> _downloadFile(String url, String? filename, Map<String, String>? headers) async {
    try {
      final finalFilename = filename ?? url.split('/').last.split('?').first;
      final dio = Dio();

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = path.join(tempDir.path, finalFilename);

      final finalHeaders =
          headers ??
              {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Accept': '*/*',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
              };

      // Step 1: Download file
      await dio.download(
        url,
        tempFilePath,
        options: Options(headers: finalHeaders, responseType: ResponseType.bytes, followRedirects: true, validateStatus: (status) => status! < 500),
      );

      final file = File(tempFilePath);
      final firstBytes = await file.openRead(0, 10).first;
      final htmlHeader = utf8.decode(firstBytes).toLowerCase();
      if (htmlHeader.contains('<!doc') || htmlHeader.contains('<html')) {
        throw Exception("Downloaded content appears to be HTML. Login may be required.");
      }

      if (Platform.isAndroid) {
        // Save using MediaStore
        final mediaStore = MediaStore();
        final saveInfo = await mediaStore.saveFile(
          tempFilePath: tempFilePath,
          dirType: DirType.download,
          dirName: DirName.download,
          relativePath: Changes.androidMediaStoreFolderName,
        );

        if (saveInfo != null) {
          print("Saved to: ${saveInfo.uri}");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File saved to Downloads/${Changes.androidMediaStoreFolderName}")));
        } else {
          throw Exception("File save failed");
        }
      } else if (Platform.isIOS) {
        // Move file to app documents folder
        final appDocDir = await getApplicationDocumentsDirectory();
        final newPath = path.join(appDocDir.path, finalFilename);
        await file.copy(newPath);

        print("File saved to iOS app directory: $newPath");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File saved locally on iOS")));
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Download failed: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Get user email from WebView localStorage and set as OneSignal external user ID
  Future<void> _syncUserEmailWithOneSignal(InAppWebViewController controller) async {
    try {
      // Try to get user email from localStorage (common Base44/auth storage keys)
      final result = await controller.evaluateJavascript(source: """
        (function() {
          // Try to get user data from common localStorage keys
          var userData = localStorage.getItem('user') || 
                         localStorage.getItem('currentUser') || 
                         localStorage.getItem('auth_user') ||
                         localStorage.getItem('userInfo');
          
          if (userData) {
            try {
              var parsed = JSON.parse(userData);
              // Return email from user object
              return parsed.email || parsed.user_email || parsed.userEmail || null;
            } catch(e) {
              return null;
            }
          }
          
          // Try direct email key
          var email = localStorage.getItem('user_email') || 
                      localStorage.getItem('email') ||
                      localStorage.getItem('userEmail');
          if (email) return email;
          
          // Try to extract from JWT token
          var token = localStorage.getItem('token') || 
                      localStorage.getItem('base44_access_token') ||
                      localStorage.getItem('access_token');
          if (token) {
            try {
              var parts = token.split('.');
              if (parts.length === 3) {
                var payload = JSON.parse(atob(parts[1]));
                return payload.email || payload.user_email || payload.sub || null;
              }
            } catch(e) {
              return null;
            }
          }
          
          return null;
        })();
      """);

      if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
        final email = result.toString();
        print('🔔 Found user email in localStorage: $email');
        await NotificationService.setExternalUserId(email);
      } else {
        print('🔔 No user email found in localStorage (user may not be logged in)');
      }
    } catch (e) {
      print('🔔 Error getting user email from localStorage: $e');
    }
  }

}