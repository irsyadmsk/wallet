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

  /// Index into `ChartPalette`; 7 is the last slot and doubles as "Lainnya".
  final int slot;
  CategorySlice(this.label, this.amount, this.slot);
}

/// Keeps at most 8 slices: the top 7 by amount plus a folded "Lainnya".
List<CategorySlice> _fold(List<(String, int)> sorted) {
  if (sorted.length <= 8) {
    return [for (var i = 0; i < sorted.length; i++) CategorySlice(sorted[i].$1, sorted[i].$2, i)];
  }
  final rest = sorted.skip(7).fold(0, (s, e) => s + e.$2);
  return [
    for (var i = 0; i < 7; i++) CategorySlice(sorted[i].$1, sorted[i].$2, i),
    CategorySlice('Lainnya', rest, 7),
  ];
}

enum CategoryPeriod { week, month, year, custom }

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

  final Rx<CategoryPeriod> categoryPeriod = CategoryPeriod.month.obs;
  final Rx<DateTime> categoryCustomFrom = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final Rx<DateTime> categoryCustomTo = DateTime.now().obs;
  final RxInt categoryPeriodTotal = 0.obs;

  void setCategoryPeriod(CategoryPeriod p) {
    categoryPeriod.value = p;
    refresh();
  }

  void setCategoryCustomRange(DateTime from, DateTime to) {
    categoryCustomFrom.value = from;
    categoryCustomTo.value = to;
    categoryPeriod.value = CategoryPeriod.custom;
    refresh();
  }

  (DateTime, DateTime) get _categoryRange {
    final now = DateTime.now();
    switch (categoryPeriod.value) {
      case CategoryPeriod.week:
        final start = now.subtract(Duration(days: now.weekday % 7));
        final from = DateTime(start.year, start.month, start.day);
        return (from, from.add(const Duration(days: 7)));
      case CategoryPeriod.month:
        final from = DateTime(now.year, now.month, 1);
        return (from, DateTime(now.year, now.month + 1, 1));
      case CategoryPeriod.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      case CategoryPeriod.custom:
        return (categoryCustomFrom.value, categoryCustomTo.value.add(const Duration(days: 1)));
    }
  }

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

    final (catFrom, catTo) = _categoryRange;
    final expenseTxs = _txs.query(TxQuery(from: catFrom, to: catTo, types: {TxType.expense}));
    categoryPeriodTotal.value = expenseTxs.fold(0, (s, t) => s + t.amount);
    final byCategory = <String, int>{};
    for (final t in expenseTxs) {
      final cat = t.categoryId == null ? null : _categories.byId(t.categoryId!);
      final parentId = cat?.parentId ?? cat?.id;
      final key = parentId ?? 'unknown';
      byCategory[key] = (byCategory[key] ?? 0) + t.amount;
    }
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    expenseByCategory.assignAll(_fold([
      for (final e in entries) (_categories.byId(e.key)?.displayName ?? 'Tanpa kategori', e.value),
    ]));

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

    assetComposition.assignAll(_fold([for (final a in assets) (a.name, a.cachedBalance)]));
    liabilityComposition.assignAll(_fold([for (final l in liabilities) (l.name, -l.cachedBalance)]));
  }
}
