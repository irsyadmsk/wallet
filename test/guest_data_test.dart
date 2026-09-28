import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/models/memo_model/memo_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/template_model/template_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/seed_service.dart';
import 'package:financial_recording/data/services/sync/ledger_merge.dart';
import 'package:financial_recording/data/services/sync/sync_registry.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Using Wallet without an account, then signing in: the app must tell
/// real records from untouched starter data, and merging them into an
/// account must not duplicate the account's own categories or accounts.
void main() {
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_guest');
    void reg<T>(TypeAdapter<T> a) {
      if (!Hive.isAdapterRegistered(a.typeId)) Hive.registerAdapter(a);
    }

    reg(TxTypeAdapter());
    reg(BudgetPeriodAdapter());
    reg(RecurrenceFreqAdapter());
    reg(AccountModelAdapter());
    reg(TxCategoryModelAdapter());
    reg(TxItemModelAdapter());
    reg(TxModelAdapter());
    reg(TagModelAdapter());
    reg(BudgetModelAdapter());
    reg(RecurringRuleModelAdapter());
    reg(FinancialGoalModelAdapter());
    reg(QuickTemplateModelAdapter());
    reg(DebtLoanModelAdapter());
    reg(MemoModelAdapter());
    reg(CryptoHoldingModelAdapter());
    await Hive.openBox<AccountModel>(AppBoxes.accounts);
    await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
    await Hive.openBox<TxModel>(AppBoxes.transactions);
    await Hive.openBox<TagModel>(AppBoxes.tags);
    await Hive.openBox<BudgetModel>(AppBoxes.budgets);
    await Hive.openBox<RecurringRuleModel>(AppBoxes.recurring);
    await Hive.openBox<FinancialGoalModel>(AppBoxes.goals);
    await Hive.openBox<QuickTemplateModel>(AppBoxes.templates);
    await Hive.openBox<DebtLoanModel>(AppBoxes.debts);
    await Hive.openBox<MemoModel>(AppBoxes.memos);
    await Hive.openBox<CryptoHoldingModel>(AppBoxes.crypto);
    for (final box in openFinancialBoxes()) {
      await box.clear();
    }
  });

  tearDown(() async => Hive.close());

  Map<String, List<Map<String, dynamic>>> snapshot() => {
        for (final e in syncEntities) e.table: [for (final i in e.allItems()) e.toJson(i)],
      };

  test('data awal bawaan saja bukan catatan pengguna', () async {
    await SeedService().seedIfEmpty();
    expect(SyncService().localHasUserData(), isFalse);
  });

  test('transaksi atau saldo awal dihitung sebagai catatan pengguna', () async {
    await SeedService().seedIfEmpty();
    final tunai = AccountRepository().all().first;
    tunai.openingBalance = 50000;
    await AccountRepository().upsert(tunai);
    expect(SyncService().localHasUserData(), isTrue);

    tunai.openingBalance = 0;
    await AccountRepository().upsert(tunai);
    expect(SyncService().localHasUserData(), isFalse);

    await TxRepository().put(TxModel(
      id: 'tx-tamu',
      type: TxType.expense,
      amount: 25000,
      accountId: tunai.id,
      date: DateTime(2026, 9, 28),
    ));
    expect(SyncService().localHasUserData(), isTrue);
  });

  test('menggabungkan catatan tamu ke akun tidak menggandakan kategori & akun bawaan', () async {
    // The account (as pulled from the cloud): its own starter data.
    await SeedService().seedIfEmpty();
    final account = snapshot();

    // This device, used without an account: its own starter data (other
    // ids, same names) plus one expense.
    for (final box in openFinancialBoxes()) {
      await box.clear();
    }
    await SeedService().seedIfEmpty();
    final guestTunai = AccountRepository().all().first;
    final guestMakan = snapshot()['categories']!.firstWhere((c) => c['name'] == 'Makanan' && c['typeCode'] == 1);
    await TxRepository().put(TxModel(
      id: 'tx-tamu',
      type: TxType.expense,
      amount: 25000,
      accountId: guestTunai.id,
      categoryId: guestMakan['id'] as String,
      date: DateTime(2026, 9, 28),
    ));
    final guest = snapshot();

    final plan = LedgerMerge.plan(mine: guest, family: account);

    // Starter categories and the unused "Tunai" collapse onto the account's.
    expect(plan['categories'] ?? const [], isEmpty);
    // The guest's Tunai was used, so it is kept (with its own id).
    final tx = plan['transactions']!.single;
    final accountMakan = account['categories']!.firstWhere((c) => c['name'] == 'Makanan' && c['typeCode'] == 1);
    expect(tx['categoryId'], accountMakan['id']);
    expect(tx['amount'], 25000);
  });
}
