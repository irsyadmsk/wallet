import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';

/// A soothing ambient background that replaces flat, sterile single-color backgrounds
/// with a gentle, organic gradient and soft, calming light aura.
///
/// Designed to reduce visual fatigue and evoke a peaceful, minimalist feel.
class ZenBackground extends StatelessWidget {
  const ZenBackground({
    super.key,
    required this.child,
    this.showAura = true,
  });

  final Widget child;
  final bool showAura;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1420),
              Color(0xFF111D2C),
              Color(0xFF0F1826),
            ],
            stops: [0.0, 0.5, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.irsyadsMist,
              Color.alphaBlend(AppColors.irsyadsMint.withValues(alpha: 0.05), AppColors.irsyadsMist),
              AppColors.irsyadsMist,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    return Container(
      decoration: BoxDecoration(gradient: baseGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showAura)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ZenAuraPainter(
                    primaryColor: colors.primary,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _ZenAuraPainter extends CustomPainter {
  _ZenAuraPainter({required this.primaryColor, required this.isDark});

  final Color primaryColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Top-left subtle calming primary aura
    final tlPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.9),
        radius: 0.9,
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.7));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.7), tlPaint);

    // Top-right gentle warm ambient aura for natural depth
    final warmColor = isDark ? const Color(0xFF1E3A34) : const Color(0xFFFDE68A);
    final trPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, -0.8),
        radius: 0.8,
        colors: [
          warmColor.withValues(alpha: isDark ? 0.08 : 0.05),
          warmColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6), trPaint);
  }

  @override
  bool shouldRepaint(covariant _ZenAuraPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.isDark != isDark;
}
