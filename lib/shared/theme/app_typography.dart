import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matches the irsyads.com type system (design-system/irsyads/MASTER.md):
/// Manrope for reading/interface text, Bricolage Grotesque for display
/// headings.
abstract class AppTypography {
  static TextTheme textTheme(Color textPrimary, Color textSecondary) {
    final body = GoogleFonts.manropeTextTheme();
    final display = GoogleFonts.bricolageGrotesqueTextTheme();
    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      displayMedium: display.displayMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      titleLarge: display.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
      titleMedium: display.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
      titleSmall: display.titleSmall?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: body.bodyMedium?.copyWith(color: textPrimary),
      bodySmall: body.bodySmall?.copyWith(color: textSecondary),
      labelLarge: body.labelLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
      labelMedium: body.labelMedium?.copyWith(color: textSecondary),
      labelSmall: body.labelSmall?.copyWith(color: textSecondary),
    );
  }

  /// Tabular-figure style for money so digits don't jitter in lists/charts.
  static TextStyle numeric({required double size, required FontWeight weight, required Color color}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Display face for hero numbers (net worth, big headings).
  static TextStyle display({required double size, required FontWeight weight, required Color color}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
