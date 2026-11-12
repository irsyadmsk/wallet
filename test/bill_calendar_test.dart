import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/services/bill_calendar.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/recurring/widget/bill_calendar.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';

/// Synthetic figures only.
RecurringRuleModel rule(String id, DateTime next, {TxType type = TxType.expense,
    RecurrenceFreq freq = RecurrenceFreq.monthly, bool auto = true,
    bool active = true, DateTime? end, String? memo}) =>
    RecurringRuleModel(id: id, type: type, amount: 100, accountId: 'acc',
      memo: memo ?? 'Aturan $id', freq: freq, startDate: next, nextRunDate: next,
      autoPost: auto, isActive: active, endDate: end);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  final nov = DateTime(2026, 11), dec = DateTime(2026, 12);

  test('recurring rules are projected without being advanced', () {
    final weekly = rule('w', DateTime(2026, 11, 3), freq: RecurrenceFreq.weekly);
    final events = billEvents(from: nov, to: dec, rules: [
      weekly,
      rule('m', DateTime(2026, 10, 31)),
      rule('off', DateTime(2026, 11, 5), active: false),
      rule('ended', DateTime(2026, 11, 6), end: DateTime(2026, 11, 1)),
      rule('pay', DateTime(2026, 11, 25), type: TxType.income),
      rule('move', DateTime(2026, 11, 26), type: TxType.transfer),
    ]);
    expect(events.where((e) => e.ruleId == 'w').map((e) => e.date.day), [3, 10, 17, 24]);
    // 31 October steps to the last day of November.
    expect(events.where((e) => e.ruleId == 'm').map((e) => e.date.day), [30]);
    expect(events.any((e) => e.ruleId == 'off' || e.ruleId == 'ended'), isFalse);
    expect(events.firstWhere((e) => e.ruleId == 'pay').income, isTrue);
    expect(events.firstWhere((e) => e.ruleId == 'move').neutral, isTrue);
    expect(weekly.nextRunDate, DateTime(2026, 11, 3));
    final days = events.map((e) => e.date).toList();
    expect(days, [...days]..sort());
  });

  test('debts and liability accounts appear on their due day', () {
    final events = billEvents(from: DateTime(2027, 2), to: DateTime(2027, 3),
      debts: [
        DebtLoanModel(id: 'd', isLoan: false, personName: 'Contoh',
          totalAmount: 500, remainingAmount: 300, dueDate: DateTime(2027, 2, 10, 15)),
        DebtLoanModel(id: 'l', isLoan: true, personName: 'Teman',
          totalAmount: 200, dueDate: DateTime(2027, 2, 11)),
        DebtLoanModel(id: 's', isLoan: false, personName: 'Lunas',
          totalAmount: 100, dueDate: DateTime(2027, 2, 12), isSettled: true),
      ],
      accounts: [
        AccountModel(id: 'card', name: 'Kartu contoh', isLiability: true,
          groupCode: AccountGroupType.card.code, dueDay: 31, cachedBalance: -750),
        AccountModel(id: 'paid', name: 'Kartu lunas', isLiability: true,
          groupCode: AccountGroupType.card.code, dueDay: 5, cachedBalance: 0),
        AccountModel(id: 'usd', name: 'Kartu dolar', isLiability: true,
          groupCode: AccountGroupType.card.code, dueDay: 7, cachedBalance: -900,
          currencyCode: 'USD'),
      ]);
    expect(events.map((e) => e.title), ['Jatuh tempo Kartu dolar',
      'Utang kepada Contoh', 'Piutang dari Teman', 'Jatuh tempo Kartu contoh']);
    expect(events[0].amount, isNull);
    expect(events[1].amount, 300);
    expect(events[1].date, DateTime(2027, 2, 10));
    expect(events[2].income, isTrue);
    // Day 31 falls back to the last day of February.
    expect(events[3].date, DateTime(2027, 2, 28));
    expect(events[3].amount, 750);
  });

  test('reminders cover late, today and tomorrow, and skip manual rules', () {
    final today = DateTime(2026, 11, 12, 9);
    final list = billReminders(today: today,
      rules: [
        rule('auto', DateTime(2026, 11, 13)),
        rule('manual', DateTime(2026, 11, 13), auto: false),
        rule('later', DateTime(2026, 11, 20)),
      ],
      debts: [DebtLoanModel(id: 'd', isLoan: false, personName: 'Contoh',
        totalAmount: 100, dueDate: DateTime(2026, 11, 2))],
      accounts: [AccountModel(id: 'c', name: 'Kartu', isLiability: true,
        groupCode: AccountGroupType.card.code, dueDay: 12, cachedBalance: -50)]);
    expect(list.map((e) => e.title), ['Utang kepada Contoh', 'Jatuh tempo Kartu', 'Aturan auto']);
    expect(dueLabel(DateTime(2026, 11, 2), today), 'Terlambat 10 hari');
    expect(dueLabel(DateTime(2026, 11, 12, 23), today), 'Hari ini');
    expect(dueLabel(DateTime(2026, 11, 13), today), 'Besok');
    expect(dueLabel(DateTime(2026, 11, 17), today), '5 hari lagi');
  });

  for (final s in [(320.0, 1.5), (390.0, 1.0), (1100.0, 1.0)]) {
    testWidgets('calendar fits ${s.$1} at scale ${s.$2} and filters by day', (t) async {
      t.view.physicalSize = Size(s.$1, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final rules = [rule('a', DateTime(2026, 11, 12), memo: 'Internet contoh'),
        rule('b', DateTime(2026, 11, 20), memo: 'Sewa contoh')];
      await t.pumpWidget(MaterialApp(
        theme: s.$1 == 390 ? AppTheme.dark(AppColors.defaultSeed)
            : AppTheme.light(AppColors.defaultSeed),
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(s.$2)), child: child!),
        home: Scaffold(body: SingleChildScrollView(child: BillCalendar(
          today: DateTime(2026, 11, 12),
          load: (from, to) => billEvents(from: from, to: to, rules: rules))))));
      await t.pumpAndSettle();
      // Opens on today.
      expect(find.text('Internet contoh'), findsOneWidget);
      expect(find.text('Sewa contoh'), findsNothing);
      expect(find.textContaining('Hari ini'), findsOneWidget);
      await t.tap(find.textContaining('Lihat semua 2 jatuh tempo'));
      await t.pumpAndSettle();
      expect(find.text('Sewa contoh'), findsOneWidget);
      await t.tap(find.bySemanticsLabel(RegExp('^20 November')));
      await t.pumpAndSettle();
      expect(find.text('Internet contoh'), findsNothing);
      expect(find.text('Sewa contoh'), findsOneWidget);
      await t.tap(find.byTooltip('Bulan berikutnya'));
      await t.pumpAndSettle();
      expect(find.text('Desember 2026'), findsOneWidget);
      expect(find.textContaining('2 jatuh tempo bulan ini'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
