import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Handles incoming deep links (custom scheme + App Links / Universal Links)
/// and converts them to URLs the WebView can load.
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;
  DeepLinkService._();

  final _appLinks = AppLinks();
  final _linkController = StreamController<String>.broadcast();
  StreamSubscription? _sub;
  String? _pendingLink;

  Stream<String> get linkStream => _linkController.stream;

  /// Returns and clears the pending cold-start link (call once from HomeScreen).
  String? consumePendingLink() {
    final link = _pendingLink;
    _pendingLink = null;
    return link;
  }

  Future<void> initialize() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        final url = _resolveUrl(initialUri);
        if (url != null) {
          _pendingLink = url;
          if (kDebugMode) print('🔗 Deep link (cold start): $url');
        }
      }
    } catch (e) {
      if (kDebugMode) print('🔗 No initial deep link: $e');
    }

    _sub = _appLinks.uriLinkStream.listen((uri) {
      final url = _resolveUrl(uri);
      if (url != null) {
        if (kDebugMode) print('🔗 Deep link (warm): $url');
        _linkController.add(url);
      }
    });
  }

  /// Convert any incoming URI to a full https URL for the WebView.
  String? _resolveUrl(Uri uri) {
    final baseHost = Uri.parse(AppConfig.startPointUrl).host;

    // Custom scheme: myapp://path → https startPointUrl + path + query
    if (uri.scheme == AppConfig.customScheme) {
      final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '${AppConfig.startPointUrl.replaceAll(RegExp(r'/$'), '')}$path$query';
    }

    // App Links / Universal Links: already a full URL on a known domain
    if (AppConfig.deepLinkDomains.contains(uri.host.toLowerCase())) {
      return uri.toString();
    }

    // Fallback: if host matches base URL host, allow it
    if (uri.host.toLowerCase() == baseHost.toLowerCase()) {
      return uri.toString();
    }

    return null;
  }

  void dispose() {
    _sub?.cancel();
    _linkController.close();
  }
}
