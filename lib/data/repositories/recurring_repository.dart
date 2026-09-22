import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class RecurringRepository {
  Box<RecurringRuleModel> get _box => Hive.box<RecurringRuleModel>(AppBoxes.recurring);

  List<RecurringRuleModel> all({bool includeInactive = true}) =>
      _box.values.where((r) => includeInactive || r.isActive).toList()
        ..sort((a, b) => a.nextRunDate.compareTo(b.nextRunDate));

  RecurringRuleModel? byId(String id) {
    try {
      return _box.values.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(RecurringRuleModel rule) async {
    final key = _keyFor(rule.id);
    if (key != null) {
      await _box.put(key, rule);
    } else {
      await _box.add(rule);
    }
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('recurring', id);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      if (_box.get(key)?.id == id) return key;
    }
    return null;
  }
}
