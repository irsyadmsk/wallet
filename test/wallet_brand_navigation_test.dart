import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/data/services/family_service.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_scaffold.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';

class _Auth extends GetxController implements AuthController {
  @override
  String get displayName => 'Pengguna Demo';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sync extends GetxController implements SyncController {
  @override
  final syncing = false.obs;
  @override
  final errorText = RxnString();
  @override
  final household = Rxn<Household>();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Draft extends StatefulWidget {
  const _Draft();
  @override
  State<_Draft> createState() => _DraftState();
}

class _DraftState extends State<_Draft> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: const InputDecoration(labelText: 'Draf sintetis'),
  );
}

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  test('default and visitor accents retain readable text in both themes', () {
    for (final seed in [
      AppColors.defaultSeed,
      AppColors.presetSage,
      AppColors.presetOcean,
      AppColors.presetSand,
      AppColors.presetLavender,
      AppColors.presetForest,
      const Color(0xFFF6E9AA),
    ]) {
      for (final c in [AppColors.light(seed), AppColors.dark(seed)]) {
        expect(contrast(c.primary, c.onPrimary), greaterThanOrEqualTo(4.5));
        expect(
          contrast(c.surfaceAlt, c.textSecondary),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(c.surface, c.textTertiary), greaterThanOrEqualTo(4.5));
      }
    }
  });
  testWidgets(
    'collapse focus restore and destination callbacks keep page draft',
    (t) async {
      Get.testMode = true;
      Get.put<AuthController>(_Auth());
      Get.put<SyncController>(_Sync());
      addTearDown(Get.reset);
      t.view.physicalSize = const Size(1366, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      int selected = 0;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.defaultSeed),
          home: AdaptiveScaffold(
            destinations: const [
              AdaptiveDestination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Beranda',
              ),
              AdaptiveDestination(
                icon: Icons.calendar_month_outlined,
                selectedIcon: Icons.calendar_month,
                label: 'Rencana Bulanan',
              ),
            ],
            index: 0,
            onSelect: (v) => selected = v,
            body: const _Draft(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Jangan hilangkan draf');
      await t.tap(find.byTooltip('Ringkas navigasi'));
      await t.pumpAndSettle();
      expect(find.byTooltip('Perluas navigasi'), findsOneWidget);
      await t.tap(find.byTooltip('Mode fokus'));
      await t.pumpAndSettle();
      expect(find.text('Tampilkan navigasi'), findsOneWidget);
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'Jangan hilangkan draf',
      );
      await t.tap(find.text('Tampilkan navigasi'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Rencana Bulanan'));
      await t.pumpAndSettle();
      expect(selected, 1);
      await t.tap(find.byTooltip('Perluas navigasi'));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'Jangan hilangkan draf',
      );
      expect(t.takeException(), isNull);
    },
  );
}
