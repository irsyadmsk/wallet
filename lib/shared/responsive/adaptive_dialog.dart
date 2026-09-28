import 'package:flutter/material.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

/// Bottom sheet on phone, a centered constrained dialog on tablet/desktop.
/// Every form (add transaction, edit account, edit budget, ...) should
/// route through this so it gets sensible desktop treatment for free.
Future<T?> showAdaptiveSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  if (context.isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _PullDownToClose(child: KeyboardInset(child: builder(ctx))),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
        child: builder(ctx),
      ),
    ),
  );
}

/// Whether the on-screen keyboard is showing. Inside a [KeyboardInset]
/// (which hides the inset from its child's [MediaQuery]) this reads the
/// value it passes down, and rebuilds the caller when it changes.
bool isKeyboardUp(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<_KeyboardScope>();
  return scope?.up ?? MediaQuery.viewInsetsOf(context).bottom > 0;
}

class _KeyboardScope extends InheritedWidget {
  const _KeyboardScope({required this.up, required super.child});
  final bool up;

  @override
  bool updateShouldNotify(_KeyboardScope old) => old.up != up;
}

/// Lifts a bottom sheet above the on-screen keyboard.
///
/// The padding sits *outside* the sheet's scroll view, so the viewport ends
/// at the top of the keyboard and a focused field scrolls into the visible
/// part. (Padding inside the scroll view — the old pattern — made the
/// viewport extend behind the keyboard, and Flutter happily "revealed" the
/// field right under it.) The inset is removed from the child's
/// [MediaQuery] so sheets that still add `viewInsets` themselves don't
/// double it.
class KeyboardInset extends StatelessWidget {
  const KeyboardInset({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    // Eases the sheet up with the keyboard instead of jumping — on phones
    // that report the inset in one step, and smooths per-frame updates on
    // the rest.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: inset),
      child: _KeyboardScope(
        up: inset > 0,
        child: MediaQuery.removeViewInsets(context: context, removeBottom: true, child: child),
      ),
    );
  }
}


/// A sheet's own drag only works on its handle: over a scrolling form the
/// list takes the gesture. This closes the sheet when the user keeps
/// pulling down after the form is already scrolled to the top.
class _PullDownToClose extends StatefulWidget {
  const _PullDownToClose({required this.child});
  final Widget child;

  @override
  State<_PullDownToClose> createState() => _PullDownToCloseState();
}

class _PullDownToCloseState extends State<_PullDownToClose> {
  static const _threshold = 70.0;
  double _pulled = 0;
  bool _closing = false;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollStartNotification) _pulled = 0;
    // Pulling down past the top: Android reports overscroll, iOS a
    // negative (bouncing) offset.
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      _pulled -= n.overscroll;
    } else if (n is ScrollUpdateNotification && n.dragDetails != null && n.metrics.pixels < 0) {
      _pulled = -n.metrics.pixels;
    }
    if (!_closing && _pulled > _threshold) {
      _closing = true;
      Navigator.of(context).maybePop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child);
}
