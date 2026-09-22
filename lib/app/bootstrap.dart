import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'package:financial_recording/data/models/tx_model/tx_item_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/template_repository.dart';
import 'package:financial_recording/data/services/backup_service.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/recurring_service.dart';
import 'package:financial_recording/data/services/seed_service.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Registers Hive adapters, opens every v2 box, and seeds a fresh install —
/// either from a bundled `.mmbak`-derived JSON (see `tool/mmbak_to_json.dart`)
/// when present, or with a minimal starter dataset otherwise.
Future<void> bootstrap() async {
  await initializeDateFormatting('id_ID', null);
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
  await SyncService.ensureOpen();

  if (AccountRepository().all(includeArchived: true).isEmpty) {
    final loadedFromSeed = await _tryLoadBundledSeed();
    if (!loadedFromSeed) {
      await SeedService().seedIfEmpty();
    }
  }

  await QuickTemplateRepository().seedDefaultsIfEmpty();
  await RecurringService().catchUp(DateTime.now());
}

Future<bool> _tryLoadBundledSeed() async {
  try {
    final jsonStr = await rootBundle.loadString('assets/seed/my_data.json');
    await BackupService().restoreJson(jsonStr, replaceAll: true);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> recomputeBalancesOnce() => LedgerService().recomputeAllBalances();
