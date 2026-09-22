import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';

/// Raw rows read from the `.mmbak` SQLite file, kept as plain maps so the
/// mapper (pure Dart, no `dart:ffi`) can run on any platform including web.
class MmbakRawData {
  final List<Map<String, Object?>> assetGroups;
  final List<Map<String, Object?>> assets;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> transactions;
  final List<Map<String, Object?>> tags;
  final List<Map<String, Object?>> txTags;
  final List<Map<String, Object?>> budgets;
  final List<Map<String, Object?>> budgetAmounts;
  final List<Map<String, Object?>> repeatTransactions;

  MmbakRawData({
    required this.assetGroups,
    required this.assets,
    required this.categories,
    required this.transactions,
    required this.tags,
    required this.txTags,
    required this.budgets,
    required this.budgetAmounts,
    required this.repeatTransactions,
  });
}

class MmbakWarning {
  final String message;
  const MmbakWarning(this.message);
  @override
  String toString() => message;
}

/// Result of mapping raw rows into v2 models — nothing is written to Hive
/// yet, so the UI can show a preview before the user commits.
class MmbakPreview {
  final List<AccountModel> accounts;
  final List<TxCategoryModel> categories;
  final List<TxModel> transactions;
  final List<TagModel> tags;
  final List<RecurringRuleModel> recurringRules;
  final List<MmbakWarning> warnings;

  MmbakPreview({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.tags,
    required this.recurringRules,
    required this.warnings,
  });

  int get incomeCount => transactions.where((t) => t.type.name == 'income').length;
  int get expenseCount => transactions.where((t) => t.type.name == 'expense').length;
  int get transferCount => transactions.where((t) => t.type.name == 'transfer').length;

  DateTime? get earliestDate =>
      transactions.isEmpty ? null : transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
  DateTime? get latestDate =>
      transactions.isEmpty ? null : transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);

  int get netWorth => accounts.fold(0, (sum, a) => sum + a.cachedBalance);
}

enum ImportMode { replaceAll, merge }

class MmbakImportReport {
  final int accountCount;
  final int categoryCount;
  final int transactionCount;
  final int tagCount;
  final int warningCount;
  final ImportMode mode;

  MmbakImportReport({
    required this.accountCount,
    required this.categoryCount,
    required this.transactionCount,
    required this.tagCount,
    required this.warningCount,
    required this.mode,
  });
}
