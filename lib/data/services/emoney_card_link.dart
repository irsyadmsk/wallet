import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/services/emoney_nfc_service.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// One balance check, kept on this device (like a card reader's history).
class EmoneyScan {
  const EmoneyScan({required this.cardCode, required this.cardName, required this.cardNumber, required this.balance, required this.at});

  final String cardCode;
  final String cardName;
  final String cardNumber;
  final int balance;
  final DateTime at;

  Map<String, dynamic> toJson() =>
      {'code': cardCode, 'name': cardName, 'number': cardNumber, 'balance': balance, 'at': at.toIso8601String()};

  factory EmoneyScan.fromJson(Map<String, dynamic> j) => EmoneyScan(
        cardCode: j['code']?.toString() ?? '',
        cardName: j['name']?.toString() ?? '',
        cardNumber: j['number']?.toString() ?? '',
        balance: (j['balance'] as num?)?.toInt() ?? 0,
        at: DateTime.tryParse(j['at']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// Links scanned e-money cards to Wallet accounts and keeps a local history
/// of balance checks.
class EmoneyCardLink {
  static const _maxHistory = 100;

  Box<String> get _box => Hive.box<String>(AppBoxes.nfcScans);
  final _accounts = AccountRepository();

  /// Digits only, so "6032 9827 1222 9721" and "6032982712229721" match.
  static String normalize(String cardNumber) => cardNumber.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();

  static String _externalId(String cardNumber) => 'nfc:${normalize(cardNumber)}';

  /// "6032 9827 1222 9721".
  static String formatNumber(String cardNumber) {
    final n = normalize(cardNumber);
    return [for (var i = 0; i < n.length; i += 4) n.substring(i, i + 4 > n.length ? n.length : i + 4)].join(' ');
  }

  // ------------------------------------------------------------ history

  List<EmoneyScan> history() {
    final raw = _box.get('history');
    if (raw == null) return [];
    try {
      return [for (final e in jsonDecode(raw) as List) EmoneyScan.fromJson(Map<String, dynamic>.from(e as Map))];
    } catch (_) {
      return [];
    }
  }

  /// The previous check of the same card, before [scan] is recorded.
  EmoneyScan? previousOf(String cardNumber) {
    final n = normalize(cardNumber);
    for (final s in history()) {
      if (normalize(s.cardNumber) == n) return s;
    }
    return null;
  }

  Future<void> record(EmoneyScan scan) async {
    final list = [scan, ...history()].take(_maxHistory).toList();
    await _box.put('history', jsonEncode([for (final s in list) s.toJson()]));
  }

  Future<void> clearHistory() => _box.delete('history');

  // ------------------------------------------------------------ accounts

  /// The Wallet account created from (or linked to) this card, if any.
  AccountModel? accountFor(String cardNumber) {
    final id = _externalId(cardNumber);
    final n = normalize(cardNumber);
    for (final a in _accounts.all(includeArchived: true)) {
      if (a.externalId == id) return a;
      if (n.length >= 8 && (a.note ?? '').replaceAll(' ', '').contains(n)) return a;
    }
    return null;
  }

  Future<AccountModel> createAccount(EmoneyCardResult card) async {
    final balance = card.balanceAmount ?? 0;
    final account = AccountModel(
      id: const Uuid().v4(),
      name: card.cardName.isNotEmpty ? card.cardName : 'Kartu E-Money',
      groupCode: AccountGroupType.prepaid.code,
      openingBalance: balance,
      cachedBalance: balance,
      note: 'No. kartu ${formatNumber(card.cardNumber)}',
      colorValue: issuerColor(card.cardCode),
    )..externalId = _externalId(card.cardNumber);
    await _accounts.upsert(account);
    return account;
  }

  /// Makes [account] match the card's [cardBalance] by recording the
  /// difference as a transaction (spent on the card → expense, topped up →
  /// income). Returns the difference applied, 0 when already equal.
  Future<int> reconcile(AccountModel account, int cardBalance) async {
    final diff = cardBalance - account.cachedBalance;
    if (diff == 0) return 0;
    final type = diff < 0 ? TxType.expense : TxType.income;
    final category = _fallbackCategory(type);
    final ledger = LedgerService();
    final memo = diff < 0 ? 'Pemakaian kartu (cek saldo NFC)' : 'Isi ulang kartu (cek saldo NFC)';
    if (type == TxType.expense) {
      await ledger.addExpense(accountId: account.id, categoryId: category, amount: -diff, date: DateTime.now(), memo: memo);
    } else {
      await ledger.addIncome(accountId: account.id, categoryId: category, amount: diff, date: DateTime.now(), memo: memo);
    }
    return diff;
  }

  /// "Lainnya" of the right type, or the first category of that type.
  String _fallbackCategory(TxType type) {
    final code = type == TxType.income ? 0 : 1;
    final cats = TxCategoryRepository().byType(code).where((c) => !c.isSub).toList();
    for (final c in cats) {
      if (c.name.toLowerCase() == 'lainnya') return c.id;
    }
    return cats.isEmpty ? '' : cats.first.id;
  }

  static int issuerColor(String cardCode) => switch (cardCode) {
        'emo' => 0xFFD9363E, // Mandiri e-money
        'brz' => 0xFF1D4F9C, // BRI Brizzi
        'tcs' => 0xFFE8702A, // BNI TapCash
        'flz' => 0xFF0060AF, // BCA Flazz
        _ => 0xFF4F46E5,
      };
}
