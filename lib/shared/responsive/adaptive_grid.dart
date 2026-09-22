import 'package:flutter/material.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

/// Lays out [children] in `context.gridColumns` columns (1 on phone, up to
/// 4 on a wide desktop window) using equal-width cards.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({super.key, required this.children, this.spacing = AppSpacing.lg, this.columnsOverride});

  final List<Widget> children;
  final double spacing;
  final int? columnsOverride;

  @override
  Widget build(BuildContext context) {
    final columns = columnsOverride ?? context.gridColumns;
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final child in children)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - context.gutter * 2 - spacing * (columns - 1)) / columns,
            child: child,
          ),
      ],
    );
  }
}
