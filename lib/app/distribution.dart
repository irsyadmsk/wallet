import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Optional build-time override: `--dart-define=WALLET_CHANNEL=play`.
/// Release builds no longer need it — the app asks Android which store
/// installed it (see [detectDistribution]), so the Play Store and the
/// GitHub APK can ship the exact same code, which Shorebird patches need.
const String kDistributionChannel = String.fromEnvironment('WALLET_CHANNEL');

const _playStore = 'com.android.vending';
bool _installedFromPlay = false;

/// Google Play requires its own billing for tips/donations to the
/// developer, so the QRIS donation page is hidden for Play installs.
bool get kDonationsEnabled => kDistributionChannel != 'play' && !_installedFromPlay;

/// Reads the installing store once at startup (Android only).
Future<void> detectDistribution() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    final installer = await const MethodChannel('wallet/launch').invokeMethod<String>('installer');
    _installedFromPlay = installer == _playStore;
  } on MissingPluginException {
    // Tests / other embedders.
  } on PlatformException {
    // Unknown source: treat as a side-loaded APK.
  }
}
