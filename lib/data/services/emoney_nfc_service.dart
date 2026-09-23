import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// Best-effort parse of [balance] into rupiah cents-free integer. Falls
  /// back to null if the card returned something unparsable.
  int? get balanceAmount {
    final digits = balance.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }
}

/// Reads Indonesian NFC prepaid e-money cards (Flazz, Brizzi, TapCash, e-Money
/// Mandiri, etc.) via the `prepaidcard_reader` plugin — Android only, and
/// entirely untested by hand here (no NFC hardware in this environment).
///
/// Real-world reliability varies by card issuer/batch: some cards expose
/// balance cleanly, others protect it behind keys the plugin doesn't have.
/// Never auto-apply a scanned balance to an account — always let the user
/// review [EmoneyCardResult] first, same reasoning as [ReceiptOcrService]
/// for OCR.
class EmoneyNfcService {
  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      return await PrepaidcardReader.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Starts an NFC session and resolves with the first card tapped, or null
  /// if NFC isn't supported/available. Stops the session itself once a card
  /// is read; call [stopSession] to cancel while waiting.
  Future<EmoneyCardResult?> scanOnce() async {
    if (!isSupported) return null;
    final completer = Completer<EmoneyCardResult?>();
    try {
      PrepaidcardReader.instance.startSession((card) async {
        await PrepaidcardReader.instance.stopSession();
        if (!completer.isCompleted) {
          completer.complete(EmoneyCardResult(
            cardName: card.cardName,
            cardNumber: card.cardNumber,
            balance: card.balance,
            cardCode: card.cardCode,
          ));
        }
      }).catchError((Object error) {
        if (!completer.isCompleted) completer.completeError(error);
      });
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }
    return completer.future;
  }

  Future<void> stopSession() async {
    if (!isSupported) return;
    try {
      await PrepaidcardReader.instance.stopSession();
    } catch (_) {}
  }
}
