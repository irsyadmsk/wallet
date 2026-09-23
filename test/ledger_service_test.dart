import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/app_settings_model/app_settings_model.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

void _registerOnce<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
}

Future<void> _openBoxes() async {
  Hive.init('./.dart_tool/hive_test_ledger');
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
  await Hive.openBox<AccountModel>(AppBoxes.accounts);
  await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
  await Hive.openBox<TxModel>(AppBoxes.transactions);
  await Hive.openBox<TagModel>(AppBoxes.tags);
  await Hive.openBox<BudgetModel>(AppBoxes.budgets);
  await Hive.openBox<RecurringRuleModel>(AppBoxes.recurring);
  await Hive.openBox<AppSettingsModel>(AppBoxes.settings);
}

void main() {
  final accounts = AccountRepository();
  final ledger = LedgerService();

  setUp(() async {
    await _openBoxes();
    await accounts.clear();
    await Hive.box<TxModel>(AppBoxes.transactions).clear();
  });

  tearDown(() async => Hive.close());

  test('transfer moves balance from one account to another', () async {
    await accounts.upsert(AccountModel(id: 'a', name: 'A', groupCode: 1));
    await accounts.upsert(AccountModel(id: 'b', name: 'B', groupCode: 1));

    await ledger.addTransfer(fromAccountId: 'a', toAccountId: 'b', amount: 50000, date: DateTime.now());

    expect(accounts.byId('a')!.cachedBalance, -50000);
    expect(accounts.byId('b')!.cachedBalance, 50000);
  });

  test('deleting a transaction reverses its balance effect', () async {
    await accounts.upsert(AccountModel(id: 'a', name: 'A', groupCode: 1));
    final tx = await ledger.addIncome(accountId: 'a', categoryId: 'c1', amount: 100000, date: DateTime.now());

    expect(accounts.byId('a')!.cachedBalance, 100000);

    await ledger.delete(tx.id);
    expect(accounts.byId('a')!.cachedBalance, 0);
  });

  test('transfer fee is deducted from source but never credited to destination', () async {
    await accounts.upsert(AccountModel(id: 'a', name: 'A', groupCode: 1));
    await accounts.upsert(AccountModel(id: 'b', name: 'B', groupCode: 1));

    await ledger.addTransfer(
      fromAccountId: 'a',
      toAccountId: 'b',
      amount: 100000,
      date: DateTime.now(),
      fee: 5000,
    );

    expect(accounts.byId('a')!.cachedBalance, -105000);
    expect(accounts.byId('b')!.cachedBalance, 100000);
  });

  test('deleting a transfer with a fee fully reverses both legs', () async {
    await accounts.upsert(AccountModel(id: 'a', name: 'A', groupCode: 1));
    await accounts.upsert(AccountModel(id: 'b', name: 'B', groupCode: 1));
    final tx = await ledger.addTransfer(
      fromAccountId: 'a',
      toAccountId: 'b',
      amount: 100000,
      date: DateTime.now(),
      fee: 5000,
    );

    await ledger.delete(tx.id);

    expect(accounts.byId('a')!.cachedBalance, 0);
    expect(accounts.byId('b')!.cachedBalance, 0);
  });

  test('soft-deleting an account hides it, restore brings it back, purge removes it', () async {
    await accounts.upsert(AccountModel(id: 'a', name: 'A', groupCode: 1));
    expect(accounts.all().map((a) => a.id), contains('a'));

    await accounts.delete('a');
    expect(accounts.all().map((a) => a.id), isNot(contains('a')));
    expect(accounts.byId('a'), isNotNull, reason: 'soft-deleted account row must still exist');
    expect(accounts.deletedAccounts().map((a) => a.id), contains('a'));

    await accounts.restore('a');
    expect(accounts.all().map((a) => a.id), contains('a'));
    expect(accounts.deletedAccounts(), isEmpty);

    await accounts.delete('a');
    await accounts.purge('a');
    expect(accounts.byId('a'), isNull);
    expect(accounts.deletedAccounts(), isEmpty);
  });

  test('recomputeAllBalances matches manual ledger sum', () async {
    await accounts.upsert(AccountModel(id: 'a', name: 'A', groupCode: 1));
    await accounts.upsert(AccountModel(id: 'b', name: 'B', groupCode: 2));

    await ledger.addIncome(accountId: 'a', categoryId: 'c1', amount: 200000, date: DateTime.now());
    await ledger.addExpense(accountId: 'a', categoryId: 'c2', amount: 50000, date: DateTime.now());
    await ledger.addTransfer(fromAccountId: 'a', toAccountId: 'b', amount: 30000, date: DateTime.now());

    await ledger.recomputeAllBalances();

    expect(accounts.byId('a')!.cachedBalance, 200000 - 50000 - 30000);
    expect(accounts.byId('b')!.cachedBalance, 30000);
  });
}
