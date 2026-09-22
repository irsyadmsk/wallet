import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';

class AccountRepository {
  Box<AccountModel> get _box => Hive.box<AccountModel>(AppBoxes.accounts);

  List<AccountModel> all({bool includeArchived = false}) {
    final list = _box.values.where((a) => includeArchived || !a.isArchived).toList();
    list.sort((a, b) => a.orderSeq.compareTo(b.orderSeq));
    return list;
  }

  AccountModel? byId(String id) {
    try {
      return _box.values.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<AccountGroupType, List<AccountModel>> grouped({bool includeArchived = false}) {
    final result = <AccountGroupType, List<AccountModel>>{};
    for (final a in all(includeArchived: includeArchived)) {
      result.putIfAbsent(a.group, () => []).add(a);
    }
    return result;
  }

  Future<void> upsert(AccountModel account) async {
    account.updatedAt = DateTime.now();
    final existingKey = _keyFor(account.id);
    if (existingKey != null) {
      await _box.put(existingKey, account);
    } else {
      await _box.add(account);
    }
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('accounts', id);
  }

  Future<void> reorder(List<String> idsInOrder) async {
    for (var i = 0; i < idsInOrder.length; i++) {
      final acc = byId(idsInOrder[i]);
      if (acc != null) {
        acc.orderSeq = i;
        await acc.save();
      }
    }
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      final v = _box.get(key);
      if (v != null && v.id == id) return key;
    }
    return null;
  }

  int get netWorth => all().fold(0, (sum, a) => sum + a.cachedBalance);
  int get totalAssets =>
      all().where((a) => !a.isLiability).fold(0, (sum, a) => sum + a.cachedBalance);
  int get totalLiabilities =>
      all().where((a) => a.isLiability).fold(0, (sum, a) => sum + a.cachedBalance);
}
