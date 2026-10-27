import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';

void main() {
  final initial = MonthlyPlan(gross: 100, received: 90, items: const [
    AllocationItem(id: 'deduction', group: 'Potongan gaji', name: 'Potongan contoh', amount: 10, done: true),
    AllocationItem(id: 'transfer', group: 'Tabungan', name: 'Alokasi contoh', amount: 30, done: true),
    AllocationItem(id: 'expense', group: 'Rutin', name: 'Pos contoh', amount: 20),
  ]);
  test('gross, net, received and checklist are distinct; no ledger writes', () {
    expect(initial.net, 90); expect(initial.received, 90);
    expect(initial.planned, 50); expect(initial.completed, 30);
    expect(initial.copy(items: initial.items.map((i) => i.copy(done: false)).toList()).planned, 50);
  });
  test('new month preserves values, resets checks and unknown receipt', () {
    final next = initial.forNewMonth();
    expect(next.received, isNull); expect(next.items.every((i) => !i.done), isTrue);
    expect(initial.items.first.done, isTrue); expect(initial.received, 90);
    expect(MonthlyPlan.fromJson(next.toJson()).planned, 50);
  });
  test('reject malformed amounts and duplicate ids', () {
    for (final value in [-1, 1.2, double.infinity, '100', 1000000000001]) {
      expect(() => planMoney(value), throwsFormatException);
    }
    final bad = initial.toJson(); bad['items'] = [initial.items.first.toJson(), initial.items.first.toJson()];
    expect(() => MonthlyPlan.fromJson(bad), throwsFormatException);
  });
  test('notes and zero amounts roundtrip without coercing unknown received', () {
    final p = MonthlyPlan(items: const [AllocationItem(id: 'z', group: 'Rutin', name: 'Contoh', note: '=teks biasa', amount: 0)]);
    final copy = MonthlyPlan.fromJson(p.toJson());
    expect(copy.received, isNull); expect(copy.items.single.amount, 0); expect(copy.items.single.note, '=teks biasa');
  });
}
