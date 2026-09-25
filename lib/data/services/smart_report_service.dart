import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/util/money/money_format.dart';

class CategoryInsight {
  const CategoryInsight({
    required this.key,
    required this.name,
    required this.amount,
    required this.share,
    required this.previous,
    required this.average3,
    required this.count,
  });

  final String key;
  final String name;
  final int amount;
  final double share;
  final int previous;

  /// Mean of the three months before the report month.
  final int average3;
  final int count;

  /// Relative change vs. the 3-month average, or null with no history.
  double? get changeVsAverage => average3 <= 0 ? null : (amount - average3) / average3;

  /// Well above its usual level (≥ 1.5× the 3-month average and at least
  /// Rp 100.000 more), so small categories don't raise false alarms.
  bool get isSpike => average3 > 0 && amount >= average3 * 1.5 && amount - average3 >= 100000;
}

class SubscriptionInsight {
  const SubscriptionInsight({required this.label, required this.monthlyAmount, required this.months});
  final String label;
  final int monthlyAmount;
  final int months;
}

class PayeeInsight {
  const PayeeInsight({required this.label, required this.amount, required this.count});
  final String label;
  final int amount;
  final int count;
}

class MemberInsight {
  const MemberInsight({required this.name, required this.expense, required this.income, required this.count});
  final String name;
  final int expense;
  final int income;
  final int count;
}

enum InsightTone { good, neutral, warning }

class ReportNote {
  const ReportNote(this.text, {this.tone = InsightTone.neutral});
  final String text;
  final InsightTone tone;
}

class SmartReport {
  const SmartReport({
    required this.month,
    required this.isCurrentMonth,
    required this.income,
    required this.expense,
    required this.previousIncome,
    required this.previousExpense,
    required this.projectedExpense,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.categories,
    required this.payees,
    required this.subscriptions,
    required this.members,
    required this.weekdaySpend,
    required this.dailySpend,
    required this.largest,
    required this.largestLabel,
    required this.transactionCount,
    required this.narrative,
    required this.actions,
  });

  final DateTime month;
  final bool isCurrentMonth;
  final int income;
  final int expense;
  final int previousIncome;
  final int previousExpense;

  /// For the current month: expense extrapolated from the daily run-rate.
  /// For past months: the actual expense.
  final int projectedExpense;
  final int daysElapsed;
  final int daysInMonth;
  final List<CategoryInsight> categories;
  final List<PayeeInsight> payees;
  final List<SubscriptionInsight> subscriptions;
  final List<MemberInsight> members;

  /// Expense per weekday, Monday = index 0.
  final List<int> weekdaySpend;

  /// Expense per day of month, index 0 = day 1.
  final List<int> dailySpend;
  final int largest;
  final String? largestLabel;
  final int transactionCount;
  final List<ReportNote> narrative;
  final List<ReportNote> actions;

  SmartReport withNotes({required List<ReportNote> narrative, required List<ReportNote> actions}) => SmartReport(
        month: month,
        isCurrentMonth: isCurrentMonth,
        income: income,
        expense: expense,
        previousIncome: previousIncome,
        previousExpense: previousExpense,
        projectedExpense: projectedExpense,
        daysElapsed: daysElapsed,
        daysInMonth: daysInMonth,
        categories: categories,
        payees: payees,
        subscriptions: subscriptions,
        members: members,
        weekdaySpend: weekdaySpend,
        dailySpend: dailySpend,
        largest: largest,
        largestLabel: largestLabel,
        transactionCount: transactionCount,
        narrative: narrative,
        actions: actions,
      );

  int get net => income - expense;
  double? get savingsRate => income <= 0 ? null : net / income;
  double? get expenseChange => previousExpense <= 0 ? null : (expense - previousExpense) / previousExpense;
  double? get incomeChange => previousIncome <= 0 ? null : (income - previousIncome) / previousIncome;
  int get averageDaily => daysElapsed <= 0 ? 0 : (expense / daysElapsed).round();
  bool get isEmpty => transactionCount == 0;

