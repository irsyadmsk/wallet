import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:financial_recording/data/repositories/settings_repository.dart';

/// App-open PIN lock, device-local only (never synced, never leaves the
/// device). Stores a salted SHA-256 hash — never the raw PIN — so reading
/// the Hive box on disk doesn't reveal it.
class PinLockService {
  final _settings = SettingsRepository();

  bool get isEnabled => _settings.current.pinEnabled && (_settings.current.pinHash?.isNotEmpty ?? false);

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _hash(pin, salt);
    final s = _settings.current
      ..pinHash = '$salt:$hash:${pin.length}'
      ..pinEnabled = true;
    await _settings.save(s);
  }

  Future<void> disable() async {
    final s = _settings.current
      ..pinHash = null
      ..pinEnabled = false;
    await _settings.save(s);
  }

  /// Stored as `salt:hash:length`. PINs saved before the length was
  /// recorded are `salt:hash` — for those this returns null and the lock
  /// screen tries every allowed length instead.
  int? get pinLength {
    final parts = _settings.current.pinHash?.split(':');
    if (parts == null || parts.length < 3) return null;
    return int.tryParse(parts[2]);
  }

  bool verify(String pin) {
    final stored = _settings.current.pinHash;
    if (stored == null || !stored.contains(':')) return false;
    final parts = stored.split(':');
    return _hash(pin, parts[0]) == parts[1];
  }

  String _hash(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  String _randomSalt() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
