import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:financial_recording/app/distribution.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/app_settings_model/app_settings_model.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/models/template_model/template_model.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/models/memo_model/memo_model.dart';
import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/services/backup_service.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/data/services/currency/display_currency.dart';

/// Registers Hive adapters, opens every v2 box, and seeds a fresh install —
/// either from a bundled JSON backup (`assets/seed/my_data.json`) when
/// present, or with a minimal starter dataset otherwise.
Future<void> bootstrap() async {
  await initializeDateFormatting('id_ID', null);
  await detectDistribution();
  await DisplayCurrency.load();
  await Hive.initFlutter();

  Hive.registerAdapter(TxTypeAdapter());
  Hive.registerAdapter(BudgetPeriodAdapter());
  Hive.registerAdapter(RecurrenceFreqAdapter());
  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(TxCategoryModelAdapter());
  Hive.registerAdapter(TxItemModelAdapter());
  Hive.registerAdapter(TxModelAdapter());
  Hive.registerAdapter(TagModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(RecurringRuleModelAdapter());
  Hive.registerAdapter(AppSettingsModelAdapter());
  Hive.registerAdapter(FinancialGoalModelAdapter());
  Hive.registerAdapter(QuickTemplateModelAdapter());
  Hive.registerAdapter(DebtLoanModelAdapter());
  Hive.registerAdapter(MemoModelAdapter());
  Hive.registerAdapter(CryptoHoldingModelAdapter());

  await Hive.openBox<AccountModel>(AppBoxes.accounts);
  await Hive.openBox<TxCategoryModel>(AppBoxes.categories);
  await Hive.openBox<TxModel>(AppBoxes.transactions);
  await Hive.openBox<TagModel>(AppBoxes.tags);
  await Hive.openBox<BudgetModel>(AppBoxes.budgets);
  await Hive.openBox<RecurringRuleModel>(AppBoxes.recurring);
  await Hive.openBox<AppSettingsModel>(AppBoxes.settings);
  await Hive.openBox<FinancialGoalModel>(AppBoxes.goals);
  await Hive.openBox<QuickTemplateModel>(AppBoxes.templates);
  await Hive.openBox<DebtLoanModel>(AppBoxes.debts);
  await Hive.openBox<MemoModel>(AppBoxes.memos);
  await Hive.openBox<CryptoHoldingModel>(AppBoxes.crypto);
  await Hive.openBox<String>(AppBoxes.cryptoPrices);
  await Hive.openBox<String>(AppBoxes.nfcScans);
  await SyncService.ensureOpen();
  await CurrencyService.ensureOpen();

  // Starter data and recurring posts now happen after sign-in, once the
  // cloud ledger has been pulled (see `SyncController._housekeeping`), so a
  // fresh device never seeds duplicates of an existing ledger. The bundled
  // personal seed still applies to native builds only.
  if (AccountRepository().all(includeArchived: true).isEmpty) {
    await _tryLoadBundledSeed();
  }
}

/// Never runs on web: a bundled seed asset is a public, unauthenticated file
/// in the deployed build, so real personal data must never be shipped this
/// way there. Fresh web visitors get the harmless [SeedService] starter data
/// instead — real data only arrives after signing in via Supabase sync.
Future<bool> _tryLoadBundledSeed() async {
  if (kIsWeb) return false;
  try {
    final jsonStr = await rootBundle.loadString('assets/seed/my_data.json');
    await BackupService().restoreJson(jsonStr, replaceAll: true);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> recomputeBalancesOnce() => LedgerService().recomputeAllBalances();