  /// Plain-text version for copying into WhatsApp, notes, or email.
  String toShareText() {
    final title = DateFormat('MMMM y', 'id_ID').format(month);
    final b = StringBuffer()
      ..writeln('Laporan Keuangan — $title')
      ..writeln('')
      ..writeln('Pemasukan   : ${income.rupiah}')
      ..writeln('Pengeluaran : ${expense.rupiah}')
      ..writeln('Selisih     : ${net.signedRupiah}');
    if (savingsRate != null) b.writeln('Rasio tabungan: ${(savingsRate! * 100).toStringAsFixed(0)}%');
    if (categories.isNotEmpty) {
      b
        ..writeln('')
        ..writeln('Kategori terbesar:');
      for (final c in categories.take(5)) {
        b.writeln('• ${c.name}: ${c.amount.rupiah} (${(c.share * 100).toStringAsFixed(0)}%)');
      }
    }
    if (narrative.isNotEmpty) {
      b
        ..writeln('')
        ..writeln('Ringkasan:');
      for (final n in narrative) {
        b.writeln('• ${n.text}');
      }
    }
    if (actions.isNotEmpty) {
      b
        ..writeln('')
        ..writeln('Saran:');
      for (final a in actions) {
        b.writeln('• ${a.text}');
      }
    }
    b
      ..writeln('')
      ..writeln('Dibuat otomatis oleh Wallet');
    return b.toString();
  }
}

/// Builds a [SmartReport] for one month from raw transactions. Pure: no
/// storage access, so it's unit-testable and reusable for any ledger.
class SmartReportBuilder {
  static SmartReport build({
    required List<TxModel> all,
    required DateTime month,
    required DateTime now,
    required String Function(String? categoryId) categoryKey,
    required String Function(String key) categoryName,
  }) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = end.subtract(const Duration(days: 1)).day;
    final isCurrent = now.year == month.year && now.month == month.month;
    final daysElapsed = isCurrent ? now.day : daysInMonth;

    bool inRange(TxModel t, DateTime a, DateTime b) => !t.date.isBefore(a) && t.date.isBefore(b);
    // Month starts computed once: building a local DateTime is costly
    // (time-zone lookup), and doing it inside the per-transaction filters
    // made this report take over a second on a 5,000-row ledger.
    final starts = [for (var n = 0; n <= 3; n++) DateTime(month.year, month.month - n, 1)];
    DateTime monthsBack(int n) => starts[n];

    final cur = all.where((t) => inRange(t, start, end)).toList();
    final prevStart = monthsBack(1);
    final prev = all.where((t) => inRange(t, prevStart, start)).toList();

    int sum(Iterable<TxModel> list, TxType type) =>
        list.where((t) => t.type == type).fold(0, (s, t) => s + t.amount);

    final income = sum(cur, TxType.income);
    final expense = sum(cur, TxType.expense);
    final prevIncome = sum(prev, TxType.income);
    final prevExpense = sum(prev, TxType.expense);

    // Like-for-like comparison mid-month: last month up to the same day.
    final prevSameDay = isCurrent
        ? sum(prev.where((t) => t.date.day <= now.day), TxType.expense)
        : prevExpense;

    final projected = isCurrent && daysElapsed > 0 ? (expense / daysElapsed * daysInMonth).round() : expense;

    // Categories.
    final curExp = cur.where((t) => t.type == TxType.expense).toList();
    Map<String, (int, int)> byCat(Iterable<TxModel> list) {
      final m = <String, (int, int)>{};
      for (final t in list.where((t) => t.type == TxType.expense)) {
        final k = categoryKey(t.categoryId);
        final (a, n) = m[k] ?? (0, 0);
        m[k] = (a + t.amount, n + 1);
      }
      return m;
    }

