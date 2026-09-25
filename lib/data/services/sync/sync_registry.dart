import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/models/memo_model/memo_model.dart';
import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/template_model/template_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/services/sync/sync_entity.dart';

SyncEntity _syncEntityFor<T extends HiveObject>({
  required String table,
  required String boxName,
  required Map<String, dynamic> Function(T item) toJson,
  required T Function(Map<String, dynamic> json) fromJson,
  required String Function(T item) idOf,
}) {
  Box<T> box() => Hive.box<T>(boxName);

  return SyncEntity(
    table: table,
    box: () => Hive.isBoxOpen(boxName) ? box() : null,
    allItems: () => box().values.toList(),
    itemsAt: (keys) {
      final b = box();
      return [for (final k in keys) b.get(k)].whereType<T>().toList();
    },
    toJson: (item) => toJson(item as T),
    idOf: (item) => idOf(item as T),
    normalize: (data) => toJson(fromJson(data)),
    applyRemote: (upserts, deletes) async {
      final b = box();
      // One id → key index per batch; looking each row up by scanning the
      // box made a pull of n rows cost n² reads.
      final keyById = <String, dynamic>{};
      for (final key in b.keys) {
        final v = b.get(key);
        if (v != null) keyById[idOf(v)] = key;
      }
      final puts = <dynamic, T>{};
      final adds = <T>[];
      for (final data in upserts) {
        final item = fromJson(data);
        final key = keyById[idOf(item)];
        if (key != null) {
          puts[key] = item;
        } else {
          adds.add(item);
        }
      }
      final deleteKeys = [for (final id in deletes) keyById[id]].whereType<Object>().toList();
      if (puts.isNotEmpty) await b.putAll(puts);
      if (adds.isNotEmpty) await b.addAll(adds);
      if (deleteKeys.isNotEmpty) await b.deleteAll(deleteKeys);
    },
  );
}

/// Every entity that syncs to Supabase. Deliberately excludes
/// `AppSettingsModel` (theme/UI prefs are device-local, not financial data)
/// and receipt image bytes (only the local file path is synced; see
/// `TxModel.imagePath`).
final List<SyncEntity> syncEntities = [
  _syncEntityFor<AccountModel>(
    table: 'accounts',
    boxName: AppBoxes.accounts,
    toJson: (m) => m.toJson(),
    fromJson: AccountModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<TxCategoryModel>(
    table: 'categories',
    boxName: AppBoxes.categories,
    toJson: (m) => m.toJson(),
    fromJson: TxCategoryModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<TxModel>(
    table: 'transactions',
    boxName: AppBoxes.transactions,
    toJson: (m) => m.toJson(),
    fromJson: TxModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<TagModel>(
    table: 'tags',
    boxName: AppBoxes.tags,
    toJson: (m) => m.toJson(),
    fromJson: TagModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<BudgetModel>(
    table: 'budgets',
    boxName: AppBoxes.budgets,
    toJson: (m) => m.toJson(),
    fromJson: BudgetModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<RecurringRuleModel>(
    table: 'recurring',
    boxName: AppBoxes.recurring,
    toJson: (m) => m.toJson(),
    fromJson: RecurringRuleModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<FinancialGoalModel>(
    table: 'goals',
    boxName: AppBoxes.goals,
    toJson: (m) => m.toJson(),
    fromJson: FinancialGoalModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<QuickTemplateModel>(
    table: 'templates',
    boxName: AppBoxes.templates,
    toJson: (m) => m.toJson(),
    fromJson: QuickTemplateModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<DebtLoanModel>(
    table: 'debts',
    boxName: AppBoxes.debts,
    toJson: (m) => m.toJson(),
    fromJson: DebtLoanModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<MemoModel>(
    table: 'memos',
    boxName: AppBoxes.memos,
    toJson: (m) => m.toJson(),
    fromJson: MemoModel.fromJson,
    idOf: (m) => m.id,
  ),
  _syncEntityFor<CryptoHoldingModel>(
    table: 'crypto_holdings',
    boxName: AppBoxes.crypto,
    toJson: (m) => m.toJson(),
    fromJson: CryptoHoldingModel.fromJson,
    idOf: (m) => m.id,
  ),
];

/// Every open financial box, typed correctly (see [SyncEntity.box]).
Iterable<Box<dynamic>> openFinancialBoxes() => syncEntities.map((e) => e.box?.call()).whereType<Box<dynamic>>();
