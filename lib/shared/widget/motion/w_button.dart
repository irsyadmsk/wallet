import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/widget/motion/pressable.dart';

enum WButtonVariant { primary, accent, tonal, outline, ghost, danger, inverse }

enum WButtonSize { small, medium, large }

/// The app's primary button. Pill-shaped, with a hover tint, press sink,
/// focus ring and an optional arrow "orb" on the right that rotates -35°
/// and pulls away from the label on hover — the CTA pattern from the hero.
class WButton extends StatelessWidget {
  const WButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = WButtonVariant.primary,
    this.size = WButtonSize.medium,
    this.arrow = false,
    this.loading = false,
    this.expand = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WButtonVariant variant;
  final WButtonSize size;

  /// Show the rotating arrow orb (use for the one main CTA on a surface).
  final bool arrow;
  final bool loading;
  final bool expand;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = _palette(c);
    final height = switch (size) {
      WButtonSize.small => 38.0,
      WButtonSize.medium => 48.0,
      WButtonSize.large => 56.0,
    };
    final fontSize = switch (size) {
      WButtonSize.small => 13.0,
      WButtonSize.medium => 14.5,
      WButtonSize.large => 16.0,
    };
    final orb = height - 8;

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      tooltip: tooltip,
      borderRadius: BorderRadius.circular(height),
      builder: (context, state, _) {
        final hoverBg = state.active && enabled ? Color.lerp(bg, fg, bg.a == 0 ? 0.06 : 0.1)! : bg;
        return AnimatedContainer(
          duration: AppMotion.hover,
          curve: AppMotion.standard,
          height: height,
          padding: EdgeInsets.only(
            left: arrow ? height * 0.42 : height * 0.4,
            right: arrow ? 4 : height * 0.4,
          ),
          decoration: BoxDecoration(
            color: enabled ? hoverBg : c.border.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(height),
            border: border == null ? null : Border.all(color: state.active ? fg.withValues(alpha: 0.5) : border),
            boxShadow: variant == WButtonVariant.primary || variant == WButtonVariant.accent
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: state.hovered && enabled ? 0.28 : 0.0),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: arrow && expand ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.hover,
                child: loading
                    ? SizedBox(
                        key: const ValueKey('spin'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: fontSize + 4, color: enabled ? fg : c.textTertiary),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: enabled ? fg : c.textTertiary,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (arrow) ...[
                AnimatedContainer(
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasized,
                  width: state.active && enabled ? 22 : 14,
                ),
                AnimatedContainer(
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasized,
                  width: orb,
                  height: orb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.active && enabled ? fg : fg.withValues(alpha: enabled ? 1 : 0.4),
                  ),
                  child: AnimatedRotation(
                    turns: state.active && enabled && !AppMotion.reduced(context) ? -35 / 360 : 0,
                    duration: AppMotion.slow,
                    curve: AppMotion.emphasized,
                    child: Icon(Icons.arrow_forward_rounded, size: orb * 0.45, color: bg.a == 0 ? c.surface : bg),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }

  (Color bg, Color fg, Color? border) _palette(AppColors c) => switch (variant) {
        WButtonVariant.primary => (c.textPrimary, c.surfaceAlt, null),
        WButtonVariant.accent => (c.primary, c.onPrimary, null),
        WButtonVariant.tonal => (c.primaryContainer, c.textPrimary, null),
        WButtonVariant.outline => (Colors.transparent, c.textPrimary, c.border),
        WButtonVariant.ghost => (Colors.transparent, c.textPrimary, null),
        WButtonVariant.danger => (c.danger, c.surfaceRaised, null),
        WButtonVariant.inverse => (c.surfaceRaised, c.textPrimary, null),
      };
}

/// Round icon-only button with the same hover/press/focus behaviour.
/// Always pass [tooltip] — it doubles as the accessible label.
class WIconButton extends StatelessWidget {
  const WIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 44,
    this.filled = false,
    this.color,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final bool filled;
  final Color? color;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onPressed,
      tooltip: tooltip,
      semanticLabel: tooltip,
      pressedScale: 0.9,
      hoverLift: 0,
      borderRadius: BorderRadius.circular(size),
      builder: (context, state, _) => AnimatedContainer(
        duration: AppMotion.hover,
        curve: AppMotion.standard,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? (state.active ? Color.lerp(c.surfaceRaised, c.textPrimary, 0.08) : c.surfaceRaised)
              : (state.active ? c.textPrimary.withValues(alpha: 0.07) : Colors.transparent),
          border: filled ? Border.all(color: c.border) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedRotation(
              turns: state.hovered && !AppMotion.reduced(context) ? 0.02 : 0,
              duration: AppMotion.hover,
              child: Icon(icon, size: size * 0.46, color: color ?? c.textPrimary),
            ),
            if (badge)
              Positioned(
                top: size * 0.2,
                right: size * 0.2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c.expense, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}
