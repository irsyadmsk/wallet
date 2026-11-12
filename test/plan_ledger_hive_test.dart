import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/monthly/plan_ledger.dart';

void _once<T>(int id, TypeAdapter<T> a) {
  if (!Hive.isAdapterRegistered(id)) Hive.registerAdapter(a);
}

void main() {
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_plan_ledger');
    _once(12, TxTypeAdapter());
    _once(4, AccountModelAdapter());
    _once(5, TxCategoryModelAdapter());
    _once(7, TxItemModelAdapter());
    _once(6, TxModelAdapter());
    _once(15, FinancialGoalModelAdapter());
    expect(HivePlanLedger.ifOpen().available, isFalse);
    final accounts = await Hive.openBox<AccountModel>(AppBoxes.accounts);
    final categories = await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
    final txs = await Hive.openBox<TxModel>(AppBoxes.transactions);
    final goals = await Hive.openBox<FinancialGoalModel>(AppBoxes.goals);
    await Future.wait([accounts.clear(), categories.clear(), txs.clear(), goals.clear()]);
    await accounts.add(AccountModel(id: 'acc', name: 'Dompet contoh', groupCode: 11,
      openingBalance: 1000, cachedBalance: 1000));
    await categories.addAll([
      TxCategoryModel(id: 'food', name: 'Dapur', typeCode: 1),
      TxCategoryModel(id: 'veg', name: 'Sayur', typeCode: 1, parentId: 'food'),
      TxCategoryModel(id: 'fun', name: 'Hiburan', typeCode: 1),
      TxCategoryModel(id: 'pay', name: 'Gaji', typeCode: 0),
    ]);
    await goals.add(FinancialGoalModel(id: 'goal', title: 'Tujuan contoh',
      targetAmount: 1000, currentAmount: 250));
  });
  tearDown(() async => Hive.close());

  test('linked spending counts this month, this category and its children only',
      () async {
    final ledger = LedgerService();
    Future<void> spend(String cat, int amount, DateTime date) => ledger.addExpense(
      accountId: 'acc', categoryId: cat, amount: amount, date: date);
    await spend('food', 100, DateTime(2026, 11, 3));
    await spend('veg', 40, DateTime(2026, 11, 30, 23, 59));
    await spend('fun', 999, DateTime(2026, 11, 5));
    await spend('food', 500, DateTime(2026, 10, 31));
    await spend('food', 700, DateTime(2026, 12, 1));
    await ledger.addIncome(accountId: 'acc', categoryId: 'pay', amount: 5000,
      date: DateTime(2026, 11, 1));

    final view = HivePlanLedger.ifOpen();
    expect(view.available, isTrue);
    expect(view.categories().map((o) => o.id), containsAll(['food', 'veg', 'fun']));
    expect(view.categories().any((o) => o.id == 'pay'), isFalse);
    expect(view.accounts().single.label, 'Dompet contoh');
    expect(view.goals().single.label, 'Tujuan contoh');

    const item = AllocationItem(id: 'i', group: 'Rutin', name: 'Dapur', amount: 300,
      categoryId: 'food', accountId: 'acc', goalId: 'goal');
    final links = view.linksFor(item, DateTime(2026, 11));
    expect(links.ledgerSpent, 140);
    expect(links.accountLabel, 'Dompet contoh');
    expect(links.goalCurrent, 250);
    expect(links.goalTarget, 1000);
    // Template and one-off tabs have no month.
    expect(view.linksFor(item, null).ledgerSpent, isNull);
    // A link to a record that no longer exists shows nothing rather than failing.
    const stale = AllocationItem(id: 's', group: 'Rutin', name: 'Lama', amount: 1,
      categoryId: 'gone', accountId: 'gone', goalId: 'gone');
    expect(view.linksFor(stale, DateTime(2026, 11)).isEmpty, isTrue);
  });
}
