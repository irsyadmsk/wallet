import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';

/// A determinate bar that grows to its value instead of jumping.
/// Optional [secondary] draws a lighter continuation after [value]
/// (e.g. a base target followed by its surplus share).
class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    this.secondary = 0,
    this.secondaryColor,
    this.height = 8,
    this.semanticsLabel,
  });

  final double value, secondary, height;
  final Color color, track;
  final Color? secondaryColor;
  final String? semanticsLabel;

  static double _unit(double v) => v.isFinite ? v.clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final first = _unit(value);
    final second = _unit(secondary).clamp(0.0, 1.0 - first);
    final radius = BorderRadius.circular(height);
    return Semantics(
      label: semanticsLabel,
      value: '${((first + second) * 100).round()}%',
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: Offset(first, second)),
        duration: AppMotion.of(context, AppMotion.slow),
        curve: AppMotion.emphasized,
        builder: (context, v, _) => ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: CustomPaint(
              painter: _BarPainter(v.dx, v.dy, color,
                secondaryColor ?? color.withValues(alpha: .45), track,
                Directionality.of(context)),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.a, this.b, this.color, this.secondary, this.track, this.dir);
  final double a, b;
  final Color color, secondary, track;
  final TextDirection dir;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    void bar(double from, double to, Color c) {
      if (to <= from) return;
      final l = dir == TextDirection.ltr ? from : 1 - to;
      canvas.drawRect(
        Rect.fromLTWH(l * size.width, 0, (to - from) * size.width, size.height),
        Paint()..color = c);
    }
    bar(0, a, color);
    bar(a, a + b, secondary);
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.a != a || old.b != b ||
      old.color != color || old.secondary != secondary || old.track != track;
}
