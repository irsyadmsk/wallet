import 'package:flutter/material.dart';

abstract class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

enum WindowSize { compact, medium, expanded, large }

extension ResponsiveX on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;

  WindowSize get windowSize {
    final w = _width;
    if (w < Breakpoints.compact) return WindowSize.compact;
    if (w < Breakpoints.medium) return WindowSize.medium;
    if (w < Breakpoints.expanded) return WindowSize.expanded;
    return WindowSize.large;
  }

  bool get isCompact => windowSize == WindowSize.compact;
  bool get isMedium => windowSize == WindowSize.medium;
  bool get isExpandedOrLarger => windowSize == WindowSize.expanded || windowSize == WindowSize.large;

  double get gutter {
    switch (windowSize) {
      case WindowSize.compact:
        return 16;
      case WindowSize.medium:
        return 20;
      case WindowSize.expanded:
        return 24;
      case WindowSize.large:
        return 32;
    }
  }

  int get gridColumns {
    switch (windowSize) {
      case WindowSize.compact:
        return 1;
      case WindowSize.medium:
        return 2;
      case WindowSize.expanded:
        return 3;
      case WindowSize.large:
        return 4;
    }
  }

  EdgeInsets get pagePadding => EdgeInsets.fromLTRB(gutter, gutter, gutter, gutter + 72);

  double get contentMaxWidth {
    switch (windowSize) {
      case WindowSize.compact:
        return double.infinity;
      case WindowSize.medium:
        return 900;
      case WindowSize.expanded:
      case WindowSize.large:
        return 1200;
    }
  }
}
