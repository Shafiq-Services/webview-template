import 'package:flutter/material.dart';
import '../config/payment_config.dart';
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
      if (PaymentConfig.testInterceptorsOnly) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Intercepted: $displayName\nProduct: $buttonName'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
      if (subscriptionController == null) return;
      await subscriptionController.purchaseProduct(buttonName, context);
    },
  );
}
