import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/web_element_interceptor_model.dart';

/// Service for intercepting and handling web element clicks in WebView
/// 
/// This service allows you to register multiple element interceptors
/// that will automatically inject JavaScript to intercept clicks on specific
/// HTML elements and execute custom Flutter actions.
class WebElementInterceptorService {
  /// List of registered interceptors
  final List<WebElementInterceptor> _interceptors = [];

  /// Register a new element interceptor
  /// 
  /// Example:
  /// ```dart
  /// service.registerInterceptor(
  ///   WebElementInterceptor(
  ///     url: '/pricing',
  ///     elementSelector: '//button[@class="exact-class"]',
  ///     selectorType: SelectorType.xpath,
  ///     action: (data) async => print('Clicked! Data: $data'),
  ///     disableOriginalClick: true,
  ///   ),
  /// );
  /// ```
  void registerInterceptor(WebElementInterceptor interceptor) {
    _interceptors.add(interceptor);
    if (kDebugMode) {
      print('🔧 Interceptor registered for URL: ${interceptor.url} (${interceptor.selectorType})');
    }
  }

  /// Register multiple interceptors at once
  void registerMultipleInterceptors(List<WebElementInterceptor> interceptors) {
    _interceptors.addAll(interceptors);
    if (kDebugMode) {
      print('🔧 ${interceptors.length} interceptors registered');
    }
  }

  /// Clear all registered interceptors
  void clearInterceptors() {
    _interceptors.clear();
  }

  /// Setup JavaScript handlers for all registered interceptors
  /// Call this in onWebViewCreated
  void setupHandlers(InAppWebViewController controller) {
    if (kDebugMode) {
      print('🔧 Setting up handlers for ${_interceptors.length} interceptors...');
    }
    
    for (var interceptor in _interceptors) {
      // Skip hide-only interceptors (no action)
      if (interceptor.action == null) continue;
      
      final handlerName = 'interceptor_${interceptor.interceptorId}';
      
      controller.addJavaScriptHandler(
        handlerName: handlerName,
        callback: (args) async {
          try {
            if (kDebugMode) {
              print('🎯 Interceptor triggered: ${interceptor.url}');
            }
            await interceptor.action!();
          } catch (e) {
            print('❌ ERROR in interceptor: $e');
          }
        },
      );
    }

    if (kDebugMode) {
      print('✅ ${_interceptors.length} interceptor handlers set up');
    }
  }

  /// Inject JavaScript for matching interceptors on current URL
  /// Call this in onLoadStop and onUpdateVisitedHistory
  Future<void> injectInterceptors(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    if (url == null) return;

    final urlString = url.toString().toLowerCase();
    final matchingInterceptors = _interceptors.where(
      (interceptor) => urlString.contains(interceptor.url.toLowerCase()),
    ).toList();

    if (matchingInterceptors.isEmpty) return;

    if (kDebugMode) {
      print('🧩 Injecting ${matchingInterceptors.length} interceptor(s) for: $urlString');
    }

    for (var interceptor in matchingInterceptors) {
      await _injectSingleInterceptor(controller, interceptor);
    }
  }

  /// Inject JavaScript for a single interceptor
  Future<void> _injectSingleInterceptor(
    InAppWebViewController controller,
    WebElementInterceptor interceptor,
  ) async {
    final handlerName = 'interceptor_${interceptor.interceptorId}';
    final jsCode = _generateInterceptorJS(interceptor, handlerName);

    try {
      await controller.evaluateJavascript(source: jsCode);
      if (kDebugMode) {
        print('✅ JS injected for: ${interceptor.elementSelector}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ JS injection failed for ${interceptor.elementSelector}: $e');
      }
    }
  }

