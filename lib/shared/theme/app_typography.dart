import 'package:flutter/material.dart';

/// Owner brand fonts, bundled locally; no runtime font request is needed.
/// Headings: Playfair Display; interface/numbers: Plus Jakarta Sans;
/// quotations: Libre Baskerville. Flutter keeps platform glyph fallback.
abstract class AppTypography {
  static TextTheme textTheme(Color textPrimary, Color textSecondary) {
    final body = Typography.material2021().black.apply(
      fontFamily: 'Plus Jakarta Sans',
    );
    final display = body.apply(fontFamily: 'Playfair Display');
    TextStyle? head(TextStyle? s, double size, FontWeight w, double tracking) =>
        s?.copyWith(
          color: textPrimary,
          fontSize: size,
          fontWeight: w,
          letterSpacing: size * tracking,
          height: 1.22,
        );
    return body.copyWith(
      displayLarge: head(display.displayLarge, 56, FontWeight.w500, -0.035),
      displayMedium: head(display.displayMedium, 44, FontWeight.w500, -0.03),
      displaySmall: head(display.displaySmall, 34, FontWeight.w500, -0.03),
      headlineLarge: head(display.headlineLarge, 30, FontWeight.w500, -0.025),
      headlineMedium: head(display.headlineMedium, 26, FontWeight.w500, -0.025),
      headlineSmall: head(display.headlineSmall, 22, FontWeight.w600, -0.02),
      titleLarge: head(body.titleLarge, 20, FontWeight.w600, -0.01),
      titleMedium: head(body.titleMedium, 16, FontWeight.w600, 0),
      titleSmall: head(body.titleSmall, 14, FontWeight.w600, 0),
      bodyLarge: body.bodyLarge?.copyWith(
        color: textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: textPrimary,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: textSecondary,
        fontSize: 12.5,
        height: 1.4,
      ),
      labelLarge: body.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Tabular-figure style for money so digits don't jitter in lists/charts.
  static TextStyle numeric({
    required double size,
    required FontWeight weight,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: size >= 24 ? -size * 0.025 : 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Display face for hero numbers (net worth, big headings).
  static TextStyle display({
    required double size,
    required FontWeight weight,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.1,
      letterSpacing: -size * 0.035,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Editorial serif accent, e.g. the italic word in a heading.
  static TextStyle serif({
    required double size,
    required Color color,
    bool italic = true,
  }) {
    return TextStyle(
      fontFamily: 'Libre Baskerville',
      fontSize: size,
      color: color,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      height: 1.0,
      letterSpacing: -size * 0.01,
    );
  }
}
