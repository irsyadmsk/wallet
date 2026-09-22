import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/models/transaction_model/transaction_model.dart';
import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'i_transaction_repository.dart';

class TransactionRepository implements ITransactionRepository {
  Box<TransactionModel> get _box =>
      Hive.box<TransactionModel>(AppConfig.transactionBoxName);
  Box<WalletModel> get _walletBox =>
      Hive.box<WalletModel>(AppConfig.walletBoxName);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _box.add(transaction);
  }

  @override
  Future<void> deleteTransaction(TransactionModel transaction) async {
    // 1. Revert wallet balance changes
    if (transaction.type == 'expense') {
      for (var key in _walletBox.keys) {
        final w = _walletBox.get(key);
        if (w != null && w.name == transaction.walletName) {
          w.balance += transaction.amount;
          await _walletBox.put(key, w);
          break;
        }
      }
    } else if (transaction.type == 'income') {
      for (var key in _walletBox.keys) {
        final w = _walletBox.get(key);
        if (w != null && w.name == transaction.walletName) {
          w.balance -= transaction.amount;
          await _walletBox.put(key, w);
          break;
        }
      }
    } else if (transaction.type == 'transfer') {
      final parts = transaction.walletName.split(" -> ");
      if (parts.length == 2) {
        final sourceName = parts[0].trim();
        final destName = parts[1].trim();
        for (var key in _walletBox.keys) {
          final w = _walletBox.get(key);
          if (w != null && w.name == sourceName) {
            w.balance += transaction.amount;
            await _walletBox.put(key, w);
          } else if (w != null && w.name == destName) {
            w.balance -= transaction.amount;
            await _walletBox.put(key, w);
          }
        }
      }
    }

    // 2. Delete transaction record
    await transaction.delete();
  }

  @override
  Future<int> getTotalExpense({DateTime? start, DateTime? end}) async {
    int total = 0;
    for (var t in _box.values) {
      if (t.type != 'expense') continue;
      if (start != null && t.createdAt.isBefore(start)) continue;
      if (end != null && t.createdAt.isAfter(end)) continue;
      total += t.amount;
    }
    return total;
  }

  @override
  Future<int> getTotalIncome({DateTime? start, DateTime? end}) async {
    int total = 0;
    for (var t in _box.values) {
      if (t.type != 'income') continue;
      if (start != null && t.createdAt.isBefore(start)) continue;
      if (end != null && t.createdAt.isAfter(end)) continue;
      total += t.amount;
    }
    return total;
  }
}
