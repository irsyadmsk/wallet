import 'dart:convert';

import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/repositories/tag_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/sync/replace_local.dart';

/// Full JSON export/import of the v2 data, used for manual backup/restore and
/// for seeding the app from a bundled backup.
class BackupService {
  BackupService({
    AccountRepository? accountRepository,
    TxCategoryRepository? categoryRepository,
    TxRepository? txRepository,
    TagRepository? tagRepository,
    RecurringRepository? recurringRepository,
    LedgerService? ledgerService,
  })  : _accounts = accountRepository ?? AccountRepository(),
        _categories = categoryRepository ?? TxCategoryRepository(),
        _txs = txRepository ?? TxRepository(),
        _tags = tagRepository ?? TagRepository(),
        _recurring = recurringRepository ?? RecurringRepository(),
        _ledger = ledgerService ?? LedgerService();

  final AccountRepository _accounts;
  final TxCategoryRepository _categories;
  final TxRepository _txs;
  final TagRepository _tags;
  final RecurringRepository _recurring;
  final LedgerService _ledger;

  String exportJson() {
    final json = {
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': _accounts.all(includeArchived: true).map((a) => a.toJson()).toList(),
      'categories': _categories.all(includeArchived: true).map((c) => c.toJson()).toList(),
      'transactions': _txs.all().map((t) => t.toJson()).toList(),
      'tags': _tags.all(includeArchived: true).map((t) => t.toJson()).toList(),
      'recurringRules': _recurring.all().map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  Future<void> restoreJson(String jsonStr, {bool replaceAll = true}) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (replaceAll) {
      await tombstoneBeforeReplace(
        accounts: _accounts,
        categories: _categories,
        transactions: _txs,
        tags: _tags,
        recurring: _recurring,
      );
      await Future.wait([_accounts.clear(), _categories.clear(), _txs.clear(), _tags.clear(), _recurring.clear()]);
    }
    for (final raw in (data['accounts'] as List<dynamic>? ?? [])) {
      await _accounts.upsert(AccountModel.fromJson(Map<String, dynamic>.from(raw as Map)));
    }
    for (final raw in (data['categories'] as List<dynamic>? ?? [])) {
      await _categories.upsert(TxCategoryModel.fromJson(Map<String, dynamic>.from(raw as Map)));
    }
    final txs = (data['transactions'] as List<dynamic>? ?? [])
        .map((raw) => TxModel.fromJson(Map<String, dynamic>.from(raw as Map)));
    await _txs.putAllFresh(txs);
    for (final raw in (data['tags'] as List<dynamic>? ?? [])) {
      await _tags.upsert(TagModel.fromJson(Map<String, dynamic>.from(raw as Map)));
    }
    for (final raw in (data['recurringRules'] as List<dynamic>? ?? [])) {
      await _recurring.upsert(RecurringRuleModel.fromJson(Map<String, dynamic>.from(raw as Map)));
    }
    await _ledger.recomputeAllBalances();
  }
}
