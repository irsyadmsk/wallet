import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

typedef NfcTagCallback = Future<void> Function(CardModel cardModel);
typedef NfcErrorCallback = Future<void> Function(NfcError error);

class PrepaidcardReader {
  static const MethodChannel channel = MethodChannel('read_card_nfc');
  PrepaidcardReader._() {
    channel.setMethodCallHandler(_handleMethodCall);
  }
  static PrepaidcardReader? _instance;

  static PrepaidcardReader get instance => _instance ??= PrepaidcardReader._();

  NfcTagCallback? _onDiscovered;

  NfcErrorCallback? onError;

  bool _stopOnDiscovered = false;

  Future<bool> isAvailable() async {
    return channel
        .invokeMethod<bool>('Nfc#isAvailable')
        .then<bool>((bool? value) => value ?? false);
  }

  Future<void> startSession(
    NfcTagCallback onDiscovered, {
    bool stopOnDiscovered = false,
    Set<NfcPollingOption>? pollingOptions,
    String alertMessage = "",
    NfcErrorCallback? onError,
  }) async {
    _onDiscovered = onDiscovered;
    _stopOnDiscovered = stopOnDiscovered;
    // Wallet patch: was `onError = onError`, which never set the field.
    this.onError = onError;
    pollingOptions ??= NfcPollingOption.values.toSet();
    return channel.invokeMethod('Nfc#startSession', {
      'alertMessage': alertMessage,
    });
  }

  Future<void> stopSession({
    String alertMessage = "",
    String errorMessage = "",
  }) async {
    _onDiscovered = null;
    onError = null;
    _stopOnDiscovered = false;
    return channel.invokeMethod('Nfc#stopSession', {
      'alertMessage': alertMessage,
      'errorMessage': errorMessage,
    });
  }

  Future<void> disposeTag(String handle) async {
    return channel.invokeMethod('Nfc#disposeTag', {'handle': handle});
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDiscovered':
        _handleOnDiscovered(call);
        break;
      case 'onError':
        _handleOnError(call);
        break;
      default:
        throw ('Not implemented: ${call.method}');
    }
  }

  void _handleOnDiscovered(MethodCall call) async {
    try {
      CardModel cardModel = CardModel.fromJson(jsonDecode(call.arguments));
      if (_onDiscovered != null) await _onDiscovered!(cardModel);
    } catch (e) {
      if (_onDiscovered != null) {
        _onDiscovered!(
          CardModel(
            "",
            "",
            "",
            "",
            "$e",
            '',
          ),
        );
      }
    } finally {
      if (_stopOnDiscovered) {
        stopSession();
      }
    }
  }

  void _handleOnError(MethodCall call) async {
    final handler = onError;
    if (handler != null) {
      await handler(NfcError(NfcErrorType.unknown, call.arguments?.toString() ?? 'Gagal membaca kartu', null));
    }
  }

  /// `unsupported` (no NFC hardware), `off` (switched off) or `on`.
  Future<String> status() async => await channel.invokeMethod<String>('Nfc#status') ?? 'unsupported';

  /// Opens the system NFC settings (or the quick panel on Android 10+).
  Future<void> openSettings() => channel.invokeMethod('Nfc#openSettings');
}

class NfcTag {
  const NfcTag(this.handle, this.data);

  final String handle;

  final Map<String, dynamic> data;
}

class NfcError {
  const NfcError(this.type, this.message, this.details);

  final NfcErrorType type;

  final String message;

  final dynamic details;
}

enum NfcPollingOption { iso14443, iso15693, iso18092 }

enum NfcErrorType { sessionTimeout, systemIsBusy, userCanceled, unknown }

class CardModel {
  String cardId;
  String cardName;
  String cardCode;
  String cardNumber;
  String balance;
  String anotherInfo;
  CardModel(
    this.cardId,
    this.cardName,
    this.cardNumber,
    this.balance,
    this.anotherInfo,
    this.cardCode,
  );
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      json['card_id'],
      json['card_name'],
      json['card_number'],
      json['balance'],
      json['another_info'],
      json['card_code'],
    );
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['card_id'] = cardId;
    data['card_name'] = cardName;
    data['card_number'] = cardNumber;
    data['balance'] = balance;
    data['another_info'] = anotherInfo;
    return data;
  }
}
