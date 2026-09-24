import 'package:url_launcher/url_launcher.dart';

/// Wallet is one of the irsyads.com spaces (situs utama, Academy, Ruang,
/// Wallet). The main site links here from its "Ruang Irsyads" switcher and
/// footer; these are the links back.
abstract class Ecosystem {
  static final Uri home = Uri.parse('https://irsyads.com');

  /// Opens irsyads.com in a new tab (web) or the external browser (mobile).
  static Future<void> openHome() => launchUrl(home, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}
