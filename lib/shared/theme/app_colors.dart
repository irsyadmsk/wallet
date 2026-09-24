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

  /// Editorial palette — warm paper, charcoal-green ink, one quiet green
  /// accent, and earthy signal colors (forest income, clay expense, ochre
  /// warning). Documented in DESIGN.md at the repo root.
  static const Color paper = Color(0xFFF6F8F5);
  static const Color ink = Color(0xFF17272B);
  static const Color forest = Color(0xFF19363B);
  static const Color sage = Color(0xFF4F8B70);
  static const Color clay = Color(0xFFC2502F);
  static const Color ochre = Color(0xFFD9A441);
  static const Color bone = Color(0xFFE9E3D6);
  static const Color cream = Color(0xFFE1E0CC);

  /// Legacy names kept so older call sites keep compiling.
  static const Color irsyadsInk = ink;
  static const Color irsyadsMist = paper;
  static const Color irsyadsMint = sage;
  static const Color irsyadsHoney = ochre;
  static const Color irsyadsWisteria = Color(0xFF6E7FAE);
  static const Color irsyadsTeal = Color(0xFF126A5A);

  /// Preset palettes offered in Settings.
  static const Color defaultSeed = forest;
  static const Color presetIrsyads = forest;
  static const Color presetSage = sage;
  static const Color presetOcean = Color(0xFF2E5A7A);
  static const Color presetSand = Color(0xFF9A5B1E);
  static const Color presetLavender = Color(0xFF5B4E8C);
  static const Color presetForest = Color(0xFF2F6B4F);

  static AppColors light(Color seed) => AppColors(
        primary: seed,
        onPrimary: const Color(0xFFF6F8F5),
        primaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.10), paper),
        surface: const Color(0xFFFCFDFB),
        surfaceAlt: paper,
        surfaceRaised: const Color(0xFFFFFFFF),
        border: const Color(0x1C17272B),
        textPrimary: ink,
        textSecondary: const Color(0xFF55615F),
        textTertiary: const Color(0xFF7B8482),
        success: const Color(0xFF2F7A5B),
        danger: const Color(0xFFB4452A),
        warning: const Color(0xFF9C6F1C),
        info: const Color(0xFF3F6E8C),
        income: const Color(0xFF2F7A5B),
        expense: const Color(0xFFB4452A),
        transfer: const Color(0xFF53679A),
      );

  static AppColors dark(Color seed) {
    // Dark seeds would disappear on a dark ground, so lift them until they
    // read as an accent (≥ ~0.45 luminance) while keeping their hue.
    var primary = seed;
    for (var i = 0; i < 8 && primary.computeLuminance() < 0.42; i++) {
      primary = Color.lerp(primary, const Color(0xFFE8F2EC), 0.22)!;
    }
    return AppColors(
      primary: primary,
      onPrimary: const Color(0xFF0D1614),
      primaryContainer: Color.alphaBlend(primary.withValues(alpha: 0.14), const Color(0xFF111B19)),
      surface: const Color(0xFF141E1C),
      surfaceAlt: const Color(0xFF0D1614),
      surfaceRaised: const Color(0xFF1A2623),
      border: const Color(0x24E1E0CC),
      textPrimary: const Color(0xFFECEBDD),
      textSecondary: const Color(0xFFAFB6AE),
      textTertiary: const Color(0xFF808A84),
      success: const Color(0xFF7FC8A2),
      danger: const Color(0xFFEE9274),
      warning: const Color(0xFFE5B85C),
      info: const Color(0xFF8DB8D6),
      income: const Color(0xFF7FC8A2),
      expense: const Color(0xFFEE9274),
      transfer: const Color(0xFFA9B6DC),
    );
  }

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
