/// Selector type for element matching
enum SelectorType {
  /// Standard CSS selector
  css,
  
  /// XPath selector for precise element targeting
  xpath,
  
  /// Text content matching (case-insensitive)
  text,
}

/// Model for configuring web element interception
/// 
/// Use this to intercept clicks on specific HTML elements in the WebView
/// and execute custom Flutter actions instead.
/// 
/// Example:
/// ```dart
/// WebElementInterceptor(
///   url: 'https://example.com/pricing',
///   elementSelector: '//button[@class="exact-class-name"]',
///   selectorType: SelectorType.xpath,
///   action: () async {
///     print('Custom action executed!');
///   },
///   disableOriginalClick: true,
/// )
/// ```
class WebElementInterceptor {
  /// The URL pattern to match (can be partial, case-insensitive)
  /// Example: '/pricing', 'checkout', 'https://example.com/subscribe'
  final String url;

  /// Selector for the HTML element
  /// Examples:
  /// - CSS: 'button.subscribe-btn', '#checkout-button'
  /// - XPath: '//button[@class="exact-class"]', '//div[@id="unique"]/button[1]'
  /// - Text: 'Subscribe Now', 'Start Trial' (exact text match)
  final String elementSelector;

  /// Type of selector (css, xpath, or text)
  final SelectorType selectorType;

  /// The Flutter action to execute when element is tapped
  /// If null, this is a hide-only interceptor (no click action)
  final Future<void> Function()? action;

  /// If true, prevents the original HTML element's click event from firing
  /// If false, executes both the original and custom action
  final bool disableOriginalClick;

  /// If true, hides the element instead of/in addition to intercepting clicks
  final bool hideElement;

  /// Optional: Delay in milliseconds before checking for element (default: 500ms)
  /// Useful if the element loads dynamically after page load
  final int delayMs;

  /// Optional: Maximum retry attempts to find element (default: 10)
  final int maxRetries;

  /// Optional: Interval between retries in milliseconds (default: 1000ms)
  final int retryIntervalMs;

  /// Optional: Additional data to extract from element on click
  /// Examples: ['textContent', 'innerHTML', 'data-price']
  final List<String>? extractData;

  WebElementInterceptor({
    required this.url,
    required this.elementSelector,
    this.selectorType = SelectorType.xpath,
    this.action,
    this.disableOriginalClick = true,
    this.hideElement = true,
    this.delayMs = 1500,
    this.maxRetries = 15,
    this.retryIntervalMs = 1000,
    this.extractData,
  });

  /// Generates a unique ID for this interceptor (used internally)
  String get interceptorId => '${url}_${elementSelector.hashCode}'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
}

