import 'package:flutter/material.dart';
import '../controllers/subscription_controller.dart';
import '../models/web_element_interceptor_model.dart';

/// Helper to create subscription button interceptors
WebElementInterceptor createSubscriptionButton({
  required String url,
  required String elementSelector,
  required String buttonName,
  required String displayName,
  required BuildContext context,
  required SubscriptionController? subscriptionController,
}) {
  return WebElementInterceptor(
    url: url,
    elementSelector: elementSelector,
    hideElement: false,
    action: () async {
      if (subscriptionController == null) return;
      // buttonName IS the product ID (e.g., 'monthly_premium')
      await subscriptionController.purchaseProduct(buttonName, context);
    },
  );
}
