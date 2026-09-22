import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';

class BudgetRepository {
  Box<BudgetModel> get _box => Hive.box<BudgetModel>(AppBoxes.budgets);

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
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      if (_box.get(key)?.id == id) return key;
    }
    return null;
  }
}