    final curCat = byCat(cur);
    final prevCat = byCat(prev);
    final hist = [
      for (var i = 1; i <= 3; i++)
        byCat(() {
          final from = monthsBack(i), to = monthsBack(i - 1);
          return all.where((t) => inRange(t, from, to));
        }()),
    ];
    final categories = curCat.entries.map((e) {
      final avg = (hist.fold<int>(0, (s, m) => s + (m[e.key]?.$1 ?? 0)) / 3).round();
      return CategoryInsight(
        key: e.key,
        name: categoryName(e.key),
        amount: e.value.$1,
        count: e.value.$2,
        share: expense <= 0 ? 0 : e.value.$1 / expense,
        previous: prevCat[e.key]?.$1 ?? 0,
        average3: avg,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Payees / memos.
    final payeeMap = <String, (String, int, int)>{};
    for (final t in curExp) {
      final label = _payeeLabel(t);
      if (label == null) continue;
      final k = label.toLowerCase();
      final (l, a, n) = payeeMap[k] ?? (label, 0, 0);
      payeeMap[k] = (l, a + t.amount, n + 1);
    }
    final payees = payeeMap.values.map((v) => PayeeInsight(label: v.$1, amount: v.$2, count: v.$3)).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Subscriptions: same payee, similar amount, in ≥3 of the 4 months
    // ending with the report month.
    final subs = <SubscriptionInsight>[];
    final windowStart = monthsBack(3);
    final window = all.where((t) => t.type == TxType.expense && inRange(t, windowStart, end));
    final byPayee = <String, Map<int, List<int>>>{};
    final payeeLabels = <String, String>{};
    for (final t in window) {
      final label = _payeeLabel(t);
      if (label == null) continue;
      final k = label.toLowerCase();
      payeeLabels[k] = label;
      final mk = t.date.year * 12 + t.date.month;
      byPayee.putIfAbsent(k, () => {}).putIfAbsent(mk, () => []).add(t.amount);
    }
    byPayee.forEach((k, months) {
      if (months.length < 3) return;
      final perMonth = months.values.map((l) => l.fold(0, (s, a) => s + a)).toList();
      final mean = perMonth.reduce((a, b) => a + b) / perMonth.length;
      final maxDev = perMonth.map((v) => (v - mean).abs() / mean).reduce(math.max);
      final txPerMonth = months.values.map((l) => l.length).reduce(math.max);
      if (maxDev <= 0.1 && txPerMonth <= 2) {
        subs.add(SubscriptionInsight(label: payeeLabels[k]!, monthlyAmount: mean.round(), months: months.length));
      }
    });
    subs.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));

    // Members (family ledger).
    final memberMap = <String, (int, int, int)>{};
    for (final t in cur) {
      final who = (t.createdByName?.trim().isNotEmpty ?? false) ? t.createdByName!.trim() : 'Tanpa nama';
      final (e, i, n) = memberMap[who] ?? (0, 0, 0);
      memberMap[who] = (
        e + (t.type == TxType.expense ? t.amount : 0),
        i + (t.type == TxType.income ? t.amount : 0),
        n + 1,
      );
    }
    final members = memberMap.entries
        .map((e) => MemberInsight(name: e.key, expense: e.value.$1, income: e.value.$2, count: e.value.$3))
        .toList()
      ..sort((a, b) => b.expense.compareTo(a.expense));

    // Weekday and daily rhythm.
    final weekday = List<int>.filled(7, 0);
    final daily = List<int>.filled(daysInMonth, 0);
    for (final t in curExp) {
      weekday[t.date.weekday - 1] += t.amount;
      daily[t.date.day - 1] += t.amount;
    }

    TxModel? largest;
    for (final t in curExp) {
      if (largest == null || t.amount > largest.amount) largest = t;
    }

    final report = SmartReport(
      month: start,
      isCurrentMonth: isCurrent,
      income: income,
      expense: expense,
      previousIncome: prevIncome,
      previousExpense: prevExpense,
      projectedExpense: projected,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
      categories: categories,
      payees: payees.take(5).toList(),
      subscriptions: subs,
      members: members,
      weekdaySpend: weekday,
      dailySpend: daily,
      largest: largest?.amount ?? 0,
      largestLabel: largest == null ? null : (_payeeLabel(largest) ?? categoryName(categoryKey(largest.categoryId))),
      transactionCount: cur.length,
      narrative: const [],
      actions: const [],
    );

    return report.withNotes(narrative: _narrate(report, prevSameDay), actions: _advise(report));
  }

  static String? _payeeLabel(TxModel t) {
    final memo = t.memo?.trim();
    if (memo != null && memo.isNotEmpty) return memo.length > 40 ? '${memo.substring(0, 40)}…' : memo;
    if (t.items.isNotEmpty && t.items.first.name.trim().isNotEmpty) return t.items.first.name.trim();
    return null;
  }

