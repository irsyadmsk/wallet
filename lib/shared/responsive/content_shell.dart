import 'package:flutter/material.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';

/// Centers page content and caps its width on tablet/desktop so a screen
/// designed for phone doesn't stretch into an ugly single column on a
/// 1920px laptop. Wrap a screen's scrollable child with this.
class ContentShell extends StatelessWidget {
  const ContentShell({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
        child: Padding(
          padding: padding ?? context.pagePadding,
          child: child,
        ),
      ),
    );
  }
}
