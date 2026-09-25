import 'package:hive/hive.dart';
import 'package:financial_recording/data/repositories/box_id_index.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class BudgetRepository {
  Box<BudgetModel> get _box => Hive.box<BudgetModel>(AppBoxes.budgets);
  BoxIdIndex<BudgetModel> get _index => BoxIdIndex.of(_box, (v) => v.id);

  List<BudgetModel> all({bool includeArchived = false}) =>
      _box.values.where((b) => includeArchived || !b.isArchived).toList();

  /// The budget row that applies to [categoryId] (null = overall budget) for
  /// [month] — the row with the latest `startMonth` that still covers it.
  BudgetModel? activeFor({String? categoryId, required DateTime month}) {
    final candidates = all().where((b) {
      final matchesTarget = categoryId == null ? b.isTotal : b.categoryId == categoryId;
      return matchesTarget && b.coversMonth(month);
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.startMonth.compareTo(a.startMonth));
    return candidates.first;
  }

  Future<void> upsert(BudgetModel budget) async {
    final key = _keyFor(budget.id);
    if (key != null) {
      await _box.put(key, budget);
    } else {
      await _box.add(budget);
    }
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('budgets', id);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) => _index.keyFor(_box, id, strict: true);
}
