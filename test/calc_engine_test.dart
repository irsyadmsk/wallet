import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/util/calc/calc_engine.dart';

void main() {
  double? ev(String s) => CalcEngine.evaluate(s);

  test('respects operator precedence and parentheses', () {
    expect(ev('2+3×4'), 14);
    expect(ev('(2+3)×4'), 20);
    expect(ev('100-20÷4'), 95);
    expect(ev('-5+10'), 5);
  });

  test('reads Indonesian number formatting', () {
    expect(ev('12.500+2.500'), 15000);
    expect(ev('2,5×4'), 10);
    expect(ev('1.000.000÷4'), 250000);
  });

  test('percent follows phone-calculator rules', () {
    expect(ev('200.000+10%'), closeTo(220000, 1e-6));
    expect(ev('200.000-25%'), closeTo(150000, 1e-6));
    expect(ev('80.000×15%'), closeTo(12000, 1e-6));
    expect(ev('50%'), 0.5);
  });

  test('invalid or incomplete input yields null', () {
    expect(ev('5÷0'), isNull);
    expect(ev('5+'), isNull);
    expect(ev('(5+2'), isNull);
    expect(ev('abc'), isNull);
    expect(ev(''), isNull);
  });

  test('preview tolerates what is still being typed', () {
    expect(CalcEngine.preview('35.000+'), 35000);
    expect(CalcEngine.preview('(10+5'), 15);
    expect(CalcEngine.preview('4×(2+'), 8);
  });

  test('accepts keyboard operator aliases', () {
    expect(ev('6*7'), 42);
    expect(ev('10/4'), 2.5);
  });
}
