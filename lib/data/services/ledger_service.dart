import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

import 'package:financial_recording/data/services/receipt_service.dart';

/// The single gateway that mutates [TxModel]s and keeps
/// [AccountModel.cachedBalance] consistent. Nothing else should write a
/// transaction directly — see the balance-drift bug this replaces in the
/// legacy `TransactionRepository`/`FormTransferController`.
class LedgerService {
  LedgerService({
    AccountRepository? accountRepository,
    TxRepository? txRepository,
    ReceiptService? receiptService,
  })  : _accounts = accountRepository ?? AccountRepository(),
        _txs = txRepository ?? TxRepository(),
        _receipts = receiptService ?? ReceiptService();

  final AccountRepository _accounts;
  final TxRepository _txs;
  final ReceiptService _receipts;
  static const _uuid = Uuid();

  Future<TxModel> addIncome({
    required String accountId,
    required String categoryId,
    required int amount,
    required DateTime date,
    String? memo,
    List<TxItemModel>? items,
    List<String>? tagIds,
    String? imagePath,
    String? id,
  }) =>
      _write(TxModel(
        id: id ?? _uuid.v4(),
        type: TxType.income,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        date: date,
        memo: memo,
        items: items,
        tagIds: tagIds,
        imagePath: imagePath,
      ));

  Future<TxModel> addExpense({
    required String accountId,
    required String categoryId,
    required int amount,
    required DateTime date,
    String? memo,
    List<TxItemModel>? items,
    List<String>? tagIds,
    String? imagePath,
    String? id,
  }) =>
      _write(TxModel(
        id: id ?? _uuid.v4(),
        type: TxType.expense,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        date: date,
        memo: memo,
        items: items,
        tagIds: tagIds,
        imagePath: imagePath,
      ));

  Future<TxModel> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    required DateTime date,
    String? memo,
    String? imagePath,
    int? fee,
    int? toAmount,
    String? id,
  }) =>
      _write(TxModel(
        id: id ?? _uuid.v4(),
        type: TxType.transfer,
        toAmount: toAmount,
        amount: amount,
        accountId: fromAccountId,
        toAccountId: toAccountId,
        date: date,
        memo: memo,
        imagePath: imagePath,
        transferFee: fee,
      ));

  Future<void> update(TxModel updated) async {
    final old = _txs.byId(updated.id);
    if (old != null && old.imagePath != null && old.imagePath != updated.imagePath) {
      await _receipts.deleteReceipt(old.imagePath);
    }
    if (old != null) _applyEffect(old, reverse: true);
    await _txs.put(updated);
    _applyEffect(updated, reverse: false);
    await _saveTouchedAccounts(old, updated);
  }

  Future<void> delete(String txId) async {
    final tx = _txs.byId(txId);
    if (tx == null) return;
    if (tx.imagePath != null) {
      await _receipts.deleteReceipt(tx.imagePath);
    }
    _applyEffect(tx, reverse: true);
    await _saveTouchedAccounts(tx, null);
    await _txs.remove(txId);
  }

  Future<TxModel> _write(TxModel tx) async {
    await _txs.put(tx);
    _applyEffect(tx, reverse: false);
    await _saveTouchedAccounts(tx, null);
    return tx;
  }

  void _applyEffect(TxModel tx, {required bool reverse}) {
    final sign = reverse ? -1 : 1;
    final from = _accounts.byId(tx.accountId);
    if (from != null) {
      from.cachedBalance += sign * tx.signedAmountOnPrimaryAccount;
    }
    if (tx.isTransfer && tx.toAccountId != null) {
      final to = _accounts.byId(tx.toAccountId!);
      if (to != null) to.cachedBalance += sign * tx.receivedAmount;
    }
  }

  Future<void> _saveTouchedAccounts(TxModel? a, TxModel? b) async {
    final ids = <String>{
      if (a != null) a.accountId,
      if (a?.toAccountId != null) a!.toAccountId!,
      if (b != null) b.accountId,
      if (b?.toAccountId != null) b!.toAccountId!,
    };
    for (final id in ids) {
      final acc = _accounts.byId(id);
      if (acc != null) await acc.save();
    }
  }

  /// Full O(n) rebuild of every account's cached balance from the ledger.
  /// Cheap (a few ms for thousands of rows) — call after import, JSON
  /// restore, or from the Settings "Hitung ulang saldo" action.
  Future<void> recomputeAllBalances() async {
    final balances = <String, int>{};
    for (final acc in _accounts.all(includeArchived: true, includeDeleted: true)) {
      balances[acc.id] = acc.openingBalance;
    }
    for (final tx in _txs.all()) {
      balances[tx.accountId] = (balances[tx.accountId] ?? 0) + tx.signedAmountOnPrimaryAccount;
      if (tx.isTransfer && tx.toAccountId != null) {
        balances[tx.toAccountId!] = (balances[tx.toAccountId!] ?? 0) + tx.receivedAmount;
      }
    }
    for (final acc in _accounts.all(includeArchived: true, includeDeleted: true)) {
      final balance = balances[acc.id] ?? acc.openingBalance;
      // Unchanged rows are skipped: every save is a disk write plus a box
      // event that wakes the sync and UI listeners.
      if (acc.cachedBalance == balance) continue;
      acc.cachedBalance = balance;
      await acc.save();
    }
  }
}
