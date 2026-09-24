import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';

/// The shared "alive" behaviour behind every custom tappable surface:
/// lifts slightly on hover, sinks to [pressedScale] while pressed, shows a
/// focus ring for keyboard users, and gives a light haptic tick on tap.
///
/// Only transform and opacity animate, so it's cheap enough to wrap every
/// button, tile, and card in the app.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.pressedScale = 0.97,
    this.hoverLift = 2,
    this.haptic = true,
    this.builder,
    this.focusRing = true,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final BorderRadius borderRadius;
  final double pressedScale;
  final double hoverLift;
  final bool haptic;
  final bool focusRing;
  final String? tooltip;

  /// Optional: rebuild [child] with the live hover/press state, for
  /// surfaces that change color or reveal detail on hover.
  final Widget Function(BuildContext context, PressState state, Widget child)? builder;

  @override
  State<Pressable> createState() => _PressableState();
}

@immutable
class PressState {
  const PressState({this.hovered = false, this.pressed = false, this.focused = false, this.enabled = true});
  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool enabled;

  /// Hovered, focused, or pressed — the "engaged" look.
  bool get active => hovered || focused || pressed;
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _handleTap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final state = PressState(hovered: _hovered, pressed: _pressed, focused: _focused, enabled: _enabled);
    final content = widget.builder?.call(context, state, widget.child) ?? widget.child;
    final colors = context.colors;

    final scale = !_enabled || reduce ? 1.0 : (_pressed ? widget.pressedScale : 1.0);
    final lift = !_enabled || reduce || _pressed ? 0.0 : (_hovered ? -widget.hoverLift : 0.0);

    Widget result = TweenAnimationBuilder<double>(
      tween: Tween(end: lift),
      duration: AppMotion.hover,
      curve: AppMotion.standard,
      builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.press,
        curve: AppMotion.standard,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: widget.focusRing && _focused
                ? Border.all(color: colors.primary, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: content,
        ),
      ),
    );

    result = FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          _handleTap();
          return null;
        }),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        child: result,
      ),
    );

    result = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: result,
    );
    if (widget.tooltip != null) result = Tooltip(message: widget.tooltip!, child: result);
    return result;
  }
}
