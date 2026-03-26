import 'package:flutter/material.dart';
import 'payment_config.dart';
import '../controllers/subscription_controller.dart';
import '../services/web_element_interceptor_service.dart';
import '../models/web_element_interceptor_model.dart';
import '../utils/subscription_helpers.dart';

class WebViewConfig {
  static final subscriptionButtons = <String, List<SubscriptionButton>>{
    '/selectplan': [
      SubscriptionButton(
        xpath:
            '//*[@id="root"]/div[1]/div[1]/main/div/div/div/div[3]/div/button[1]',
        productId: PaymentConfig.annualProductId,
        displayName: 'Yearly Subscription',
      ),
    ],
  };

  static final hideElements = <HideElement>[];

  static void setupInterceptors(
    WebElementInterceptorService service,
    BuildContext context,
    dynamic webViewController, [
    SubscriptionController? subscriptionController,
  ]) {
    final allInterceptors = <WebElementInterceptor>[];

    subscriptionButtons.forEach((url, buttons) {
      for (var btn in buttons) {
        allInterceptors.add(
          createSubscriptionButton(
            url: url,
            elementSelector: btn.xpath,
            buttonName: btn.productId,
            displayName: btn.displayName,
            context: context,
            subscriptionController: subscriptionController,
          ),
        );
      }
    });

    service.registerMultipleInterceptors(allInterceptors);
  }
}

class SubscriptionButton {
  final String xpath;
  final String productId;
  final String displayName;

  SubscriptionButton({
    required this.xpath,
    required this.productId,
    required this.displayName,
  });
}

class HideElement {
  final String url;
  final String xpath;

  HideElement({required this.url, required this.xpath});
}

class WebInterceptorsConfig {
  static void setupInterceptors(
    WebElementInterceptorService service,
    BuildContext context,
    dynamic webViewController, [
    SubscriptionController? subscriptionController,
  ]) {
    WebViewConfig.setupInterceptors(
        service, context, webViewController, subscriptionController);
  }
}
