import 'package:flutter/material.dart';
import '../view/components/custom_error.dart';
import '../view/components/no_internet_error.dart';

void handleErrorCode(String errorMessage, BuildContext context) {
  if (errorMessage.contains('ERR_INTERNET_DISCONNECTED')) {
    showNoInternetErrorScreen(context);
  } else {
    showCustomErrorScreen(errorMessage, context);
  }
}

void showCustomErrorScreen(String errorMessage, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CustomErrorScreen(errorMessage: errorMessage),
    ),
  );
}

void showNoInternetErrorScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NoInternetErrorScreen(),
    ),
  );
}

