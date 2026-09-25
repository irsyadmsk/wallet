import 'package:hive/hive.dart';
import 'package:financial_recording/data/repositories/box_id_index.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

class DebtRepository {
  Box<DebtLoanModel> get _box => Hive.box<DebtLoanModel>(AppBoxes.debts);
  BoxIdIndex<DebtLoanModel> get _index => BoxIdIndex.of(_box, (v) => v.id);

  List<DebtLoanModel> all() {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.isSettled != b.isSettled) {
        return a.isSettled ? 1 : -1;
      }
      return (a.dueDate ?? DateTime(2099)).compareTo(b.dueDate ?? DateTime(2099));
    });
    return list;
  }

  List<DebtLoanModel> debts() => all().where((d) => !d.isLoan).toList();
  List<DebtLoanModel> loans() => all().where((d) => d.isLoan).toList();
  List<DebtLoanModel> active() => all().where((d) => !d.isSettled).toList();

  DebtLoanModel? byId(String id) => _index.valueFor(_box, id);

  Future<void> upsert(DebtLoanModel debt) async {
    if (debt.remainingAmount <= 0) {
      debt.isSettled = true;
      debt.remainingAmount = 0;
    }
    final key = _keyFor(debt.id);
    if (key != null) {
      await _box.put(key, debt);
    } else {
      await _box.add(debt);
    }
  }

  Future<void> recordPayment(String id, int amount) async {
    final debt = byId(id);
    if (debt == null || amount <= 0) return;
    debt.remainingAmount = (debt.remainingAmount - amount).clamp(0, debt.totalAmount);
    if (debt.remainingAmount <= 0) {
      debt.isSettled = true;
    }
    await upsert(debt);
  }

  Future<void> delete(String id) async {
    final key = _keyFor(id);
    if (key != null) await _box.delete(key);
    await TombstoneService().record('debts', id);
  }

  Future<void> clear() => _box.clear();

  dynamic _keyFor(String id) => _index.keyFor(_box, id, strict: true);
}
