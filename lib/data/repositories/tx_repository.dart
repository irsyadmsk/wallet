import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';

class TxRepository {
  Box<TxModel> get _box => Hive.box<TxModel>(AppBoxes.transactions);

  List<TxModel> all() => _box.values.toList();

  TxModel? byId(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All rows touching [accountId], including the "to" leg of transfers.
  List<TxModel> forAccount(String accountId) => _box.values
      .where((t) => t.accountId == accountId || t.toAccountId == accountId)
      .toList();

  List<TxModel> query(TxQuery q) {
    var result = _box.values.where((t) {
      if (q.from != null && t.date.isBefore(q.from!)) return false;
      if (q.to != null && t.date.isAfter(q.to!)) return false;
      if (q.types != null && !q.types!.contains(t.type)) return false;
      if (q.accountIds != null &&
          !(q.accountIds!.contains(t.accountId) ||
              (t.toAccountId != null && q.accountIds!.contains(t.toAccountId)))) {
        return false;
      }
      if (q.categoryIds != null && !q.categoryIds!.contains(t.categoryId)) return false;
      if (q.tagIds != null && !t.tagIds.any((tag) => q.tagIds!.contains(tag))) return false;
      if (q.minAmount != null && t.amount < q.minAmount!) return false;
      if (q.maxAmount != null && t.amount > q.maxAmount!) return false;
      if (q.search != null && q.search!.trim().isNotEmpty) {
        final s = q.search!.toLowerCase();
        final inMemo = (t.memo ?? '').toLowerCase().contains(s);
        final inItems = t.items.any((i) => i.name.toLowerCase().contains(s));
        if (!inMemo && !inItems) return false;
      }
      return true;
    }).toList();

    switch (q.sort) {
      case TxSort.dateDesc:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TxSort.dateAsc:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TxSort.amountDesc:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TxSort.amountAsc:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    if (q.limit != null && result.length > q.limit!) {
      result = result.sublist(0, q.limit!);
    }
    return result;
  }

  /// Raw write — prefer [LedgerService] which keeps account balances correct.
  Future<void> put(TxModel t) async {
    final key = _keyFor(t.id);
    if (key != null) {
      await _box.put(key, t);
    } else {
      await _box.add(t);
    }
  }

  Future<void> putAllFresh(Iterable<TxModel> items) => _box.addAll(items);

  Future<void> remove(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      if (_box.get(key)?.id == id) return key;
    }
    return null;
  }
}
