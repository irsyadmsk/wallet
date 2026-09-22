import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';

abstract class AppTheme {
  static ThemeData light(Color seed) => _build(AppColors.light(seed), Brightness.light, seed);
  static ThemeData dark(Color seed) => _build(AppColors.dark(seed), Brightness.dark, seed);

  static ThemeData _build(AppColors c, Brightness brightness, Color seed) {
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
      primary: c.primary,
      surface: c.surface,
      error: c.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.surfaceAlt,
      canvasColor: c.surfaceAlt,
      textTheme: AppTypography.textTheme(c.textPrimary, c.textSecondary),
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfaceAlt,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.textTheme(c.textPrimary, c.textSecondary).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: c.border.withValues(alpha: 0.7), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        selectedIconTheme: IconThemeData(color: c.primary),
        selectedLabelTextStyle: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
        unselectedIconTheme: IconThemeData(color: c.textTertiary),
        unselectedLabelTextStyle: TextStyle(color: c.textTertiary),
        indicatorColor: c.primaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceAlt,
        selectedColor: c.primaryContainer,
        labelStyle: TextStyle(color: c.textPrimary),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
      ),
    );
  }
}
