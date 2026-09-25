import 'package:hive/hive.dart';
import 'package:financial_recording/data/repositories/box_id_index.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class RecurringRepository {
  Box<RecurringRuleModel> get _box => Hive.box<RecurringRuleModel>(AppBoxes.recurring);
  BoxIdIndex<RecurringRuleModel> get _index => BoxIdIndex.of(_box, (v) => v.id);

  List<RecurringRuleModel> all({bool includeInactive = true}) =>
      _box.values.where((r) => includeInactive || r.isActive).toList()
        ..sort((a, b) => a.nextRunDate.compareTo(b.nextRunDate));

  RecurringRuleModel? byId(String id) => _index.valueFor(_box, id);

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

  dynamic _keyFor(String id) => _index.keyFor(_box, id, strict: true);
}
