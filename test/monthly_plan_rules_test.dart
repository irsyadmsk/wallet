import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';

AllocationItem fixed(String id, int amount, {String group = 'Rutin'}) =>
  AllocationItem(id: id, group: group, name: id, amount: amount);
AllocationItem saving(String id, int target, int weight, int priority) =>
  AllocationItem(id: id, group: 'Tabungan', name: id, amount: 0,
    rule: PlanRule(kind: 'saving', target: target, weight: weight, priority: priority));

void main() {
  test('one budget allocates salary/bonus while fixed costs stay fixed', () {
    final p = MonthlyPlan(gross: 1000, items: [
      fixed('bpjs', 100, group: 'Potongan gaji'), fixed('home', 400),
      saving('emergency', 200, 50, 1), saving('invest', 100, 30, 2),
      saving('goal', 50, 20, 3),
    ]).recalculate();
    expect(p.available, 900);
    expect(p.items[1].amount, 400);
    expect(p.items.skip(2).map((i) => i.amount), [275, 145, 80]);
    expect(p.unallocated, 0);
    final extra = p.copy(bonus: 100).recalculate();
    expect(extra.items[1].amount, 400);
    expect(extra.items.skip(2).map((i) => i.amount), [325, 175, 100]);
    expect(p.bonus, 0);
  });
  test('insufficient income cuts low priority goals and never makes savings negative', () {
    final p = MonthlyPlan(gross: 500, items: [fixed('home', 300),
      saving('last', 100, 20, 3), saving('first', 150, 50, 1),
      saving('middle', 100, 30, 2)]).recalculate();
    expect(p.items.skip(1).map((i) => i.amount), [0, 150, 50]);
    final deficit = p.copy(gross: 250).recalculate();
    expect(deficit.unallocated, -50);
    expect(deficit.items.skip(1).every((i) => i.amount == 0), isTrue);
  });
  test('weighted allocation accounts for every rupiah with stable rounding', () {
    final p = MonthlyPlan(gross: 7, items: [
      saving('a', 0, 1, 1), saving('b', 0, 1, 1), saving('c', 0, 1, 1)]).recalculate();
    expect(p.items.map((i) => i.amount), [3, 2, 2]);
    expect(p.unallocated, 0);
  });
  test('subscription quote snapshots USD, tax and annual reserve without double tax', () {
    const usd = PlanRule(kind: 'subscription', currency: 'USD', price: 324, taxBps: 1100);
    expect(usd.quote(18000), 64735);
    expect(const PlanRule(kind: 'subscription', price: 11100,
      taxBps: 1100, taxIncluded: true).quote(0), 11100);
    expect(const PlanRule(kind: 'subscription', price: 120000,
      months: 12, taxBps: 1100).quote(0), 11100);
    expect(const PlanRule(kind: 'subscription', currency: 'USD',
      enabled: false, price: 324).quote(0), 0);
    expect(() => usd.quote(0), throwsFormatException);
    final old = MonthlyPlan(fx: 18000, items: const [AllocationItem(id: 's',
      group: 'Digital', name: 'Example', amount: 64735, done: true, rule: usd)]);
    final newer = old.copy(fx: 19000).recalculate();
    expect(newer.items.single.done, isFalse);
    expect(old.items.single.amount, 64735);
    expect(old.fx, 18000);
  });
  test('rollover counts actual deposits and withdrawals once; never planned deposits', () {
    final last = MonthlyPlan(gross: 1000, bonus: 200, items: const [
      AllocationItem(id: 'trip', group: 'Dana', name: 'Trip', amount: 500,
        actual: 500, opening: 500, spent: 200, done: true, rollover: true),
    ]);
    final next = last.forNewMonth(previous: last);
    expect(last.items.single.balance, 800);
    expect(next.items.single.opening, 800);
    expect(next.items.single.actual, isNull);
    expect(next.items.single.spent, 0);
    expect(next.items.single.balance, 800);
    expect(next.bonus, 0);
    expect(next.items.single.done, isFalse);
    expect(next.items.single.amount, 500);
    expect(next.copy(items: [next.items.single.copy(actual: 500)])
      .items.single.balance, 1300);
  });
  test('legacy documents and new metadata round trip in the personal namespace', () {
    final legacy = {'version': 1, 'gross': 1000, 'received': null, 'items': [
      {'id': 'x', 'group': 'Rutin', 'name': 'X', 'note': '', 'amount': 25, 'done': true}]};
    final p = MonthlyPlan.fromJson(legacy);
    expect(p.bonus, 0); expect(p.fx, 0); expect(p.items.single.rule, isNull);
    final enhanced = p.copy(bonus: 50, received: 900, items: [p.items.single.copy(
      actual: 10, opening: -5, spent: 1, rollover: true,
      rule: const PlanRule(kind: 'saving', target: 20, weight: 1, priority: 1))]);
    final read = MonthlyPlan.fromJson(enhanced.toJson());
    expect(read.available, 950);
    expect(read.items.single.balance, 4);
    expect(read.items.single.rule!.weight, 1);
    expect(read.toJson(), enhanced.toJson());
    final invalid = read.toJson();
    (invalid['items'] as List).single['rule']['taxBps'] = 10001;
    expect(() => MonthlyPlan.fromJson(invalid), throwsFormatException);
  });
}
