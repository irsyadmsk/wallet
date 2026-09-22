import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:financial_recording/data/repositories/settings_repository.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/art_icon_theme.dart';
import 'package:financial_recording/shared/theme/theme_config.dart' as legacy;

class ThemeController extends GetxController {
  ThemeController({SettingsRepository? settingsRepository})
      : _settings = settingsRepository ?? SettingsRepository();

  final SettingsRepository _settings;

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rx<Color> seedColor = AppColors.defaultSeed.obs;
  final Rx<ArtShape> artShape = ArtShape.squircle.obs;

  @override
  void onInit() {
    super.onInit();
    final s = _settings.current;
    themeMode.value = ThemeMode.values[s.themeModeIndex.clamp(0, 2)];
    // Automatically migrate older defaults forward: harsh indigo -> calming
    // sage teal -> the irsyads.com brand teal this app now ships under.
    if (s.seedColorValue == 0xFF4F46E5 || s.seedColorValue == 0xFF0D9488) {
      s.seedColorValue = AppColors.defaultSeed.toARGB32();
      _settings.save(s);
    }
    seedColor.value = Color(s.seedColorValue);
    final shapeIdx = s.iconShapeIndex.clamp(0, ArtShape.values.length - 1);
    artShape.value = ArtShape.values[shapeIdx];

    syncLegacyGlobals();
    ever(themeMode, (_) => syncLegacyGlobals());
    ever(seedColor, (_) => syncLegacyGlobals());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final s = _settings.current;
    s.themeModeIndex = mode.index;
    await _settings.save(s);
  }

  Future<void> setSeedColor(Color color) async {
    seedColor.value = color;
    final s = _settings.current;
    s.seedColorValue = color.toARGB32();
    await _settings.save(s);
  }

  Future<void> setArtShape(ArtShape shape) async {
    artShape.value = shape;
    final s = _settings.current;
    s.iconShapeIndex = shape.index;
    await _settings.save(s);
  }

  bool get _isDark {
    if (themeMode.value == ThemeMode.dark) return true;
    if (themeMode.value == ThemeMode.light) return false;
    return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  /// Keeps the handful of reusable form widgets that still read the old
  /// global `primaryColor`/`dangerColor`/... variables (instead of
  /// `context.colors`) in sync with the real, dark-mode-aware palette.
  void syncLegacyGlobals() {
    final c = _isDark ? AppColors.dark(seedColor.value) : AppColors.light(seedColor.value);
    legacy.primaryColor = c.primary;
    legacy.secondaryColor = c.transfer;
    legacy.disabledColor = c.border;
    legacy.textColor = c.textPrimary;
    legacy.secondaryTextColor = c.textSecondary;
    legacy.scaffoldBackgroundColor = c.surfaceAlt;
    legacy.successColor = c.success;
    legacy.dangerColor = c.danger;
    legacy.warningColor = c.warning;
    legacy.infoColor = c.info;
    legacy.inputColor = c.surface;
  }
}
