import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/services/smart_report_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:intl/date_symbol_data_local.dart';

var _id = 0;
TxModel tx(DateTime d, int amount, {TxType type = TxType.expense, String cat = 'food', String? memo, String? who}) => TxModel(
      id: 'tx${_id++}',
      type: type,
      amount: amount,
      accountId: 'a',
      categoryId: cat,
      date: d,
      memo: memo,
      createdByName: who,
    );

SmartReport build(List<TxModel> all, DateTime month, DateTime now) => SmartReportBuilder.build(
      all: all,
      month: month,
      now: now,
      categoryKey: (id) => id ?? 'unknown',
      categoryName: (k) => {'food': 'Makanan', 'fun': 'Hiburan', 'salary': 'Gaji'}[k] ?? k,
    );

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('totals, savings rate and month-over-month change', () {
    final r = build([
      tx(DateTime(2026, 8, 3), 5000000, type: TxType.income, cat: 'salary'),
      tx(DateTime(2026, 8, 5), 1000000),
      tx(DateTime(2026, 9, 1), 6000000, type: TxType.income, cat: 'salary'),
      tx(DateTime(2026, 9, 4), 1500000),
    ], DateTime(2026, 9), DateTime(2026, 10, 2));
    expect(r.income, 6000000);
    expect(r.expense, 1500000);
    expect(r.savingsRate, closeTo(0.75, 1e-9));
    expect(r.expenseChange, closeTo(0.5, 1e-9));
    expect(r.isCurrentMonth, isFalse);
  });

  test('flags a category spike against its 3-month average', () {
    final all = [
      for (final m in [6, 7, 8]) tx(DateTime(2026, m, 10), 200000, cat: 'fun'),
      tx(DateTime(2026, 9, 10), 900000, cat: 'fun'),
      tx(DateTime(2026, 9, 11), 50000, cat: 'food'),
    ];
    final r = build(all, DateTime(2026, 9), DateTime(2026, 10, 1));
    final fun = r.categories.firstWhere((c) => c.key == 'fun');
    expect(fun.average3, 200000);
    expect(fun.isSpike, isTrue);
    expect(r.narrative.any((n) => n.text.contains('melonjak')), isTrue);
  });

  test('projects month-end spending from the daily run-rate', () {
    final r = build([tx(DateTime(2026, 9, 2), 300000)], DateTime(2026, 9), DateTime(2026, 9, 10));
    expect(r.daysElapsed, 10);
    expect(r.projectedExpense, 900000); // 300k / 10 days × 30 days
  });

  test('detects subscriptions with a steady monthly amount', () {
    final all = [
      for (final m in [7, 8, 9]) tx(DateTime(2026, m, 5), 54990, memo: 'Netflix'),
      tx(DateTime(2026, 7, 9), 20000, memo: 'Parkir'),
      tx(DateTime(2026, 9, 9), 90000, memo: 'Parkir'),
    ];
    final r = build(all, DateTime(2026, 9), DateTime(2026, 10, 1));
    expect(r.subscriptions.map((s) => s.label), ['Netflix']);
    expect(r.subscriptions.first.monthlyAmount, 54990);
  });

  test('breaks spending down per family member', () {
    final r = build([
      tx(DateTime(2026, 9, 1), 100000, who: 'Ayah'),
      tx(DateTime(2026, 9, 2), 300000, who: 'Ibu'),
      tx(DateTime(2026, 9, 3), 50000, who: 'Ayah'),
    ], DateTime(2026, 9), DateTime(2026, 10, 1));
    expect(r.members.first.name, 'Ibu');
    expect(r.members.first.expense, 300000);
    expect(r.members[1].count, 2);
  });

  test('share text contains the headline numbers', () {
    final r = build([tx(DateTime(2026, 9, 1), 100000)], DateTime(2026, 9), DateTime(2026, 10, 1));
    final text = r.toShareText();
    expect(text, contains('September 2026'));
    expect(text, contains('Rp 100.000'));
  });

  test('empty month produces a single explanatory note', () {
    final r = build([], DateTime(2026, 9), DateTime(2026, 9, 15));
    expect(r.isEmpty, isTrue);
    expect(r.narrative, hasLength(1));
    expect(r.actions, isEmpty);
  });
}
