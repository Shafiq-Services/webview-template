import 'package:connectivity_plus/connectivity_plus.dart';

class CheckInternetConnection {
  static bool checkInternet = true;

  static Future<bool> isConnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  static Future<void> checkInternetFunction() async {
    checkInternet = await isConnected();
  }
}
