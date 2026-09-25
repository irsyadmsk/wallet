import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Motion tokens (see DESIGN.md). One easing family, a few durations.
/// Interaction feedback stays ≤ 200ms; entrances may take longer.
abstract class AppMotion {
  /// Exponential ease-out used for entrances and reveals — the same curve
  /// as `cubic-bezier(0.16, 1, 0.3, 1)` in the hero reference.
  static const Curve emphasized = Cubic(0.16, 1, 0.3, 1);

  /// Snappy ease for hover/press/tab changes: `cubic-bezier(0.2, 0.8, 0.2, 1)`.
  static const Curve standard = Cubic(0.2, 0.8, 0.2, 1);

  /// Symmetric morph for layout rearrangements (≈ GSAP power3.inOut).
  static const Curve morph = Cubic(0.65, 0, 0.35, 1);

  static const Duration press = Duration(milliseconds: 120);
  static const Duration hover = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration reveal = Duration(milliseconds: 700);
  static const Duration slow = Duration(milliseconds: 500);

  /// Delay between staggered siblings.
  static const Duration stagger = Duration(milliseconds: 60);

  static bool reduced(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Page entrances and page-to-page transitions. Skipped on the web, where
  /// every frame of a staggered entrance or cross-fade re-lays out and
  /// repaints whole pages (two of them during a cross-fade) through
  /// CanvasKit — measured at hundreds of ms per page switch on a large
  /// ledger. Native builds keep them.
  static bool skipPageMotion(BuildContext context) => kIsWeb || reduced(context);

  /// [d], or zero when the user asked the OS to reduce motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
