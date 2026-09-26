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
      builder: (ctx) => KeyboardInset(child: builder(ctx)),
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
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: MediaQuery.removeViewInsets(context: context, removeBottom: true, child: child),
    );
  }
}
