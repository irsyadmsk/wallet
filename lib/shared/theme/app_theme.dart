import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';

abstract class AppTheme {
  static ThemeData light(Color seed) => _build(AppColors.light(seed), Brightness.light, seed);
  static ThemeData dark(Color seed) => _build(AppColors.dark(seed), Brightness.dark, seed);

  static ThemeData _build(AppColors c, Brightness brightness, Color seed) {
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.textPrimary,
      secondary: c.primary,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.border,
      outlineVariant: c.border,
      error: c.danger,
    );
    final text = AppTypography.textTheme(c.textPrimary, c.textSecondary);

    // Every Material button shares the same state language: a soft tint on
    // hover, a deeper one on press, a visible ring on keyboard focus, and a
    // small lift — so even buttons that don't use the custom [Pressable]
    // respond to the pointer.
    WidgetStateProperty<Color?> overlay(Color base) => WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed)) return base.withValues(alpha: 0.16);
          if (s.contains(WidgetState.hovered)) return base.withValues(alpha: 0.08);
          if (s.contains(WidgetState.focused)) return base.withValues(alpha: 0.12);
          return null;
        });
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>((s) {
      if (s.contains(WidgetState.focused)) return BorderSide(color: c.primary, width: 2);
      return null;
    });
    const pillShape = WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder());
    const btnPadding = WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14));
    final btnText = WidgetStatePropertyAll(text.labelLarge?.copyWith(letterSpacing: 0));
    const motion = Duration(milliseconds: 180);
    final splash = kIsWeb ? InkRipple.splashFactory : InkSparkle.splashFactory;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.surfaceAlt,
      canvasColor: c.surfaceAlt,
      textTheme: text,
      extensions: [c],
      splashFactory: splash,
      hoverColor: c.textPrimary.withValues(alpha: 0.04),
      focusColor: c.primary.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      }),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.22),
        selectionHandleColor: c.primary,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.textTertiary.withValues(alpha: 0.35)),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfaceAlt,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        titleSpacing: 24,
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: c.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        selectedIconTheme: IconThemeData(color: c.primary),
        selectedLabelTextStyle: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
        unselectedIconTheme: IconThemeData(color: c.textTertiary),
        unselectedLabelTextStyle: TextStyle(color: c.textTertiary),
        indicatorColor: c.primaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? c.surfaceAlt : c.textSecondary,
              size: 22,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 11.5,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
            )),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: text.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.surfaceAlt),
        actionTextColor: brightness == Brightness.light ? AppColors.ochre : c.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.textPrimary, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(color: c.surfaceAlt, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
        circularTrackColor: c.border,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        labelStyle: TextStyle(color: c.textSecondary),
        floatingLabelStyle: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: c.textTertiary),
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
          borderSide: BorderSide(color: c.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.border : c.primary),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.textTertiary : c.onPrimary),
          overlayColor: overlay(c.onPrimary),
          elevation: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.pressed)) return 0;
            if (s.contains(WidgetState.hovered)) return 3;
            return 0;
          }),
          shadowColor: WidgetStatePropertyAll(c.primary.withValues(alpha: 0.35)),
          shape: pillShape,
          padding: btnPadding,
          textStyle: btnText,
          side: focusSide,
          animationDuration: motion,
          splashFactory: splash,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(c.primary),
          foregroundColor: WidgetStatePropertyAll(c.onPrimary),
          overlayColor: overlay(c.onPrimary),
          elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) ? 3 : 0),
          shadowColor: WidgetStatePropertyAll(c.primary.withValues(alpha: 0.35)),
          shape: pillShape,
          padding: btnPadding,
          textStyle: btnText,
          side: focusSide,
          animationDuration: motion,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          overlayColor: overlay(c.textPrimary),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.focused)) return BorderSide(color: c.primary, width: 2);
            if (s.contains(WidgetState.hovered)) return BorderSide(color: c.textPrimary.withValues(alpha: 0.5));
            return BorderSide(color: c.border);
          }),
          shape: pillShape,
          padding: btnPadding,
          textStyle: btnText,
          animationDuration: motion,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.primary),
          overlayColor: overlay(c.primary),
          shape: pillShape,
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          textStyle: btnText,
          side: focusSide,
          animationDuration: motion,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          overlayColor: overlay(c.textPrimary),
          side: focusSide,
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          animationDuration: motion,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.textPrimary,
        foregroundColor: c.surfaceAlt,
        elevation: 2,
        hoverElevation: 6,
        focusElevation: 6,
        highlightElevation: 1,
        shape: const StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? c.textPrimary : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? c.surfaceAlt : c.textSecondary),
          overlayColor: overlay(c.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          animationDuration: motion,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        // Light tint + ink text when selected: readable for every chip type,
        // including ones that set their own label style.
        selectedColor: c.primaryContainer,
        secondarySelectedColor: c.primaryContainer,
        // A plain style, not WidgetStateTextStyle: chips merge the theme
        // style into their defaults, which drops a state-resolved color and
        // painted unselected labels white — unreadable in light mode.
        labelStyle: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
        checkmarkColor: c.primary,
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.selected) ? c.primary.withValues(alpha: 0.5) : c.border,
            )),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.surfaceAlt : c.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.primary : c.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }

  /// Exposed for widgets that animate their own transitions.
  static const Curve curve = AppMotion.standard;
}
