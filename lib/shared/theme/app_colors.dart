import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.income,
    required this.expense,
    required this.transfer,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceRaised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color income;
  final Color expense;
  final Color transfer;

  Color get positiveBalance => success;
  Color get negativeBalance => danger;
  Color get budgetSafe => success;
  Color get budgetWarn => warning;
  Color get budgetOver => danger;

  /// Irsyads brand palette (design-system/irsyads/MASTER.md): mist #f7f8fa,
  /// ink #192a40, mint #66d6bf, honey #f6c76b, wisteria #b7a4e5, and a deep
  /// teal #126a5a for accent text — used as this app's default identity
  /// since it ships under the irsyads.com ecosystem.
  static const Color irsyadsInk = Color(0xFF192A40);
  static const Color irsyadsMist = Color(0xFFF7F8FA);
  static const Color irsyadsMint = Color(0xFF66D6BF);
  static const Color irsyadsHoney = Color(0xFFF6C76B);
  static const Color irsyadsWisteria = Color(0xFFB7A4E5);
  static const Color irsyadsTeal = Color(0xFF126A5A);

  /// Preset palettes offered in Settings.
  static const Color defaultSeed = irsyadsTeal;
  static const Color presetIrsyads = irsyadsTeal;
  static const Color presetSage = Color(0xFF0D9488);
  static const Color presetOcean = Color(0xFF0284C7);
  static const Color presetSand = Color(0xFFD97706);
  static const Color presetLavender = Color(0xFF7C3AED);
  static const Color presetForest = Color(0xFF059669);

  static AppColors light(Color seed) => AppColors(
        primary: seed,
        onPrimary: Colors.white,
        primaryContainer: seed.withValues(alpha: 0.12),
        surface: const Color(0xFFFFFFFF),
        surfaceAlt: irsyadsMist,
        surfaceRaised: const Color(0xFFFFFFFF),
        border: const Color(0xFFE4E7EC),
        textPrimary: irsyadsInk,
        textSecondary: const Color(0xFF56657D),
        textTertiary: const Color(0xFF8D99AD),
        success: const Color(0xFF10B981),
        danger: const Color(0xFFF43F5E),
        warning: irsyadsHoney,
        info: const Color(0xFF0EA5E9),
        income: const Color(0xFF10B981),
        expense: const Color(0xFFF43F5E),
        transfer: irsyadsWisteria,
      );

  static AppColors dark(Color seed) => AppColors(
        primary: Color.lerp(seed, Colors.white, 0.22)!,
        onPrimary: const Color(0xFF0B1420),
        primaryContainer: seed.withValues(alpha: 0.24),
        surface: const Color(0xFF16212F),
        surfaceAlt: const Color(0xFF0F1826),
        surfaceRaised: const Color(0xFF1E2C3D),
        border: const Color(0xFF283A4E),
        textPrimary: const Color(0xFFEEF2F7),
        textSecondary: const Color(0xFFA3B0C4),
        textTertiary: const Color(0xFF6B7A92),
        success: const Color(0xFF34D399),
        danger: const Color(0xFFFB7185),
        warning: const Color(0xFFFBBF24),
        info: const Color(0xFF38BDF8),
        income: const Color(0xFF34D399),
        expense: const Color(0xFFFB7185),
        transfer: const Color(0xFFC4B5F2),
      );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? income,
    Color? expense,
    Color? transfer,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      income: l(income, other.income),
      expense: l(expense, other.expense),
      transfer: l(transfer, other.transfer),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light(AppColors.defaultSeed);
}