  static String _pct(double v) => '${(v.abs() * 100).toStringAsFixed(0)}%';

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  /// Facts first, conclusion after — each sentence states one observation.
  static List<ReportNote> _narrate(SmartReport r, int prevSameDay) {
    if (r.isEmpty) return const [ReportNote('Belum ada transaksi pada periode ini.')];
    final out = <ReportNote>[];
    final monthName = DateFormat('MMMM', 'id_ID').format(r.month);

    // Spending vs last month.
    if (prevSameDay > 0) {
      final ch = (r.expense - prevSameDay) / prevSameDay;
      final when = r.isCurrentMonth ? 'dibanding periode yang sama bulan lalu' : 'dibanding bulan sebelumnya';
      if (ch.abs() < 0.05) {
        out.add(ReportNote('Pengeluaran ${r.expense.rupiah}, relatif stabil $when.'));
      } else {
        out.add(ReportNote(
          'Pengeluaran ${r.expense.rupiah}, ${ch > 0 ? 'naik' : 'turun'} ${_pct(ch)} $when.',
          tone: ch > 0.15 ? InsightTone.warning : (ch < 0 ? InsightTone.good : InsightTone.neutral),
        ));
      }
    } else {
      out.add(ReportNote('Pengeluaran $monthName tercatat ${r.expense.rupiah} dari ${r.transactionCount} transaksi.'));
    }

    // Savings.
    final sr = r.savingsRate;
    if (sr != null) {
      if (sr >= 0.2) {
        out.add(ReportNote('Anda menyisihkan ${_pct(sr)} dari pemasukan — di atas patokan sehat 20%.', tone: InsightTone.good));
      } else if (sr >= 0) {
        out.add(ReportNote('Sisa pemasukan ${_pct(sr)}, masih di bawah patokan 20%.'));
      } else {
        out.add(ReportNote('Pengeluaran melebihi pemasukan sebesar ${(-r.net).rupiah}.', tone: InsightTone.warning));
      }
    }

    // Biggest category.
    if (r.categories.isNotEmpty) {
      final top = r.categories.first;
      out.add(ReportNote('${top.name} menjadi pos terbesar: ${top.amount.rupiah} (${_pct(top.share)} dari total belanja).'));
    }

    // Spikes.
    for (final c in r.categories.where((c) => c.isSpike).take(2)) {
      out.add(ReportNote(
        '${c.name} melonjak ${_pct(c.changeVsAverage!)} di atas rata-rata tiga bulan (${c.average3.rupiah}).',
        tone: InsightTone.warning,
      ));
    }

    // Projection.
    if (r.isCurrentMonth && r.daysElapsed >= 5 && r.daysElapsed < r.daysInMonth) {
      final tone = r.income > 0 && r.projectedExpense > r.income ? InsightTone.warning : InsightTone.neutral;
      out.add(ReportNote(
        'Dengan laju ${r.averageDaily.rupiah} per hari, pengeluaran akhir bulan diperkirakan ${r.projectedExpense.rupiah}.',
        tone: tone,
      ));
    }

    // Weekday rhythm.
    final maxDay = r.weekdaySpend.reduce(math.max);
    if (maxDay > 0 && r.expense > 0 && maxDay / r.expense >= 0.25) {
      out.add(ReportNote('Belanja paling banyak terjadi pada hari ${_days[r.weekdaySpend.indexOf(maxDay)]}.'));
    }

    // Subscriptions.
    if (r.subscriptions.isNotEmpty) {
      final total = r.subscriptions.fold(0, (s, x) => s + x.monthlyAmount);
      out.add(ReportNote('${r.subscriptions.length} pembayaran rutin terdeteksi, total sekitar ${total.rupiah} per bulan.'));
    }

    // Family.
    if (r.members.length > 1) {
      final top = r.members.first;
      out.add(ReportNote('${top.name} mencatat belanja terbanyak di keluarga: ${top.expense.rupiah}.'));
    }
    return out;
  }

  static List<ReportNote> _advise(SmartReport r) {
    if (r.isEmpty) return const [];
    final out = <ReportNote>[];
    final sr = r.savingsRate;
    if (sr != null && sr < 0.2 && r.income > 0) {
      final target = (r.income * 0.2).round();
      out.add(ReportNote('Sisihkan ${target.rupiah} di awal bulan depan agar tabungan mencapai 20%.'));
    }
    final spike = r.categories.where((c) => c.isSpike).firstOrNull;
    if (spike != null) {
      out.add(ReportNote('Pasang anggaran ${spike.name} sebesar ${spike.average3.rupiah} untuk menahan lonjakan.'));
    }
    if (r.isCurrentMonth && r.income > 0 && r.projectedExpense > r.income) {
      final left = r.daysInMonth - r.daysElapsed;
      final room = r.income - r.expense;
      if (left > 0 && room > 0) {
        out.add(ReportNote('Batasi belanja sekitar ${(room / left).round().rupiah} per hari sampai akhir bulan.'));
      }
    }
    if (r.subscriptions.length >= 3) {
      out.add(const ReportNote('Tinjau daftar langganan; hentikan yang jarang dipakai.'));
    }
    if (out.isEmpty) out.add(const ReportNote('Keuangan bulan ini terkendali. Pertahankan kebiasaan mencatat.', tone: InsightTone.good));
    return out;
  }
}

/// Reads the local ledger and builds [SmartReport]s.
class SmartReportService {
  final _txs = TxRepository();
  final _categories = TxCategoryRepository();

  SmartReport forMonth(DateTime month, {DateTime? now}) {
    return SmartReportBuilder.build(
      all: _txs.all(),
      month: month,
      now: now ?? DateTime.now(),
      categoryKey: (id) {
        if (id == null) return 'unknown';
        final c = _categories.byId(id);
        return c?.parentId ?? c?.id ?? 'unknown';
      },
      categoryName: (key) => key == 'unknown' ? 'Tanpa kategori' : (_categories.byId(key)?.name ?? 'Lainnya'),
    );
  }
}
