import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/goal_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';

class GoalsController extends GetxController {
  final _goals = FinancialGoalRepository();
  final _accounts = AccountRepository();

  final RxList<FinancialGoalModel> activeGoals = <FinancialGoalModel>[].obs;
  final RxList<FinancialGoalModel> completedGoals = <FinancialGoalModel>[].obs;
  final RxInt totalSaved = 0.obs;
  final RxInt totalTarget = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  void refresh() {
    final all = _goals.all();
    activeGoals.assignAll(all.where((g) => !g.isCompleted));
    completedGoals.assignAll(all.where((g) => g.isCompleted));

    totalSaved.value = all.fold(0, (s, g) => s + g.currentAmount);
    totalTarget.value = all.fold(0, (s, g) => s + g.targetAmount);
  }

  Future<void> saveGoal({
    String? id,
    required String title,
    required int targetAmount,
    int currentAmount = 0,
    DateTime? targetDate,
    int colorValue = 0xFF0D9488,
    String iconName = 'savings',
    String? notes,
  }) async {
    final goal = FinancialGoalModel(
      id: id ?? const Uuid().v4(),
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      colorValue: colorValue,
      iconName: iconName,
      isCompleted: currentAmount >= targetAmount && targetAmount > 0,
      notes: notes,
    );
    await _goals.upsert(goal);
    refresh();
  }

  Future<void> addContribution(String goalId, int amount, String? fromAccountId) async {
    if (amount <= 0) return;
    await _goals.addContribution(goalId, amount);

    if (fromAccountId != null) {
      final acc = _accounts.byId(fromAccountId);
      if (acc != null) {
        final goal = _goals.byId(goalId);
        await LedgerService().addExpense(
          accountId: fromAccountId,
          categoryId: 'none',
          amount: amount,
          date: DateTime.now(),
          memo: 'Alokasi Tabungan: ${goal?.title ?? 'Target Impian'}',
        );
      }
    }
    refresh();
  }

  Future<void> deleteGoal(String id) async {
    await _goals.delete(id);
    refresh();
  }
}
