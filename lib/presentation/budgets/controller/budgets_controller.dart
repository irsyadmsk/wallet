import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/repositories/budget_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/services/budget_service_v2.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

class BudgetsController extends GetxController {
  final _budgets = BudgetRepository();
  final categories = TxCategoryRepository();
  final _service = BudgetServiceV2();

  final Rx<DateTime> month = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final Rx<BudgetProgress?> overall = Rx<BudgetProgress?>(null);
  final RxList<BudgetProgress> categoryProgress = <BudgetProgress>[].obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  void refresh() {
    overall.value = _service.overallProgress(month.value);
    categoryProgress.assignAll(_service.categoryProgress(month.value));
  }

  void previousMonth() {
    month.value = DateTime(month.value.year, month.value.month - 1);
    refresh();
  }

  void nextMonth() {
    month.value = DateTime(month.value.year, month.value.month + 1);
    refresh();
  }

  Future<void> setOverallBudget(int amount) async {
    await _budgets.upsert(BudgetModel(
      id: const Uuid().v4(),
      isTotal: true,
      amount: amount,
      period: BudgetPeriod.monthly,
      startMonth: month.value,
    ));
    refresh();
  }

  Future<void> setCategoryBudget(String categoryId, int amount) async {
    await _budgets.upsert(BudgetModel(
      id: const Uuid().v4(),
      categoryId: categoryId,
      amount: amount,
      period: BudgetPeriod.monthly,
      startMonth: month.value,
    ));
    refresh();
  }
}
