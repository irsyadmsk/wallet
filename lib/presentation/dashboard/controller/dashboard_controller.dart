import 'package:get/get.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/template_model/template_model.dart';
import 'package:financial_recording/data/repositories/template_repository.dart';
import 'package:financial_recording/data/services/financial_health_service.dart';
import 'package:financial_recording/data/services/budget_service_v2.dart';
import 'package:financial_recording/data/services/recurring_service.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/debt_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

class DashboardController extends GetxController {
  final _accounts = AccountRepository();
  final _txs = TxRepository();
  final _categories = TxCategoryRepository();
  final _budgets = BudgetServiceV2();
  final _recurringService = RecurringService();
  final _healthService = FinancialHealthService();
  final _templates = QuickTemplateRepository();
  final _debts = DebtRepository();

  final RxInt netWorth = 0.obs;
  final RxInt totalAssets = 0.obs;
  final RxInt totalLiabilities = 0.obs;
  final RxInt monthIncome = 0.obs;
  final RxInt monthExpense = 0.obs;
  final RxList<TxModel> recentTransactions = <TxModel>[].obs;
  final RxList<BudgetProgress> topBudgets = <BudgetProgress>[].obs;
  final RxList<RecurringRuleModel> upcomingRecurring = <RecurringRuleModel>[].obs;
  final Rx<BudgetProgress?> overallBudget = Rx<BudgetProgress?>(null);
  final Rx<FinancialHealthReport?> healthReport = Rx<FinancialHealthReport?>(null);
  final RxList<QuickTemplateModel> templates = <QuickTemplateModel>[].obs;
  final RxList<AccountModel> accountsList = <AccountModel>[].obs;
  final RxInt activeDebtAmount = 0.obs;
  final RxInt activeLoanAmount = 0.obs;
  final RxInt activeDebtCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  TxCategoryRepository get categories => _categories;
  AccountRepository get accounts => _accounts;

  Future<void> confirmRecurring(String ruleId) async {
    await _recurringService.confirmPost(ruleId);
    refresh();
  }

  @override
  void refresh() {
    netWorth.value = _accounts.netWorth;
    totalAssets.value = _accounts.totalAssets;
    totalLiabilities.value = _accounts.totalLiabilities;

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 1);

    final monthTxs = _txs.query(TxQuery(from: from, to: to));
    monthIncome.value = monthTxs.where((t) => t.type == TxType.income).fold(0, (s, t) => s + t.amount);
    monthExpense.value = monthTxs.where((t) => t.type == TxType.expense).fold(0, (s, t) => s + t.amount);

    recentTransactions.assignAll(_txs.query(TxQuery(limit: 6)));

    overallBudget.value = _budgets.overallProgress(now);
    topBudgets.assignAll(_budgets.categoryProgress(now).take(3));

    upcomingRecurring.assignAll(
      _recurringService.dueForConfirmation(now, horizonDays: 7),
    );

    accountsList.assignAll(_accounts.all());
    templates.assignAll(_templates.all());
    healthReport.value = _healthService.calculateReport(now);

    final activeDebts = _debts.active();
    activeDebtCount.value = activeDebts.length;
    activeDebtAmount.value = activeDebts.where((d) => !d.isLoan).fold(0, (s, d) => s + d.remainingAmount);
    activeLoanAmount.value = activeDebts.where((d) => d.isLoan).fold(0, (s, d) => s + d.remainingAmount);
  }
}
