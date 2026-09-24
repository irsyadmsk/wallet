import 'package:flutter/material.dart';

/// Categorical chart hues in fixed order (never cycled past 8 — fold the
/// rest into "Lainnya"). Both modes validated with the dataviz palette
/// validator: lightness band, chroma floor, CVD and normal-vision
/// separation between neighbours. Light ochre sits under 3:1 contrast, so
/// every chart using it also lists values as text.
abstract class ChartPalette {
  static const light = [
    Color(0xFF1F8A70),
    Color(0xFFD8612F),
    Color(0xFF2F74C8),
    Color(0xFFD09200),
    Color(0xFFD0668F),
    Color(0xFF3E8A2E),
    Color(0xFF5A4BB0),
    Color(0xFFC9433F),
  ];

  static const dark = [
    Color(0xFF23A07F),
    Color(0xFFE06A36),
    Color(0xFF4A8BE0),
    Color(0xFFBF8000),
    Color(0xFFD5608C),
    Color(0xFF4E9E3C),
    Color(0xFF8E82E6),
    Color(0xFFE06560),
  ];

  static Color of(BuildContext context, int slot) {
    final list = Theme.of(context).brightness == Brightness.dark ? dark : light;
    return list[slot.clamp(0, list.length - 1)];
  }
}
