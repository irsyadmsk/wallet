import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';
import 'package:financial_recording/presentation/monthly/monthly_plan_view.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';

class FakePlans extends MonthlyPlanService {
  FakePlans() : super('synthetic-user');
  final local = <String, PlanSnapshot>{}, server = <String, PlanSnapshot>{};
  bool failWrite = false, offline = false;
  @override
  Future<PlanSnapshot?> cached(String period) async => local[period];
  @override
  Future<PlanSnapshot?> remote(String period) async {
    if (offline) throw StateError('Synthetic offline');
    return server[period];
  }

  @override
  Future<void> store(String period, PlanSnapshot snapshot) async {
    if (failWrite) throw StateError('Synthetic quota');
    local[period] = snapshot;
  }

  @override
  Future<PlanSnapshot> save(String period, PlanSnapshot snapshot) async {
    if (offline) throw StateError('Synthetic offline');
    if ((server[period]?.revision ?? 0) != snapshot.revision) {
      throw StateError('Synthetic revision conflict');
    }
    final saved = PlanSnapshot(snapshot.plan, snapshot.revision + 1);
    server[period] = saved;
    local[period] = saved;
    return saved;
  }
}

void main() {
  testWidgets('search filter and group folding preserve every allocation', (
    t,
  ) async {
    await initializeDateFormatting('id_ID');
    final service = FakePlans();
    service.server['template'] = PlanSnapshot(
      MonthlyPlan(
        gross: 100,
        items: const [
          AllocationItem(
            id: 'one',
            group: 'Rutin',
            name: 'Pos satu',
            amount: 10,
          ),
          AllocationItem(
            id: 'two',
            group: 'Cadangan',
            name: 'Pos dua',
            amount: 20,
          ),
        ],
      ),
      1,
    );
    t.view.physicalSize = const Size(390, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppColors.defaultSeed),
        home: MonthlyPlanEditor(service: service),
      ),
    );
    await t.pumpAndSettle();
    final first = find.byWidgetPredicate(
      (w) => w is Checkbox && w.semanticLabel == 'Selesai: Pos satu',
    );
    await t.ensureVisible(first);
    await t.tap(first);
    await t.pumpAndSettle();
    await t.ensureVisible(find.widgetWithText(FilterChip, 'Belum selesai'));
    await t.tap(find.widgetWithText(FilterChip, 'Belum selesai'));
    await t.pumpAndSettle();
    expect(find.text('Pos satu'), findsNothing);
    expect(find.text('Pos dua'), findsOneWidget);
    await t.enterText(
      find.widgetWithText(TextField, 'Cari pos atau kelompok'),
      'tidak cocok',
    );
    await t.pumpAndSettle();
    expect(find.textContaining('Tidak ada pos yang cocok'), findsOneWidget);
    await t.tap(find.byTooltip('Hapus pencarian'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Cadangan'));
    await t.tap(find.text('Cadangan'));
    await t.pumpAndSettle();
    expect(find.text('Pos dua'), findsNothing);
    await t.tap(find.text('Cadangan'));
    await t.pumpAndSettle();
    expect(find.text('Pos dua'), findsOneWidget);
    final current = service.local.values.firstWhere(
      (s) => s.plan.items.length == 2,
    );
    expect(current.plan.items.map((item) => item.id), ['one', 'two']);
    expect(current.plan.items.first.done, isTrue);
    expect(t.takeException(), isNull);
  });
  setUpAll(() => initializeDateFormatting('id_ID'));
  FakePlans fixture() {
    final service = FakePlans();
    final plan = MonthlyPlan(
      gross: 100,
      items: const [
        AllocationItem(
          id: 'sample',
          group: 'Rutin',
          name: 'Pos contoh',
          amount: 10,
        ),
      ],
    );
    service.server['template'] = PlanSnapshot(plan, 1);
    service.server['reserves'] = PlanSnapshot(plan, 1);
    return service;
  }

  Future<void> open(
    WidgetTester t,
    FakePlans service, {
    double width = 390,
    bool dark = false,
  }) async {
    t.view.physicalSize = Size(width, 1000);
    t.view.devicePixelRatio = 1;
    await t.pumpWidget(
      MaterialApp(
        theme: dark
            ? AppTheme.dark(AppColors.defaultSeed)
            : AppTheme.light(AppColors.defaultSeed),
        home: MonthlyPlanEditor(service: service),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'monthly checks persist independently; new month clears checks; reserve does not reset',
    (t) async {
      final service = fixture();
      await open(t, service);
      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      expect(service.local.values.any((s) => s.plan.items.first.done), isTrue);
      await t.ensureVisible(find.byTooltip('Bulan berikutnya'));
      await t.tap(find.byTooltip('Bulan berikutnya'));
      await t.pumpAndSettle();
      expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      await t.tap(find.byTooltip('Bulan sebelumnya'));
      await t.pumpAndSettle();
      expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await t.ensureVisible(find.text('Sekali isi rekening'));
      await t.tap(find.text('Sekali isi rekening'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Bulan'));
      await t.tap(find.text('Bulan'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Sekali isi rekening'));
      await t.tap(find.text('Sekali isi rekening'));
      await t.pumpAndSettle();
      expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(t.takeException(), isNull);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
    },
  );
  testWidgets(
    'failed device save stays visible and blocks month switch; cloud retry resolves',
    (t) async {
      final service = fixture();
      await open(t, service);
      service.failWrite = true;
      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      expect(
        find.textContaining('Penyimpanan perangkat gagal'),
        findsOneWidget,
      );
      expect(
        t
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Bulan berikutnya',
              ),
            )
            .onPressed,
        isNull,
      );
      service.failWrite = false;
      await t.ensureVisible(find.text('Simpan ke akun'));
      await t.tap(find.text('Simpan ke akun'));
      await t.pumpAndSettle();
      expect(find.text('Tersimpan di akun dan perangkat.'), findsOneWidget);
      expect(t.takeException(), isNull);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
    },
  );
  testWidgets(
    'desktop dark: edit nominal, preserve other rows and detect concurrent revision',
    (t) async {
      final service = fixture();
      await open(t, service, width: 1280, dark: true);
      await t.ensureVisible(find.byTooltip('Ubah Pos contoh'));
      await t.tap(find.byTooltip('Ubah Pos contoh'));
      await t.pumpAndSettle();
      await t.enterText(
        find.widgetWithText(TextFormField, 'Rencana nominal (rupiah)'),
        '25',
      );
      await t.tap(find.text('Terapkan'));
      await t.pumpAndSettle();
      final key = service.local.keys.firstWhere(
        (k) => k != 'template' && k != 'reserves',
      );
      expect(service.local[key]!.plan.items.single.amount, 25);
      service.server[key] = PlanSnapshot(MonthlyPlan(gross: 999), 2);
      await t.ensureVisible(find.text('Simpan ke akun'));
      await t.tap(find.text('Simpan ke akun'));
      await t.pumpAndSettle();
      expect(find.textContaining('Simpan belum terkonfirmasi'), findsOneWidget);
      expect(service.server[key]!.plan.gross, 999);
      expect(service.local[key]!.plan.items.single.amount, 25);
      expect(t.takeException(), isNull);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
    },
  );
}
