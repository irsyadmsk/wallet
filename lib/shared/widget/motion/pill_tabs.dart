import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/widget/motion/pressable.dart';

class PillTab<T> {
  const PillTab(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented "topic selector": a thin bordered capsule where the active
/// item fills with ink. Scrolls horizontally on narrow screens without a
/// visible scrollbar; each item is keyboard-focusable.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({super.key, required this.tabs, required this.value, required this.onChanged, this.dense = false});

  final List<PillTab<T>> tabs;
  final T value;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in tabs)
                Semantics(
                  selected: t.value == value,
                  child: Pressable(
                    onTap: () => onChanged(t.value),
                    semanticLabel: t.label,
                    hoverLift: 0,
                    pressedScale: 0.95,
                    borderRadius: BorderRadius.circular(999),
                    builder: (context, state, _) {
                      final active = t.value == value;
                      return AnimatedContainer(
                        duration: AppMotion.base,
                        curve: AppMotion.standard,
                        height: dense ? 34 : 40,
                        padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 16),
                        decoration: BoxDecoration(
                          color: active
                              ? c.textPrimary
                              : (state.hovered ? c.textPrimary.withValues(alpha: 0.06) : Colors.transparent),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (t.icon != null) ...[
                              Icon(t.icon, size: 16, color: active ? c.surfaceAlt : c.textSecondary),
                              const SizedBox(width: 6),
                            ],
                            AnimatedDefaultTextStyle(
                              duration: AppMotion.base,
                              style: TextStyle(
                                fontSize: dense ? 12.5 : 13.5,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                color: active ? c.surfaceAlt : c.textSecondary,
                              ),
                              child: Text(t.label),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
