import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/services/zakat_service.dart';

void main() {
  const gold = 1500000; // Rp per gram, illustrative

  test('nisab is 85 grams of gold', () {
    expect(Zakat.nisabYearly(gold), 127500000);
    expect(Zakat.nisabMonthly(gold), 10625000);
  });

  test('income zakat is 2.5% only at or above the monthly nisab', () {
    expect(Zakat.income(monthlyIncome: 12000000, goldPricePerGram: gold), 300000);
    expect(Zakat.income(monthlyIncome: 9000000, goldPricePerGram: gold), 0);
  });

  test('wealth zakat needs haul and nets out debts due', () {
    expect(Zakat.wealth(assets: 200000000, debtsDue: 20000000, goldPricePerGram: gold, haulReached: true), 4500000);
    expect(Zakat.wealth(assets: 200000000, debtsDue: 20000000, goldPricePerGram: gold, haulReached: false), 0);
    expect(Zakat.wealth(assets: 130000000, debtsDue: 10000000, goldPricePerGram: gold, haulReached: true), 0);
  });

  test('fitrah is 2.5 kg of rice per person', () {
    expect(Zakat.fitrah(people: 4, ricePricePerKg: 15000), 150000);
  });
}
