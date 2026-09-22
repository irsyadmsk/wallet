import 'package:get/get.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

class MonthPoint {
  final DateTime month;
  final int income;
  final int expense;
  MonthPoint(this.month, this.income, this.expense);
}

class NetWorthPoint {
  final DateTime month;
  final int netWorth;
  NetWorthPoint(this.month, this.netWorth);
}

class CategorySlice {
  final String label;
  final int amount;
  final int colorValue;
  CategorySlice(this.label, this.amount, this.colorValue);
}

const _palette = [
  0xFF126A5A,
  0xFF66D6BF,
  0xFFF6C76B,
  0xFFB7A4E5,
  0xFF0EA5E9,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFF64748B,
];

class ReportsController extends GetxController {
  final _txs = TxRepository();
  final _categories = TxCategoryRepository();
  final _accounts = AccountRepository();

  final RxInt monthsBack = 6.obs;
  final RxList<MonthPoint> monthly = <MonthPoint>[].obs;
  final RxList<NetWorthPoint> netWorthHistory = <NetWorthPoint>[].obs;
  final RxList<CategorySlice> expenseByCategory = <CategorySlice>[].obs;
  final RxList<CategorySlice> assetComposition = <CategorySlice>[].obs;
  final RxList<CategorySlice> liabilityComposition = <CategorySlice>[].obs;
  final RxInt periodIncome = 0.obs;
  final RxInt periodExpense = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  void setMonthsBack(int n) {
    monthsBack.value = n;
    refresh();
  }

  @override
  void refresh() {
    final now = DateTime.now();
    final points = <MonthPoint>[];
    for (var i = monthsBack.value - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final next = DateTime(m.year, m.month + 1, 1);
      final txs = _txs.query(TxQuery(from: m, to: next));
      final income = txs.where((t) => t.type == TxType.income).fold(0, (s, t) => s + t.amount);
      final expense = txs.where((t) => t.type == TxType.expense).fold(0, (s, t) => s + t.amount);
      points.add(MonthPoint(m, income, expense));
    }
    monthly.assignAll(points);
    periodIncome.value = points.fold(0, (s, p) => s + p.income);
    periodExpense.value = points.fold(0, (s, p) => s + p.expense);

    final from = DateTime(now.year, now.month - (monthsBack.value - 1), 1);
    final expenseTxs = _txs.query(TxQuery(from: from, types: {TxType.expense}));
    final byCategory = <String, int>{};
    for (final t in expenseTxs) {
      final cat = t.categoryId == null ? null : _categories.byId(t.categoryId!);
      final parentId = cat?.parentId ?? cat?.id;
      final key = parentId ?? 'unknown';
      byCategory[key] = (byCategory[key] ?? 0) + t.amount;
    }
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final slices = <CategorySlice>[];
    for (var i = 0; i < entries.length; i++) {
      final cat = _categories.byId(entries[i].key);
      slices.add(CategorySlice(cat?.displayName ?? 'Lainnya', entries[i].value, _palette[i % _palette.length]));
    }
    expenseByCategory.assignAll(slices);

    _refreshNetWorthHistory(now);
    _refreshComposition();
  }

  /// Replays the whole ledger up to the end of each of the last
  /// [monthsBack] months so the trend reflects the account balances as
  /// they actually stood at each month-end (not just today's snapshot).
  void _refreshNetWorthHistory(DateTime now) {
    final accounts = _accounts.all(includeArchived: true);
    final allTxs = _txs.all()..sort((a, b) => a.date.compareTo(b.date));

    final balances = <String, int>{for (final a in accounts) a.id: a.openingBalance};
    var txIndex = 0;
    final points = <NetWorthPoint>[];

    for (var i = monthsBack.value - 1; i >= 0; i--) {
      final cutoff = DateTime(now.year, now.month - i + 1, 1);
      while (txIndex < allTxs.length && allTxs[txIndex].date.isBefore(cutoff)) {
        final t = allTxs[txIndex];
        balances[t.accountId] = (balances[t.accountId] ?? 0) + t.signedAmountOnPrimaryAccount;
        if (t.isTransfer && t.toAccountId != null) {
          balances[t.toAccountId!] = (balances[t.toAccountId!] ?? 0) + t.amount;
        }
        txIndex++;
      }
      final netWorth = balances.values.fold(0, (s, v) => s + v);
      points.add(NetWorthPoint(DateTime(now.year, now.month - i, 1), netWorth));
    }
    netWorthHistory.assignAll(points);
  }

  void _refreshComposition() {
    final accounts = _accounts.all();
    final assets = accounts.where((a) => !a.isLiability && a.cachedBalance > 0).toList()
      ..sort((a, b) => b.cachedBalance.compareTo(a.cachedBalance));
    final liabilities = accounts.where((a) => a.isLiability && a.cachedBalance < 0).toList()
      ..sort((a, b) => a.cachedBalance.compareTo(b.cachedBalance));

    assetComposition.assignAll([
      for (var i = 0; i < assets.length; i++)
        CategorySlice(assets[i].name, assets[i].cachedBalance, _palette[i % _palette.length]),
    ]);
    liabilityComposition.assignAll([
      for (var i = 0; i < liabilities.length; i++)
        CategorySlice(liabilities[i].name, -liabilities[i].cachedBalance, _palette[i % _palette.length]),
    ]);
  }
}
