import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:prepaidcard_reader/prepaidcard_reader.dart';

/// Raw fields read off a tapped e-money card. Always shown to the user for
/// confirmation before touching an account balance — see [EmoneyNfcService]
/// for why this can't be trusted blindly.
class EmoneyCardResult {
  final String cardName;
  final String cardNumber;
  final String balance;
  final String cardCode;

  const EmoneyCardResult({
    required this.cardName,
    required this.cardNumber,
    required this.balance,
    required this.cardCode,
  });

  /// Best-effort parse of [balance] into rupiah. Null when the card returned
  /// something unparsable.
  int? get balanceAmount {
    final digits = balance.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }
}

enum NfcStatus { unsupported, off, on }

/// A scan that ended without a card result, with a message for the user.
class EmoneyScanException implements Exception {
  const EmoneyScanException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads Indonesian NFC prepaid e-money cards (e-Money Mandiri, Brizzi,
/// TapCash, Flazz) through the `prepaidcard_reader` plugin, vendored and
/// patched in `packages/prepaidcard_reader` — Android only.
///
/// Balance reads vary by issuer and card batch, so a scanned balance is
/// never applied automatically; the user reviews [EmoneyCardResult] first.
class EmoneyNfcService {
  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// How long to wait for a card before giving up.
  static const scanTimeout = Duration(seconds: 45);

  Future<NfcStatus> status() async {
    if (!isSupported) return NfcStatus.unsupported;
    try {
      switch (await PrepaidcardReader.instance.status()) {
        case 'on':
          return NfcStatus.on;
        case 'off':
          return NfcStatus.off;
        default:
          return NfcStatus.unsupported;
      }
    } catch (_) {
      return NfcStatus.unsupported;
    }
  }

  Future<void> openSettings() async {
    try {
      await PrepaidcardReader.instance.openSettings();
    } catch (_) {}
  }

  /// Waits for one card tap and returns what was read. Throws
  /// [EmoneyScanException] with a user-facing message when NFC is off or
  /// missing, the card can't be read, or nothing is tapped in time.
  Future<EmoneyCardResult> scanOnce() async {
    if (!isSupported) throw const EmoneyScanException('Pindai kartu hanya tersedia di aplikasi Android.');
    final completer = Completer<EmoneyCardResult>();

    void fail(String message) {
      if (!completer.isCompleted) completer.completeError(EmoneyScanException(message));
    }

    try {
      await PrepaidcardReader.instance.startSession(
        (card) async {
          if (completer.isCompleted) return;
          if (card.cardCode == 'ktp') {
            fail('Itu kartu e-KTP, bukan kartu e-money.');
            return;
          }
          if (card.cardName.isEmpty && card.cardNumber.isEmpty && card.balance.isEmpty) {
            fail(_friendly(card.anotherInfo));
            return;
          }
          completer.complete(EmoneyCardResult(
            cardName: card.cardName,
            cardNumber: card.cardNumber,
            balance: card.balance,
            cardCode: card.cardCode,
          ));
        },
        onError: (error) async => fail(_friendly(error.message)),
      );
    } on PlatformException catch (e) {
      fail(switch (e.code) {
        'off' => 'NFC sedang nonaktif. Aktifkan NFC lalu coba lagi.',
        'unsupported' => 'HP ini tidak memiliki NFC.',
        _ => e.message ?? 'Tidak bisa memulai pemindaian NFC.',
      });
    } catch (e) {
      fail('Tidak bisa memulai pemindaian NFC: $e');
    }

    try {
      return await completer.future.timeout(
        scanTimeout,
        onTimeout: () => throw const EmoneyScanException(
          'Tidak ada kartu terbaca. Tempelkan kartu tepat di area NFC (biasanya tengah belakang HP) '
          'dan tahan 2–3 detik tanpa digeser.',
        ),
      );
    } finally {
      // Not awaited: the reply isn't needed to show the result.
      unawaited(stopSession());
    }
  }

  Future<void> stopSession() async {
    if (!isSupported) return;
    try {
      await PrepaidcardReader.instance.stopSession();
    } catch (_) {}
  }

  static String _friendly(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('tidak dikenal') || r.contains('not e-money')) {
      return 'Kartu tidak dikenali. Yang didukung: e-Money Mandiri, Brizzi (BRI), TapCash (BNI), dan Flazz (BCA).';
    }
    if (r.contains('terlepas') || r.contains('tag was lost') || r.contains('ioexception')) {
      return 'Kartu terlepas sebelum selesai dibaca. Tahan kartu 2–3 detik tanpa digeser.';
    }
    if (r.contains('ktp')) return 'Itu kartu e-KTP, bukan kartu e-money.';
    return raw.isEmpty ? 'Gagal membaca kartu. Coba lagi.' : 'Gagal membaca kartu ($raw).';
  }
}
