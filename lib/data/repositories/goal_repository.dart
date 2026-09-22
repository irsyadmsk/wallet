import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class FinancialGoalRepository {
  Box<FinancialGoalModel> get _box => Hive.box<FinancialGoalModel>(AppBoxes.goals);

  List<FinancialGoalModel> all() {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return (a.targetDate ?? DateTime(2099)).compareTo(b.targetDate ?? DateTime(2099));
    });
    return list;
  }

  List<FinancialGoalModel> active() =>
      all().where((g) => !g.isCompleted).toList();

  List<FinancialGoalModel> completed() =>
      all().where((g) => g.isCompleted).toList();

  FinancialGoalModel? byId(String id) {
    try {
      return _box.values.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(FinancialGoalModel goal) async {
    if (goal.currentAmount >= goal.targetAmount && goal.targetAmount > 0) {
      goal.isCompleted = true;
    }
    final key = _keyFor(goal.id);
    if (key != null) {
      await _box.put(key, goal);
    } else {
      await _box.add(goal);
    }
  }

  Future<void> addContribution(String id, int amount) async {
    final goal = byId(id);
    if (goal == null) return;
    goal.currentAmount = (goal.currentAmount + amount).clamp(0, 999999999999);
    if (goal.currentAmount >= goal.targetAmount && goal.targetAmount > 0) {
      goal.isCompleted = true;
    }
    await upsert(goal);
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('goals', id);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) {
    for (final key in _box.keys) {
      if (_box.get(key)?.id == id) return key;
    }
    return null;
  }
}
