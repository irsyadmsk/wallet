import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_recording/data/repositories/template_repository.dart';
import 'package:financial_recording/data/services/recurring_service.dart';
import 'package:financial_recording/data/services/seed_service.dart';

/// Using Wallet without an account: records stay in this device's local
/// boxes only (no sync, no family). Signing in later uploads them — see
/// `SyncController.onSignedIn`.
///
/// [started] is set once the user taps "Mulai" on the welcome screen, so
/// the next launch opens straight into the app. Signing out clears it.
abstract class GuestMode {
  static const _key = 'guest_started';
  static final started = false.obs;

  static Future<void> load() async {
    try {
      started.value = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      // Storage unavailable: show the welcome screen again.
    }
  }

  static Future<void> start() async {
    await housekeeping();
    started.value = true;
    await _save(true);
  }

  static Future<void> stop() async {
    started.value = false;
    await _save(false);
  }

  /// What a signed-in device does after each sync (starter data, recurring
  /// posts), done locally instead.
  static Future<void> housekeeping() async {
    await SeedService().seedIfEmpty();
    await QuickTemplateRepository().seedDefaultsIfEmpty();
    await RecurringService().catchUp(DateTime.now());
  }

  static Future<void> _save(bool v) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, v);
    } catch (_) {}
  }
}
