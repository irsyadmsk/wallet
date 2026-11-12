import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';
import 'package:financial_recording/presentation/monthly/monthly_plan_view.dart';
import 'package:financial_recording/presentation/monthly/widget/plan_kind.dart';
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

/// Synthetic figures only.
MonthlyPlan sample({int gross = 9000}) => MonthlyPlan(gross: gross, items: const [
  AllocationItem(id: 'rent', group: 'Rumah', name: 'Sewa contoh', amount: 3600),
  AllocationItem(id: 'film', group: 'Hiburan', name: 'Film contoh', amount: 0,
    rule: PlanRule(kind: 'subscription', price: 360)),
  AllocationItem(id: 'goal', group: 'Simpanan', name: 'Tujuan contoh', amount: 0,
    rule: PlanRule(kind: 'saving', target: 2000, weight: 0)),
  AllocationItem(id: 'trip', group: 'Dana', name: 'Liburan contoh', amount: 1500,
    opening: 500, rollover: true),
]);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> open(WidgetTester t, MonthlyPlan plan, {double width = 390,
      double scale = 1, bool dark = false, bool reduced = false}) async {
    t.view.physicalSize = Size(width, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
      theme: dark ? AppTheme.dark(AppColors.defaultSeed)
          : AppTheme.light(AppColors.defaultSeed),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale), disableAnimations: reduced),
        child: child!),
      home: MonthlyPlanEditor(service: _Plans(plan)),
    ));
    await t.pumpAndSettle();
  }

  test('kinds follow the stored rule and never count salary deductions', () {
    final plan = sample().copy(items: [...sample().items, const AllocationItem(
      id: 'tax', group: 'Potongan gaji', name: 'Potongan contoh', amount: 100)])
      .recalculate();
    expect(plan.items.map(planKindOf), [PlanKind.fixed, PlanKind.subscription,
      PlanKind.saving, PlanKind.fund, null]);
    final totals = planTotals(plan);
    expect(totals.values.fold(0, (s, v) => s + v), plan.planned);
    expect(totals[PlanKind.subscription], 360);
    expect(totals[PlanKind.saving], 2000);
  });

  for (final s in [(320.0, 1.5), (390.0, 1.0), (768.0, 1.0), (1280.0, 1.0)]) {
    testWidgets('overview fits ${s.$1} at text scale ${s.$2}', (t) async {
      await open(t, sample(), width: s.$1, scale: s.$2, dark: s.$1 == 768);
      expect(find.text('Dana tersedia'), findsOneWidget);
      expect(find.text('Arus alokasi'), findsOneWidget);
      expect(find.text('Belum dialokasikan'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('choosing a flow part filters the list and can be cleared', (t) async {
    await open(t, sample());
    expect(find.text('Sewa contoh'), findsOneWidget);
    await t.ensureVisible(find.text('Langganan'));
    await t.tap(find.text('Langganan'));
    await t.pumpAndSettle();
    expect(find.text('Film contoh'), findsOneWidget);
    expect(find.text('Sewa contoh'), findsNothing);
    expect(find.text('1 dari 4 pos'), findsOneWidget);
    await t.ensureVisible(find.byTooltip('Tampilkan semua bagian'));
    await t.tap(find.byTooltip('Tampilkan semua bagian'));
    await t.pumpAndSettle();
    expect(find.text('Sewa contoh'), findsOneWidget);
    expect(find.text('4 dari 4 pos'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('deficit is named, not only coloured; reduced motion settles at once',
      (t) async {
    await open(t, sample(gross: 5000), reduced: true);
    expect(find.text('Defisit'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.textContaining('Alokasi melebihi dana tersedia'), findsOneWidget);
    expect(t.hasRunningAnimations, isFalse);
    expect(t.takeException(), isNull);
  });
}
