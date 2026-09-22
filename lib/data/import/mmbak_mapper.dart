import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/import/bank_logo_matcher.dart';
import 'package:financial_recording/data/import/mmbak_models.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/models/tag_model/tag_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Pure-Dart mapping from raw `.mmbak` rows (see `MmbakReader`) to v2
/// models. Deliberately has no `dart:ffi`/`dart:io` import so it can run on
/// every platform, including inside `tool/mmbak_to_json.dart`.
class MmbakMapper {
  static const _uuid = Uuid();
  static final _leadingEmoji = RegExp(
    r'^([\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2190}-\u{21FF}️]+)\s*',
    unicode: true,
  );

  static MmbakPreview map(MmbakRawData raw) {
    final warnings = <MmbakWarning>[];

    // ASSETGROUP.uid -> AccountGroupType code (normally identical to TYPE,
    // but resolved via lookup rather than assumed for robustness).
    final groupTypeByUid = <String, int>{};
    for (final g in raw.assetGroups) {
      final uid = g['uid']?.toString() ?? '';
      final type = int.tryParse(g['TYPE']?.toString() ?? '') ?? 7;
      groupTypeByUid[uid] = type;
    }

    final accounts = <AccountModel>[];
    for (final a in raw.assets) {
      final uid = a['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;
      final groupUid = a['groupUid']?.toString() ?? '';
      final groupCode = groupTypeByUid[groupUid] ?? int.tryParse(groupUid) ?? AccountGroupType.other.code;
      final name = (a['NIC_NAME']?.toString() ?? '').trim();
      accounts.add(AccountModel(
        id: uid,
        name: name.isEmpty ? 'Akun' : name,
        groupCode: groupCode,
        orderSeq: int.tryParse(a['ORDERSEQ']?.toString() ?? '') ?? 0,
        externalId: uid,
        iconPath: BankLogoMatcher.match(name),
      ));
    }

    // --- categories, with leading-emoji split and orphan-reference guard ---
    final categories = <TxCategoryModel>[];
    final categoryUidSet = <String>{};
    for (final c in raw.categories) {
      final isDeleted = (int.tryParse(c['C_IS_DEL']?.toString() ?? '0') ?? 0) == 1;
      if (isDeleted) continue;
      final uid = c['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;
      final rawName = (c['NAME']?.toString() ?? '').trim();
      final match = _leadingEmoji.firstMatch(rawName);
      final emoji = match?.group(1)?.trim();
      final name = (match == null ? rawName : rawName.substring(match.end)).trim();
      final pUid = c['pUid']?.toString() ?? '';
      categories.add(TxCategoryModel(
        id: uid,
        name: name.isEmpty ? rawName : name,
        emoji: emoji,
        typeCode: int.tryParse(c['TYPE']?.toString() ?? '') ?? 1,
        parentId: (pUid.isEmpty || pUid == '0') ? null : pUid,
        orderSeq: int.tryParse(c['ORDERSEQ']?.toString() ?? '') ?? 0,
        externalId: uid,
      ));
      categoryUidSet.add(uid);
    }
    // Orphan fallback categories, added lazily only if actually referenced.
    final orphanIncomeId = 'orphan-income';
    final orphanExpenseId = 'orphan-expense';
    var orphanIncomeUsed = false;
    var orphanExpenseUsed = false;

    // --- transactions: income/expense first, then collapse transfer pairs ---
    final transactions = <TxModel>[];
    final transferLegsByPair = <String, List<Map<String, Object?>>>{};
    final transferLegsNoPair = <Map<String, Object?>>[];

    for (final t in raw.transactions) {
      final doType = t['DO_TYPE']?.toString() ?? '';
      if (doType == '3' || doType == '4') {
        final pairId = t['txUidTrans']?.toString() ?? '';
        if (pairId.isEmpty) {
          transferLegsNoPair.add(t);
        } else {
          transferLegsByPair.putIfAbsent(pairId, () => []).add(t);
        }
        continue;
      }
      if (doType != '0' && doType != '1') continue; // unknown DO_TYPE, skip

      final amount = (double.tryParse(t['ZMONEY']?.toString() ?? '0') ?? 0).round();
      final dateMs = int.tryParse(t['ZDATE']?.toString() ?? '');
      final date = dateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(dateMs)
          : (DateTime.tryParse(t['WDATE']?.toString() ?? '') ?? DateTime.now());
      var ctgUid = t['ctgUid']?.toString();
      final isIncome = doType == '0';
      if (ctgUid == null || ctgUid.isEmpty || !categoryUidSet.contains(ctgUid)) {
        ctgUid = isIncome ? orphanIncomeId : orphanExpenseId;
        if (isIncome) {
          orphanIncomeUsed = true;
        } else {
          orphanExpenseUsed = true;
        }
      }
      final memo = (t['ZCONTENT']?.toString() ?? '').trim();
      transactions.add(TxModel(
        id: _uuid.v4(),
        type: isIncome ? TxType.income : TxType.expense,
        amount: amount,
        accountId: t['assetUid']?.toString() ?? '',
        categoryId: ctgUid,
        date: date,
        memo: memo.isEmpty ? null : memo,
        externalId: t['uid']?.toString(),
      ));
    }

    void addTransfer(Map<String, Object?> leg3, {String? pairId}) {
      final amount = (double.tryParse(leg3['ZMONEY']?.toString() ?? '0') ?? 0).round();
      final dateMs = int.tryParse(leg3['ZDATE']?.toString() ?? '');
      final date = dateMs != null ? DateTime.fromMillisecondsSinceEpoch(dateMs) : DateTime.now();
      final memo = (leg3['ZCONTENT']?.toString() ?? '').trim();
      transactions.add(TxModel(
        id: _uuid.v4(),
        type: TxType.transfer,
        amount: amount,
        accountId: leg3['assetUid']?.toString() ?? '',
        toAccountId: leg3['toAssetUid']?.toString(),
        date: date,
        memo: memo.isEmpty ? null : memo,
        externalId: leg3['uid']?.toString(),
        externalPairId: pairId,
      ));
    }

    for (final entry in transferLegsByPair.entries) {
      final legs = entry.value;
      final leg3 = legs.where((r) => r['DO_TYPE']?.toString() == '3').toList();
      final leg4 = legs.where((r) => r['DO_TYPE']?.toString() == '4').toList();
      if (leg3.length == 1) {
        addTransfer(leg3.first, pairId: entry.key);
      } else if (leg4.length == 1) {
        // Only the "in" leg survived — flip it into a canonical "out" leg.
        final l4 = leg4.first;
        final flipped = Map<String, Object?>.from(l4);
        flipped['assetUid'] = l4['toAssetUid'];
        flipped['toAssetUid'] = l4['assetUid'];
        addTransfer(flipped, pairId: entry.key);
        warnings.add(MmbakWarning('Transfer ${entry.key} hanya punya sisi "masuk" — direkonstruksi otomatis.'));
      } else {
        warnings.add(MmbakWarning('Transfer ${entry.key} punya ${legs.length} baris tak terduga — dilewati.'));
      }
    }
    for (final leg in transferLegsNoPair) {
      // No pairing id at all: use this leg as-is, flipping if it's a '4'.
      if (leg['DO_TYPE']?.toString() == '4') {
        final flipped = Map<String, Object?>.from(leg);
        flipped['assetUid'] = leg['toAssetUid'];
        flipped['toAssetUid'] = leg['assetUid'];
        addTransfer(flipped);
      } else {
        addTransfer(leg);
      }
      warnings.add(const MmbakWarningUnpaired());
    }

    if (orphanIncomeUsed) {
      categories.add(TxCategoryModel(id: orphanIncomeId, name: 'Tanpa Kategori (Impor)', typeCode: 0));
      warnings.add(MmbakWarning('Beberapa transaksi pemasukan tidak punya kategori valid di file sumber.'));
    }
    if (orphanExpenseUsed) {
      categories.add(TxCategoryModel(id: orphanExpenseId, name: 'Tanpa Kategori (Impor)', typeCode: 1));
      warnings.add(MmbakWarning('Beberapa transaksi pengeluaran tidak punya kategori valid di file sumber.'));
    }

    // --- tags ---
    final tags = <TagModel>[];
    for (final t in raw.tags) {
      final isDel = (int.tryParse(t['isDel']?.toString() ?? '0') ?? 0) == 1;
      if (isDel) continue;
      final uid = t['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;
      tags.add(TagModel(id: uid, name: t['name']?.toString() ?? uid, externalId: uid));
    }
    final tagIdsByTxUid = <String, List<String>>{};
    for (final link in raw.txTags) {
      final isDel = (int.tryParse(link['isDel']?.toString() ?? '0') ?? 0) == 1;
      if (isDel) continue;
      final txUid = link['txUid']?.toString();
      final tagUid = link['tagUid']?.toString();
      if (txUid == null || tagUid == null) continue;
      tagIdsByTxUid.putIfAbsent(txUid, () => []).add(tagUid);
    }
    if (tagIdsByTxUid.isNotEmpty) {
      for (final tx in transactions) {
        final linked = tagIdsByTxUid[tx.externalId];
        if (linked != null) tx.tagIds.addAll(linked);
      }
    }

    // --- recurring rules (REPEATTRANSACTION) ---
    final recurring = <RecurringRuleModel>[];
    for (final r in raw.repeatTransactions) {
      final isDel = (int.tryParse(r['IS_DEL']?.toString() ?? '0') ?? 0) == 1;
      if (isDel) continue;
      final doType = r['DO_TYPE']?.toString();
      final type = doType == '0'
          ? TxType.income
          : (doType == '3' || doType == '4')
              ? TxType.transfer
              : TxType.expense;
      final nextMs = int.tryParse(r['NEXT_DATE']?.toString() ?? '');
      final endMs = int.tryParse(r['END_DATE']?.toString() ?? '');
      final amount = (double.tryParse(r['AMOUNT_SUB']?.toString() ?? '0') ?? 0).round();
      recurring.add(RecurringRuleModel(
        id: _uuid.v4(),
        type: type,
        amount: amount,
        accountId: r['assetUid']?.toString() ?? '',
        toAccountId: r['toAssetUid']?.toString(),
        categoryId: r['ctgUid']?.toString(),
        memo: r['MEMO']?.toString(),
        startDate: nextMs != null ? DateTime.fromMillisecondsSinceEpoch(nextMs) : DateTime.now(),
        nextRunDate: nextMs != null ? DateTime.fromMillisecondsSinceEpoch(nextMs) : DateTime.now(),
        endDate: endMs != null ? DateTime.fromMillisecondsSinceEpoch(endMs) : null,
        autoPost: false,
        externalId: r['uid']?.toString(),
      ));
    }

    // Ledger-sum balances (mmbak stores no opening balance separately).
    final balanceById = <String, int>{for (final a in accounts) a.id: 0};
    for (final tx in transactions) {
      balanceById[tx.accountId] = (balanceById[tx.accountId] ?? 0) + tx.signedAmountOnPrimaryAccount;
      if (tx.isTransfer && tx.toAccountId != null) {
        balanceById[tx.toAccountId!] = (balanceById[tx.toAccountId!] ?? 0) + tx.amount;
      }
    }
    for (final a in accounts) {
      a.cachedBalance = balanceById[a.id] ?? 0;
    }

    return MmbakPreview(
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      tags: tags,
      recurringRules: recurring,
      warnings: warnings,
    );
  }
}

class MmbakWarningUnpaired extends MmbakWarning {
  const MmbakWarningUnpaired() : super('Satu transfer tanpa id pasangan ditemukan dan diimpor sebagai satu sisi.');
}