  /// Generate JavaScript code for intercepting element clicks
  String _generateInterceptorJS(
    WebElementInterceptor interceptor,
    String handlerName,
  ) {
    final disableClick = interceptor.disableOriginalClick.toString();
    final hideElement = interceptor.hideElement.toString();
    final hasAction = (interceptor.action != null).toString();
    final selector = _escapeJavaScriptString(interceptor.elementSelector);
    final selectorType = interceptor.selectorType.toString().split('.').last;
    final delayMs = interceptor.delayMs;
    final maxRetries = interceptor.maxRetries;
    final retryInterval = interceptor.retryIntervalMs;
    final extractData = interceptor.extractData != null 
        ? interceptor.extractData!.map((e) => "'$e'").join(',') 
        : '';

    return """
(function() {
  console.log('🔹 Element interceptor loaded for: $selector (type: $selectorType)');
  
  let attemptCount = 0;
  const maxAttempts = $maxRetries;
  const retryDelay = $retryInterval;
  const selectorType = '$selectorType';
  const extractDataKeys = [$extractData];
  
  function findElement() {
    let element = null;
    
    if (selectorType === 'xpath') {
      // XPath selector - most precise
      const result = document.evaluate(
        '$selector',
        document,
        null,
        XPathResult.FIRST_ORDERED_NODE_TYPE,
        null
      );
      element = result.singleNodeValue;
    } else if (selectorType === 'text') {
      // Text matching - find by exact text content
      const walker = document.createTreeWalker(
        document.body,
        NodeFilter.SHOW_ELEMENT,
        null,
        false
      );
      
      while (walker.nextNode()) {
        const node = walker.currentNode;
        if (node.textContent.trim().toLowerCase().includes('$selector'.toLowerCase())) {
          element = node;
          break;
        }
      }
    } else {
      // CSS selector
      element = document.querySelector('$selector');
    }
    
    return element;
  }
  
  function findAndAttachInterceptor() {
    attemptCount++;
    
    const element = findElement();
    
    if (!element) {
      if (attemptCount < maxAttempts) {
        console.log('⏳ Element not found, retrying... (attempt ' + attemptCount + '/' + maxAttempts + ')');
        setTimeout(findAndAttachInterceptor, retryDelay);
      } else {
        console.log('⚠️ Element not found after ' + maxAttempts + ' attempts');
      }
      return;
    }
    
    // Check if already processed
    if (element._flutterInterceptorAttached) {
      console.log('✅ Interceptor already attached');
      return;
    }
    
    element._flutterInterceptorAttached = true;
    console.log('✅ Element found, processing...');
    
    // Hide element if requested
    if ($hideElement) {
      element.style.display = 'none';
      element.style.visibility = 'hidden';
      element.style.opacity = '0';
      element.style.pointerEvents = 'none';
      console.log('🙈 Element hidden');
    }
    
    // Setup click interception if action is provided
    if ($hasAction) {
      let targetElement = element;
      
      // Disable original click handlers if requested
      if ($disableClick) {
        element.onclick = null;
        element.removeAttribute('href');
        
        // Remove all existing click listeners by cloning
        const clone = element.cloneNode(true);
        element.parentNode.replaceChild(clone, element);
        targetElement = clone;
        targetElement._flutterInterceptorAttached = true;
      }
      
      // Attach new click handler
      targetElement.addEventListener('click', function(e) {
        if ($disableClick) {
          e.preventDefault();
          e.stopImmediatePropagation();
          console.log('🧩 Click intercepted (original disabled)');
        } else {
          console.log('🧩 Click intercepted (original allowed)');
        }
        
        // Extract data if requested
        const extractedData = [];
        if (extractDataKeys.length > 0) {
          extractDataKeys.forEach(key => {
            if (key === 'textContent') {
              extractedData.push(targetElement.textContent.trim());
            } else if (key === 'innerHTML') {
              extractedData.push(targetElement.innerHTML);
            } else if (key.startsWith('data-')) {
              extractedData.push(targetElement.getAttribute(key));
            } else {
              extractedData.push(targetElement[key]);
            }
          });
        }
        
        // Call Flutter handler
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler('$handlerName', ...extractedData);
        } else {
          console.warn('⚠️ Flutter handler not available');
        }
      }, true);
      
      // Visual indication
      if ($disableClick && !$hideElement) {
        targetElement.style.cursor = 'pointer';
      }
      
      console.log('✅ Click interceptor attached');
    }
  }
  
  // Observe DOM for dynamic elements (with safety check)
  function startObserver() {
    if (document.body) {
      const observer = new MutationObserver(() => {
        const element = findElement();
        if (element && !element._flutterInterceptorAttached) {
          findAndAttachInterceptor();
        }
      });
      
      observer.observe(document.body, { 
        childList: true, 
        subtree: true 
      });
      console.log('🔍 DOM observer started');
    } else {
      console.log('⏳ document.body not ready, waiting...');
      setTimeout(startObserver, 100);
    }
  }
  
  startObserver();
  
  // Initial attempt with delay
  setTimeout(findAndAttachInterceptor, $delayMs);
})();
""";
  }

  /// Escape JavaScript string to prevent injection attacks
  String _escapeJavaScriptString(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  /// Dispose resources
  void dispose() {
    _interceptors.clear();
  }
}

