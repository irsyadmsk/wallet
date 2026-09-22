import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/app_settings_model/app_settings_model.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/template_model/template_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/goal_repository.dart';
import 'package:financial_recording/data/repositories/template_repository.dart';
import 'package:financial_recording/data/services/financial_health_service.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

void _registerOnce<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
}

Future<void> _openBoxes() async {
  Hive.init('./.dart_tool/hive_test_smart');
  _registerOnce(12, TxTypeAdapter());
  _registerOnce(13, BudgetPeriodAdapter());
  _registerOnce(14, RecurrenceFreqAdapter());
  _registerOnce(4, AccountModelAdapter());
  _registerOnce(5, TxCategoryModelAdapter());
  _registerOnce(7, TxItemModelAdapter());
  _registerOnce(6, TxModelAdapter());
  _registerOnce(8, TagModelAdapter());
  _registerOnce(9, BudgetModelAdapter());
  _registerOnce(10, RecurringRuleModelAdapter());
  _registerOnce(11, AppSettingsModelAdapter());
  _registerOnce(15, FinancialGoalModelAdapter());
  _registerOnce(16, QuickTemplateModelAdapter());

  await Hive.openBox<AccountModel>(AppBoxes.accounts);
  await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
  await Hive.openBox<TxModel>(AppBoxes.transactions);
  await Hive.openBox<TagModel>(AppBoxes.tags);
  await Hive.openBox<BudgetModel>(AppBoxes.budgets);
  await Hive.openBox<RecurringRuleModel>(AppBoxes.recurring);
  await Hive.openBox<AppSettingsModel>(AppBoxes.settings);
  await Hive.openBox<FinancialGoalModel>(AppBoxes.goals);
  await Hive.openBox<QuickTemplateModel>(AppBoxes.templates);
}

void main() {
  setUpAll(() async {
    await _openBoxes();
  });

  setUp(() async {
    await Hive.box<AccountModel>(AppBoxes.accounts).clear();
    await Hive.box<TxModel>(AppBoxes.transactions).clear();
    await Hive.box<BudgetModel>(AppBoxes.budgets).clear();
    await Hive.box<FinancialGoalModel>(AppBoxes.goals).clear();
    await Hive.box<QuickTemplateModel>(AppBoxes.templates).clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('FinancialGoalModel calculates progress and completion accurately', () {
    final goal = FinancialGoalModel(
      id: 'g1',
      title: 'Laptop Baru',
      targetAmount: 10000000,
      currentAmount: 2500000,
    );

    expect(goal.progress, equals(0.25));
    expect(goal.progressPercent, equals(25));
    expect(goal.remainingAmount, equals(7500000));
    expect(goal.isCompleted, isFalse);

    goal.currentAmount = 10000000;
    expect(goal.progress, equals(1.0));
    expect(goal.remainingAmount, equals(0));
  });

  test('FinancialGoalRepository handles deposits and status updates', () async {
    final repo = FinancialGoalRepository();
    final goal = FinancialGoalModel(
      id: 'g2',
      title: 'Dana Darurat',
      targetAmount: 5000000,
      currentAmount: 1000000,
    );
    await repo.upsert(goal);

    expect(repo.active().length, equals(1));
    expect(repo.completed().length, equals(0));

    await repo.addContribution('g2', 4000000);
    final updated = repo.byId('g2');
    expect(updated?.currentAmount, equals(5000000));
    expect(updated?.isCompleted, isTrue);

    expect(repo.active().length, equals(0));
    expect(repo.completed().length, equals(1));
  });

  test('QuickTemplateRepository seeds default templates and parses correctly', () async {
    final repo = QuickTemplateRepository();
    await repo.seedDefaultsIfEmpty();

    final templates = repo.all();
    expect(templates.isNotEmpty, isTrue);
    expect(templates.any((t) => t.name == 'Kopi'), isTrue);
    expect(templates.any((t) => t.name == 'Makan Siang'), isTrue);
  });

  test('FinancialHealthService computes health score and safe daily spend', () async {
    final accounts = AccountRepository();
    final ledger = LedgerService();
    final healthService = FinancialHealthService();

    final acc = AccountModel(
      id: 'acc_bca',
      name: 'BCA Main',
      groupCode: AccountGroupType.bank.code,
      cachedBalance: 15000000,
      openingBalance: 15000000,
    );
    await accounts.upsert(acc);

    final now = DateTime.now();
    await ledger.addIncome(
      accountId: acc.id,
      categoryId: 'cat_salary',
      amount: 10000000,
      date: DateTime(now.year, now.month, 2),
      memo: 'Gaji Bulanan',
    );

    await ledger.addExpense(
      accountId: acc.id,
      categoryId: 'cat_food',
      amount: 2000000,
      date: DateTime(now.year, now.month, 5),
      memo: 'Belanja Bulanan',
    );

    final report = healthService.calculateReport(now);

    expect(report.score, greaterThanOrEqualTo(60));
    expect(report.savingsRate, equals(0.8)); // (10jt - 2jt) / 10jt = 80%
    expect(report.safeDailySpend, greaterThan(0));
    expect(report.emergencyRunwayMonths, greaterThan(1.0));
    expect(report.insights.isNotEmpty, isTrue);
  });
}
