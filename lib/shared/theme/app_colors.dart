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

  /// Irsyads portrait-reference palette, owner mandate 22 October 2026.
  /// Existing named visitor palettes remain available below.
  static const Color paper = Color(0xFFF4EADF);
  static const Color ink = Color(0xFF141720);
  static const Color academicBlue = Color(0xFF2D3C57);
  static const Color powderBlue = Color(0xFF8BA2CE);
  static const Color paperShadow = Color(0xFFCFBEAF);
  static const Color forest = Color(0xFF134E4A);
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
  static const Color defaultSeed = academicBlue;
  static const Color presetIrsyads = academicBlue;
  static const Color presetSage = sage;
  static const Color presetOcean = Color(0xFF2E5A7A);
  static const Color presetSand = Color(0xFF9A5B1E);
  static const Color presetLavender = Color(0xFF5B4E8C);
  static const Color presetForest = Color(0xFF2F6B4F);

  static AppColors light(Color seed) => AppColors(
    primary: seed,
    onPrimary: _onAccent(seed),
    primaryContainer: Color.alphaBlend(seed.withValues(alpha: 0.10), paper),
    surface: const Color(0xFFFBF5EE),
    surfaceAlt: paper,
    surfaceRaised: const Color(0xFFFFFFFF),
    border: paperShadow,
    textPrimary: ink,
    textSecondary: const Color(0xFF535767),
    textTertiary: const Color(0xFF62616A),
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
      primary = Color.lerp(primary, paper, 0.22)!;
    }
    return AppColors(
      primary: primary,
      onPrimary: _onAccent(primary),
      primaryContainer: Color.alphaBlend(
        primary.withValues(alpha: 0.14),
        const Color(0xFF1D2330),
      ),
      surface: const Color(0xFF1D2330),
      surfaceAlt: ink,
      surfaceRaised: const Color(0xFF293247),
      border: const Color(0xFF4B5262),
      textPrimary: paper,
      textSecondary: const Color(0xFFC2C6D0),
      textTertiary: const Color(0xFFA9B4C7),
      success: const Color(0xFF7FC8A2),
      danger: const Color(0xFFEE9274),
      warning: const Color(0xFFE5B85C),
      info: const Color(0xFF8DB8D6),
      income: const Color(0xFF7FC8A2),
      expense: const Color(0xFFEE9274),
      transfer: const Color(0xFFA9B6DC),
    );
  }

  // A custom visitor accent may be much lighter than the default blue.
  // Choose the stronger text contrast instead of assuming white text fits.
  static Color _onAccent(Color accent) {
    final luminance = accent.computeLuminance();
    final light = (paper.computeLuminance() + 0.05) / (luminance + 0.05);
    final dark = (luminance + 0.05) / (ink.computeLuminance() + 0.05);
    if (light >= 4.5 || dark >= 4.5) return light >= dark ? paper : ink;
    // Mid-tone custom accents can miss 4.5 with both warm brand inks.
    return 1.05 / (luminance + 0.05) >= (luminance + 0.05) / 0.05
        ? Colors.white
        : Colors.black;
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
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      AppColors.light(AppColors.defaultSeed);
}
