import 'dart:async';

import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/csv_export_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

enum TxGroupMode {
  date('Tanggal'),
  account('Akun'),
  category('Kategori');

  final String label;
  const TxGroupMode(this.label);
}

class TxGroup {
  final String key;
  final String label;
  final List<TxModel> items;
  final int income;
  final int expense;
  TxGroup({required this.key, required this.label, required this.items, required this.income, required this.expense});

  int get net => income - expense;
}

/// One row of the flattened, lazily built transaction list: either a
/// group header or a transaction inside that group's card.
class TxListRow {
  const TxListRow.header(TxGroup this.group)
      : tx = null,
        isFirst = false,
        isLast = false;
  const TxListRow.item(TxModel this.tx, {required this.isFirst, required this.isLast}) : group = null;

  final TxGroup? group;
  final TxModel? tx;
  final bool isFirst;
  final bool isLast;
}

class TransactionsController extends GetxController {
  final _txs = TxRepository();
  final _accounts = AccountRepository();
  final _categories = TxCategoryRepository();

  final RxList<TxModel> results = <TxModel>[].obs;
  final RxString search = ''.obs;
  final Rx<Set<TxType>?> typeFilter = Rx<Set<TxType>?>(null);
  final RxBool onlyWithReceipt = false.obs;
  final Rx<DateTime?> from = Rx<DateTime?>(null);
  final Rx<DateTime?> to = Rx<DateTime?>(null);
  final Rx<TxGroupMode> groupMode = TxGroupMode.date.obs;
  final RxBool calendarMode = false.obs;

  /// [results] grouped per [groupMode], recomputed only when either changes
  /// instead of on every rebuild.
  final RxList<TxGroup> groups = <TxGroup>[].obs;

  /// [groups] flattened for a lazily built list.
  final RxList<TxListRow> rows = <TxListRow>[].obs;

  Timer? _searchDebounce;

  static final _dayLabel = DateFormat('EEEE, d MMMM y', 'id_ID');
  final Rx<DateTime> calendarMonth = Rx(DateTime(DateTime.now().year, DateTime.now().month, 1));

  void toggleCalendarMode() => calendarMode.value = !calendarMode.value;

  void shiftCalendarMonth(int delta) {
    final m = calendarMonth.value;
    calendarMonth.value = DateTime(m.year, m.month + delta, 1);
  }

  /// Income/expense totals per day-of-month for [calendarMonth], ignoring
  /// the active search/type filters — the calendar is a whole-month
  /// overview; tapping a day narrows the list below via [setDateRange].
  Map<int, (int income, int expense)> get calendarDayTotals {
    final m = calendarMonth.value;
    final from = DateTime(m.year, m.month, 1);
    final to = DateTime(m.year, m.month + 1, 1);
    final txs = _txs.query(TxQuery(from: from, to: to));
    final totals = <int, (int, int)>{};
    for (final t in txs) {
      final day = t.date.day;
      final (inc, exp) = totals[day] ?? (0, 0);
      totals[day] = t.type == TxType.income
          ? (inc + t.idr, exp)
          : t.type == TxType.expense
              ? (inc, exp + t.idr)
              : (inc, exp);
    }
    return totals;
  }

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  @override
  void refresh() {
    var list = _txs.query(TxQuery(
      search: search.value,
      types: typeFilter.value,
      from: from.value,
      to: to.value,
      sort: TxSort.dateDesc,
    ));
    if (onlyWithReceipt.value) {
      list = list.where((t) => t.imagePath != null && t.imagePath!.isNotEmpty).toList();
    }
    results.assignAll(list);
    _rebuildGroups();
  }

  void toggleOnlyWithReceipt() {
    onlyWithReceipt.value = !onlyWithReceipt.value;
    refresh();
  }

  /// Debounced: filtering the whole ledger on every keystroke made typing
  /// stutter on large ledgers.
  void setSearch(String v) {
    search.value = v;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), refresh);
  }

  void setTypeFilter(Set<TxType>? types) {
    typeFilter.value = types;
    refresh();
  }

  void setDateRange(DateTime? f, DateTime? t) {
    from.value = f;
    to.value = t;
    refresh();
  }

  void setGroupMode(TxGroupMode mode) {
    groupMode.value = mode;
    _rebuildGroups();
  }

  final RxBool exporting = false.obs;

  /// Exports the currently filtered/grouped [results] — not the whole
  /// database — matching "export what I'm looking at" from a table view.
  Future<bool> exportVisibleToCsv() async {
    exporting.value = true;
    try {
      final csv = CsvExportService().buildCsv(results);
      return await saveTextFile(
        csv,
        dialogTitle: 'Ekspor transaksi',
        fileName: 'transaksi_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    } finally {
      exporting.value = false;
    }
  }

  /// Groups [results] according to [groupMode] — mirrors the "By Date / By
  /// Account / By Category" grouping in the Money Manager desktop viewer,
  /// each with its own income/expense subtotal.
  void _rebuildGroups() {
    final list = _computeGroups();
    groups.assignAll(list);
    rows.assignAll([
      for (final g in list) ...[
        TxListRow.header(g),
        for (var i = 0; i < g.items.length; i++)
          TxListRow.item(g.items[i], isFirst: i == 0, isLast: i == g.items.length - 1),
      ],
    ]);
  }

  List<TxGroup> _computeGroups() {
    final buckets = <String, List<TxModel>>{};
    final labels = <String, String>{};

    String keyFor(TxModel t) {
      switch (groupMode.value) {
        case TxGroupMode.date:
          // Plain zero-padded key: formatting a date per row is costly on
          // the web; the readable label is formatted once per group.
          final d = t.date;
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          labels.putIfAbsent(key, () => _dayLabel.format(d));
          return key;
        case TxGroupMode.account:
          final acc = _accounts.byId(t.accountId);
          final key = acc?.id ?? 'unknown';
          labels[key] = acc?.name ?? 'Akun tidak dikenal';
          return key;
        case TxGroupMode.category:
          if (t.categoryId == null) {
            labels['none'] = 'Transfer / tanpa kategori';
            return 'none';
          }
          final cat = _categories.byId(t.categoryId!);
          final rootId = cat?.parentId ?? cat?.id ?? 'none';
          labels[rootId] = cat == null ? 'Tanpa kategori' : _categories.pathName(rootId).split(' • ').first;
          return rootId;
      }
    }

    for (final t in results) {
      buckets.putIfAbsent(keyFor(t), () => []).add(t);
    }

    final list = buckets.entries.map((e) {
      final income = e.value.where((t) => t.type == TxType.income).fold(0, (s, t) => s + t.idr);
      final expense = e.value.where((t) => t.type == TxType.expense).fold(0, (s, t) => s + t.idr);
      return TxGroup(key: e.key, label: labels[e.key] ?? e.key, items: e.value, income: income, expense: expense);
    }).toList();

    if (groupMode.value == TxGroupMode.date) {
      list.sort((a, b) => b.key.compareTo(a.key));
    } else {
      list.sort((a, b) => (b.income + b.expense).compareTo(a.income + a.expense));
    }
    return list;
  }
}
