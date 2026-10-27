import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:financial_recording/app/shell_controller.dart';
import 'package:financial_recording/app/sync_controller.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/models/app_settings_model/app_settings_model.dart';
import 'package:financial_recording/data/repositories/settings_repository.dart';
import 'package:financial_recording/presentation/auth/controller/auth_controller.dart';
import 'package:financial_recording/presentation/settings/view/settings_view.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_theme.dart';
import 'package:financial_recording/shared/theme/theme_controller.dart';

class _Guest extends GetxController implements AuthController {
  final signedIn = false.obs;
  @override
  bool get isSignedIn => signedIn.value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedSync extends GetxController implements SyncController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemorySettings extends SettingsRepository {
  AppSettingsModel value = AppSettingsModel()
    ..seedColorValue = const Color(0xFFA0A0A0).toARGB32();
  @override
  AppSettingsModel get current => value;
  @override
  Future<void> save(AppSettingsModel settings) async {
    value = settings;
  }
}

void main() {
  late Directory sandbox;
  late Box<AppSettingsModel> settings;
  setUpAll(() async {
    sandbox = await Directory.systemTemp.createTemp('wallet-theme-test-');
    Hive.init(sandbox.path);
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(AppSettingsModelAdapter());
    }
    settings = await Hive.openBox<AppSettingsModel>(AppBoxes.settings);
    // The unrelated PIN section reads this box; theme changes use RAM below.
    await settings.put('app', AppSettingsModel());
  });
  tearDownAll(() async {
    await Hive.close();
    // Only the isolated directory created above, never application storage.
    if (!sandbox.absolute.path.startsWith(Directory.systemTemp.absolute.path)) {
      throw StateError('Unexpected test sandbox');
    }
    await sandbox.delete(recursive: true);
  });
  for (final scenario in [
    (width: 320.0, scale: 1.5, rtl: false),
    (width: 390.0, scale: 1.5, rtl: true),
    (width: 1024.0, scale: 1.0, rtl: false),
  ]) {
    testWidgets(
      'settings ${scenario.width}/${scenario.scale} RTL=${scenario.rtl}: layout, selection and preference callbacks',
      (tester) async {
        Get.testMode = true;
        final repository = _MemorySettings();
        final theme = Get.put(ThemeController(settingsRepository: repository));
        Get.put<AuthController>(_Guest());
        Get.put<SyncController>(_UnusedSync());
        Get.put(ShellController());
        addTearDown(Get.reset);
        tester.view.physicalSize = Size(scenario.width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          Obx(
            () => MaterialApp(
              theme: AppTheme.light(theme.seedColor.value),
              darkTheme: AppTheme.dark(theme.seedColor.value),
              themeMode: theme.themeMode.value,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
                child: Directionality(
                  textDirection: scenario.rtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: child!,
                ),
              ),
              home: const SettingsView(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          repository.current.seedColorValue,
          const Color(0xFFA0A0A0).toARGB32(),
        );
        expect(find.text('Tinta Hutan'), findsNothing);
        expect(find.text('Tinta Akademik'), findsOneWidget);
        final customTile = find.ancestor(
          of: find.text('Warna Kustom Lainnya'),
          matching: find.byType(ListTile),
        );
        final avatar = tester.widget<CircleAvatar>(
          find.descendant(of: customTile, matching: find.byType(CircleAvatar)),
        );
        final a = avatar.backgroundColor!.computeLuminance();
        final b = (avatar.child! as Icon).color!.computeLuminance();
        expect(
          ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
          greaterThanOrEqualTo(3),
          reason: 'Custom accent selection stays visible',
        );
        final dark = find.text('Gelap');
        await tester.ensureVisible(dark);
        await tester.tap(dark);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(theme.themeMode.value, ThemeMode.dark);
        expect(repository.current.themeModeIndex, ThemeMode.dark.index);
        final academic = find.text('Tinta Akademik');
        await tester.ensureVisible(academic);
        await tester.tap(academic);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          repository.current.seedColorValue,
          AppColors.presetIrsyads.toARGB32(),
        );
        final chip = find.ancestor(
          of: academic,
          matching: find.byType(FilterChip),
        );
        expect(tester.widget<FilterChip>(chip).selected, isTrue);
        expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
        expect(
          find.descendant(of: chip, matching: find.byIcon(Icons.check_rounded)),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
