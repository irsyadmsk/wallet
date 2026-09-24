import 'dart:typed_data';

import 'package:financial_recording/data/import/mmbak_mapper.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';
import 'package:financial_recording/data/import/mmbak_reader.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/repositories/tag_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';

typedef ImportProgressCb = void Function(String phase, double fraction);

class MmbakImportService {
  MmbakImportService({
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

  static bool get isSupportedOnThisPlatform => MmbakReader.isSupported;

  Future<MmbakPreview> analyze({String? path, Uint8List? bytes, ImportProgressCb? onProgress}) async {
    onProgress?.call('Membaca file cadangan', 0.1);
    final raw = await MmbakReader.read(path: path, bytes: bytes);
    onProgress?.call('Memetakan data', 0.6);
    final preview = MmbakMapper.map(raw);
    onProgress?.call('Selesai memindai', 1.0);
    return preview;
  }

  Future<MmbakImportReport> apply(
    MmbakPreview preview, {
    required ImportMode mode,
    ImportProgressCb? onProgress,
  }) async {
    if (mode == ImportMode.replaceAll) {
      onProgress?.call('Menghapus data lama', 0.05);
      await Future.wait([_accounts.clear(), _categories.clear(), _txs.clear(), _tags.clear()]);
    }

    onProgress?.call('Menyimpan akun', 0.2);
    for (final a in preview.accounts) {
      await _accounts.upsert(a);
    }

    onProgress?.call('Menyimpan kategori', 0.35);
    for (final c in preview.categories) {
      await _categories.upsert(c);
    }

    onProgress?.call('Menyimpan tag', 0.4);
    for (final t in preview.tags) {
      await _tags.upsert(t);
    }

    onProgress?.call('Menyimpan transaksi', 0.5);
    if (mode == ImportMode.replaceAll) {
      await _txs.putAllFresh(preview.transactions);
    } else {
      final existingExternalIds = _txs.all().map((t) => t.externalId).whereType<String>().toSet();
      final fresh = preview.transactions.where((t) => t.externalId == null || !existingExternalIds.contains(t.externalId));
      await _txs.putAllFresh(fresh);
    }

    onProgress?.call('Menyimpan aturan berulang', 0.85);
    for (final r in preview.recurringRules) {
      await _recurring.upsert(r);
    }

    onProgress?.call('Menghitung ulang saldo', 0.92);
    await _ledger.recomputeAllBalances();

    onProgress?.call('Selesai', 1.0);
    return MmbakImportReport(
      accountCount: preview.accounts.length,
      categoryCount: preview.categories.length,
      transactionCount: preview.transactions.length,
      tagCount: preview.tags.length,
      warningCount: preview.warnings.length,
      mode: mode,
    );
  }
}
