import 'package:media_store_plus/media_store_plus.dart';
import 'package:webview_demo/controllers/inialize_web_view_features.dart';
import 'package:webview_demo/services/one_signal_notification.dart';

class InitilizeApp {
  //check Internet
  static callFunctions() async {
    //this function checks internet
    // await CheckInternetConnection.checkInternetFunction();
    // this function snippet enables web contents debugging for the in-app web view on Android
    initializeWebViewFeatures();
    
    // Initialize OneSignal (non-blocking)
    OneSignalNotification.initialize();
    
    // requestPermissions();
  }
}
