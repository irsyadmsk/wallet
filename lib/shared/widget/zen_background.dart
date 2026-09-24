import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';

/// Page background. Formerly a tinted gradient with a coloured aura; the
/// editorial design uses the plain paper surface everywhere (DESIGN.md), so
/// this now just paints `surfaceAlt`. Kept so existing screens needn't
/// change; [showAura] is accepted and ignored.
class ZenBackground extends StatelessWidget {
  const ZenBackground({
    super.key,
    required this.child,
    this.showAura = true,
  });

  final Widget child;
  final bool showAura;

  @override
  Widget build(BuildContext context) => ColoredBox(color: context.colors.surfaceAlt, child: child);
}
