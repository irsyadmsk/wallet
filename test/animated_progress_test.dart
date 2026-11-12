import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

void main() {
  Widget host(double value, {bool reduced = false, double secondary = 0}) =>
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 200, child: AnimatedProgress(
            value: value, secondary: secondary,
            color: const Color(0xFF0C6C58), track: const Color(0xFFE1E6DC),
            semanticsLabel: 'Contoh')))));

  testWidgets('grows to a new value and then rests', (t) async {
    await t.pumpWidget(host(0.2));
    await t.pumpAndSettle();
    await t.pumpWidget(host(0.8));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpAndSettle();
    expect(t.hasRunningAnimations, isFalse);
    expect(t.getSemantics(find.bySemanticsLabel('Contoh')).value, '80%');
  });

  testWidgets('reduced motion jumps straight to the value', (t) async {
    await t.pumpWidget(host(0.1, reduced: true));
    await t.pumpWidget(host(0.9, reduced: true));
    await t.pump();
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('out-of-range and non-finite values are clamped', (t) async {
    for (final v in [-1.0, 4.0, double.nan, double.infinity]) {
      await t.pumpWidget(host(v, secondary: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    expect(t.getSemantics(find.bySemanticsLabel('Contoh')).value, '100%');
  });
}
