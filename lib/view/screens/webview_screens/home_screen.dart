import 'dart:async';
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

import '../../../constants/my_app_colors.dart';
import '../../../constants/my_app_urls.dart';
import '../../../constants/web_interceptors_config.dart';
import '../../../controllers/error_handle.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../utils/internet_connectivity.dart';
import '../../../services/web_element_interceptor_service.dart';


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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      CheckInternetConnection.checkInternetFunction();

      // Initialize subscription controller
      await _subscriptionController.initialize();
      
      // Setup web interceptors from config file
      // To configure: Go to lib/constants/web_interceptors_config.dart
      WebInterceptorsConfig.setupInterceptors(_interceptorService, context, _webViewController, _subscriptionController);
      
      // Setup handlers AFTER interceptors are registered (fixes timing issue)
      _interceptorService.setupHandlers(_webViewController);
    });
  }

  @override
  void dispose() {
    _pullToRefreshController.dispose();
    _interceptorService.dispose();
    super.dispose();
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
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(backgroundColor: MyColors.kprimaryColor, elevation: 0),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: MyColors.kmainColor,
            onRefresh: () async {
              await _webViewController.reload();
            },
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('${Changes.mainUrl}')),
              pullToRefreshController: _pullToRefreshController,
              onWebViewCreated: (controller) {
                _webViewController = controller;
                // NOTE: setupHandlers will be called AFTER interceptors are registered
                // in addPostFrameCallback to avoid timing issues
              },
              onLoadStart: (controller, url) {
                _isLoading = true;
                _debounceTimer?.cancel();
                setState(() {
                  Changes.mainUrl = url?.toString() ?? '';
                });
              },

              onLoadStop: (controller, url) async {
                // Don't set _isPageLoaded here
                Changes.mainUrl = url?.toString() ?? '';

                // Inject element interceptors for matching URLs
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
                
                // Inject element interceptors for matching URLs
                _interceptorService.injectInterceptors(controller, url);
              },
              onConsoleMessage: (controller, consoleMessage) {
                print("JS Console: ${consoleMessage.message}");
              },

              shouldOverrideUrlLoading: (controller, navAction) async {
                final url = navAction.request.url?.toString() ?? '';
                if (kDebugMode) print("🔗 shouldOverrideUrlLoading: $url");

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

                // Non-HTTP schemes -> try external apps (mailto:, tel:, intent://, whatsapp:)
                final lower = url.toLowerCase();
                if (lower.startsWith('mailto:') ||
                    lower.startsWith('tel:') ||
                    lower.startsWith('intent://') ||
                    //  lower.startsWith('whatsapp://') // add others you support
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
                javaScriptCanOpenWindowsAutomatically: true, // ✅ allow window.open
                supportMultipleWindows: true, // ✅ handle popups
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
                userAgent:
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) '
                    'Chrome/91.0.4472.120 Mobile Safari/537.36 ${Changes.AppTitle}/1.0',
              ),
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
              },
              // Track if the website already asked for geolocation permission
              onGeolocationPermissionsShowPrompt: (controller, origin) async {
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
            ? AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 800),
          child: FloatingActionButton(
            backgroundColor: MyColors.kmainColor,
            child: const Icon(Icons.share, color: Colors.black),
            onPressed: () async {
              final currentUrl = await _webViewController.getUrl();
              if (currentUrl != null) {
                await Share.share(currentUrl.toString(),
                    subject: "Check out this page!");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No webpage loaded to share")),
                );
              }
            },
          ),

        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // <-- move FAB to left

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

}