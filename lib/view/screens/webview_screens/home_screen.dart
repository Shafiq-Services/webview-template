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
import 'package:webview_demo/constants/my_app_colors.dart';
import 'package:webview_demo/constants/my_app_urls.dart';
import 'package:webview_demo/controllers/error_handle.dart';
import 'package:webview_demo/utils/internet_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_demo/services/one_signal_notification.dart';
import 'package:dio/dio.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:media_store_plus/media_store_plus.dart' as ms;
import 'package:path/path.dart' as path;

class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key,
  }) {}
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //web view
  late InAppWebViewController _webViewController;
  late PullToRefreshController _pullToRefreshController;
  final InAppBrowser browser = InAppBrowser();
  double _progress = 0.0; // Variable to hold the progress percentage
  bool hasGeolocationPermission = false;
  bool _isLoading = true;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: MyColors.kmainColor,
        backgroundColor: Colors.white,  // Adding background color for better visibility
        size: PullToRefreshSize.DEFAULT,  // Ensures consistent size across platforms
      ),
      onRefresh: () async {
        try {
          if (Platform.isAndroid) {
            await _webViewController.reload();
          } else if (Platform.isIOS) {
            final url = await _webViewController.getUrl();
            if (url != null) {
              await _webViewController.loadUrl(
                urlRequest: URLRequest(url: url),
              );
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
    });
  }

  @override
  void dispose() {
    _pullToRefreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey _loaderKey = GlobalKey();
    double baseSize = 55.0;
    double scaleFactor = MediaQuery.of(context).size.shortestSide /
        360; // Adjust the divisor as needed
    double containerSize = baseSize * scaleFactor;

    return WillPopScope(
      onWillPop: () async {
        if (_webViewController != null) {
          final currentUrl = (await _webViewController.getUrl())?.toString();
          bool canGoBack = await _webViewController.canGoBack();
          if (canGoBack) {
            _webViewController.goBack();
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(
            backgroundColor: MyColors.kprimaryColor,
            elevation: 0,
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: MyColors.kmainColor,
            onRefresh: () async {
              if (_webViewController != null) {
                await _webViewController.reload();
              }
            },
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('${Changes.mainUrl}')),
              pullToRefreshController: _pullToRefreshController,
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  Changes.mainUrl = url?.toString() ?? '';
                  _isLoading = true;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  Changes.mainUrl = url?.toString() ?? '';
                  _isLoading = false;
                });
              },
              onProgressChanged: (controller, progress) {
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
                  print(
                      ':::url: ${request.url} message ${error.description} code ${error.hashCode} type ${error.type} error ${error.toString()}');
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
                  // Optionally, stop loading indicator
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onConsoleMessage: (controller, consoleMessage) {
                print("JS Console: ${consoleMessage.message}");
              },

              shouldOverrideUrlLoading: (controller, navAction) async {
                final url = navAction.request.url.toString();
                print("🔗 Attempting URL: $url");

                // Allow navigation within our main domain
                if (url.contains(Changes.startPointUrl)) {
                  return NavigationActionPolicy.ALLOW;
                }

                // Handle external URLs (Facebook, WhatsApp, etc.)
                try {
                  await _launchExternalUrl(url);
                  return NavigationActionPolicy.CANCEL;
                } catch (e) {
                  print("Failed to launch external URL: $e");
                  return NavigationActionPolicy.ALLOW;
                }
              },
              // <---------------------------- new code added ---------------------------->
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                cacheEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                supportZoom: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                useShouldOverrideUrlLoading: true,
                useOnDownloadStart: true,
                useHybridComposition: true,
                sharedCookiesEnabled: true, // ✅ Keep session working
                thirdPartyCookiesEnabled:
                    true, // ✅ Needed for auth across subdomains
                domStorageEnabled:
                    true, // ✅ DOM Storage is mandatory for modern SPAs
              ),
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              // Track if the website already asked for geolocation permission
              onGeolocationPermissionsShowPrompt: (controller, origin) async {
                if (hasGeolocationPermission) {
                  return GeolocationPermissionShowPromptResponse(
                      origin: origin, allow: true, retain: true);
                } else {
                  var status = await Permission.locationWhenInUse.request();
                  if (status.isGranted) {
                    hasGeolocationPermission = true;
                    return GeolocationPermissionShowPromptResponse(
                        origin: origin, allow: true, retain: true);
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Location Permission Required'),
                        content: Text(
                            'This app needs access to your location to show it on the map.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              hasGeolocationPermission = false;
                              controller.evaluateJavascript(
                                source:
                                    'navigator.geolocation.getCurrentPosition = function(success, error) { error({code: 1}); };',
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
                    return GeolocationPermissionShowPromptResponse(
                        origin: origin, allow: false, retain: true);
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
                final cookieHeader =
                    cookies.map((c) => "${c.name}=${c.value}").join("; ");

                print('Cookies found: ${cookies.length}');
                print('Cookie header: $cookieHeader');

                // Create headers with cookies
                final headers = {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
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
      ),
    );
  }

  Future<void> _downloadFile(
      String url, String? filename, Map<String, String>? headers) async {
    try {
      final finalFilename = filename ?? url.split('/').last.split('?').first;
      final dio = Dio();

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = path.join(tempDir.path, finalFilename);

      final finalHeaders = headers ??
          {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          };

      // Step 1: Download file
      await dio.download(
        url,
        tempFilePath,
        options: Options(
          headers: finalHeaders,
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      final file = File(tempFilePath);
      final firstBytes = await file.openRead(0, 10).first;
      final htmlHeader = utf8.decode(firstBytes).toLowerCase();
      if (htmlHeader.contains('<!doc') || htmlHeader.contains('<html')) {
        throw Exception(
            "Downloaded content appears to be HTML. Login may be required.");
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File saved to Downloads/${Changes.androidMediaStoreFolderName}")),
          );
        } else {
          throw Exception("File save failed");
        }
      } else if (Platform.isIOS) {
        // Move file to app documents folder
        final appDocDir = await getApplicationDocumentsDirectory();
        final newPath = path.join(appDocDir.path, finalFilename);
        await file.copy(newPath);

        print("File saved to iOS app directory: $newPath");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File saved locally on iOS")),
        );
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
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

  void _openWhatsApp(String url) async {
    // String url = 'https://wa.me/$phoneNumber';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final telScheme = 'tel:';
    if (phoneNumber.startsWith(telScheme)) {
      final Uri uri = Uri.parse(phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $phoneNumber');

        // Handle the error gracefully (e.g., show an error message to the user).
      }
    } else {
      print('Invalid phone number format: $phoneNumber');
      // Handle the error gracefully (e.g., show an error message to the user).
    }
  }
}
