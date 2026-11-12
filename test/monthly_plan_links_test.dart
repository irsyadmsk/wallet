import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';
import 'package:financial_recording/presentation/monthly/monthly_plan_view.dart';
import 'package:financial_recording/presentation/monthly/plan_ledger.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';

class _Plans extends MonthlyPlanService {
  _Plans(this.template) : super('synthetic-user');
  final MonthlyPlan template;
  final local = <String, PlanSnapshot>{};
  @override
  Future<PlanSnapshot?> cached(String period) async => local[period];
  @override
  Future<PlanSnapshot?> remote(String period) async =>
      period == 'template' ? PlanSnapshot(template, 1) : null;
  @override
  Future<void> store(String period, PlanSnapshot snapshot) async =>
      local[period] = snapshot;
  @override
  Future<PlanSnapshot> save(String period, PlanSnapshot snapshot) async =>
      PlanSnapshot(snapshot.plan, snapshot.revision + 1);
}

/// Synthetic ledger: one category, one account, one goal.
class _Ledger implements PlanLedger {
  int spent = 300;
  @override
  bool get available => true;
  @override
  List<PlanLinkOption> categories() => const [PlanLinkOption('cat', 'Dapur contoh')];
  @override
  List<PlanLinkOption> accounts() => const [PlanLinkOption('acc', 'Dompet contoh')];
  @override
  List<PlanLinkOption> goals() => const [PlanLinkOption('goal', 'Tujuan contoh')];
  @override
  PlanItemLinks linksFor(AllocationItem item, DateTime? month) => PlanItemLinks(
    categoryLabel: item.categoryId == 'cat' ? 'Dapur contoh' : null,
    ledgerSpent: item.categoryId == 'cat' && month != null ? spent : null,
    accountLabel: item.accountId == 'acc' ? 'Dompet contoh' : null,
    accountBalance: item.accountId == 'acc' ? 750 : null,
    goalLabel: item.goalId == 'goal' ? 'Tujuan contoh' : null,
    goalCurrent: item.goalId == 'goal' ? 250 : null,
    goalTarget: item.goalId == 'goal' ? 1000 : null,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('links round-trip, survive a new month, and old documents still load', () {
    const linked = AllocationItem(id: 'a', group: 'Rutin', name: 'Dapur', amount: 500,
      categoryId: 'cat', accountId: 'acc', goalId: 'goal');
    final plan = MonthlyPlan(gross: 1000, items: const [linked,
      AllocationItem(id: 'b', group: 'Rutin', name: 'Lain', amount: 100)]);
    final json = plan.toJson();
    expect((json['items'] as List)[1], isNot(contains('categoryId')));
    final back = MonthlyPlan.fromJson(json);
    expect(back.items.first.categoryId, 'cat');
    expect(back.items.first.accountId, 'acc');
    expect(back.items.first.goalId, 'goal');
    expect(back.items.last.categoryId, isNull);
    final next = back.recalculate().forNewMonth(previous: back);
    expect(next.items.first.categoryId, 'cat');
    expect(next.items.first.copy(done: true).goalId, 'goal');
    // Links take no part in the arithmetic.
    expect(plan.planned, 600);
    expect(() => AllocationItem.fromJson({...linked.toJson(), 'categoryId': 7}),
      throwsFormatException);
    expect(() => AllocationItem.fromJson({...linked.toJson(), 'goalId': ''}),
      throwsFormatException);
  });

  Future<void> open(WidgetTester t, MonthlyPlan plan, _Ledger ledger,
      {double width = 390, double scale = 1,
      Future<void> Function(BuildContext, AllocationItem)? onRecord}) async {
    t.view.physicalSize = Size(width, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(AppColors.defaultSeed),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: MonthlyPlanEditor(service: _Plans(plan), ledger: ledger,
        onRecord: onRecord)));
    await t.pumpAndSettle();
  }

  MonthlyPlan sample() => MonthlyPlan(gross: 2000, items: const [
    AllocationItem(id: 'a', group: 'Rutin', name: 'Dapur', amount: 500,
      categoryId: 'cat', accountId: 'acc', goalId: 'goal'),
    AllocationItem(id: 'b', group: 'Potongan gaji', name: 'Potongan contoh', amount: 50),
  ]);

  for (final s in [(320.0, 1.5), (1280.0, 1.0)]) {
    testWidgets('linked figures show beside the plan at ${s.$1}', (t) async {
      final ledger = _Ledger();
      await open(t, sample(), ledger, width: s.$1, scale: s.$2);
      expect(find.textContaining('Buku kas: Dapur contoh terpakai'), findsOneWidget);
      expect(find.textContaining('Saldo Dompet contoh'), findsOneWidget);
      expect(find.textContaining('Tujuan contoh'), findsOneWidget);
      expect(find.textContaining('(25%)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      // Salary deductions cannot be recorded as a transaction from here.
      expect(find.text('Catat transaksi'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('recording goes through the form and overspending is named', (t) async {
    final ledger = _Ledger();
    final service = _Plans(sample());
    AllocationItem? recorded;
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(AppColors.defaultSeed),
      home: MonthlyPlanEditor(service: service, ledger: ledger,
        onRecord: (context, item) async {
          recorded = item;
          ledger.spent = 800; // the user saved a transaction in the form
        })));
    await t.pumpAndSettle();
    final before = service.local.values.map((s) => s.plan.toJson().toString()).toList();
    await t.ensureVisible(find.text('Catat transaksi'));
    await t.tap(find.text('Catat transaksi'));
    await t.pumpAndSettle();
    expect(recorded?.id, 'a');
    expect(find.textContaining('melebihi rencana'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    // The plan document itself is untouched by recording.
    expect(service.local.values.map((s) => s.plan.toJson().toString()).toList(), before);
    expect(t.takeException(), isNull);
  });

  testWidgets('a link is chosen in the item sheet and stored on the item', (t) async {
    final ledger = _Ledger();
    final service = _Plans(MonthlyPlan(gross: 1000, items: const [
      AllocationItem(id: 'x', group: 'Rutin', name: 'Belanja', amount: 400)]));
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(AppColors.defaultSeed),
      home: MonthlyPlanEditor(service: service, ledger: ledger)));
    await t.pumpAndSettle();
    expect(find.textContaining('Buku kas'), findsNothing);
    await t.ensureVisible(find.byTooltip('Ubah Belanja'));
    await t.tap(find.byTooltip('Ubah Belanja'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Tautan ke buku kas'));
    await t.tap(find.text('Tautan ke buku kas'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Kategori pengeluaran'));
    await t.tap(find.text('Tidak ditautkan').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Dapur contoh').last);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Terapkan'));
    await t.tap(find.text('Terapkan'));
    await t.pumpAndSettle();
    final saved = service.local.values.firstWhere(
      (s) => s.plan.items.single.categoryId != null).plan.items.single;
    expect(saved.categoryId, 'cat');
    expect(saved.accountId, isNull);
    expect(find.textContaining('Buku kas: Dapur contoh terpakai'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
