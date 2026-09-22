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
      builder: builder,
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
