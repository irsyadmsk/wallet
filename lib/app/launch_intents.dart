import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android launches that should land on a specific page — for now only an
/// e-money card tapped while Wallet was closed or in the background, after
/// the user picked Wallet in Android's NFC "Pilih tindakan" sheet
/// (see MainActivity.kt).
abstract class LaunchIntents {
  static const _channel = MethodChannel('wallet/launch');

  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Calls [onNfc] now if the app was opened by a card tap, and again for
  /// every later tap that brings the running app to the front.
  static Future<void> listen({required VoidCallback onNfc}) async {
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'nfcTapped') onNfc();
    });
    try {
      if (await _channel.invokeMethod<bool>('takeNfcLaunch') == true) onNfc();
    } on MissingPluginException {
      // Tests / other embedders.
    } on PlatformException {
      // Nothing to hand over.
    }
  }

  static void cancel() {
    if (_supported) _channel.setMethodCallHandler(null);
  }
}
