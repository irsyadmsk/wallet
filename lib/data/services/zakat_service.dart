import 'package:shared_preferences/shared_preferences.dart';

/// Zakat arithmetic.
///
/// Legal basis (shown in the UI too):
/// - UU No. 23 Tahun 2011 tentang Pengelolaan Zakat — Pasal 22: zakat yang
///   dibayar melalui BAZNAS/LAZ dikurangkan dari penghasilan kena pajak.
/// - PMA No. 52 Tahun 2014 (diubah PMA No. 31 Tahun 2019) tentang syarat dan
///   tata cara penghitungan zakat mal dan zakat fitrah: kadar 2,5%.
///
/// Nisab defaults to 85 g of gold, the standard used by BAZNAS; the gold
/// and rice prices are user-editable because they change constantly.
abstract class Zakat {
  static const rate = 0.025;
  static const nisabGoldGrams = 85.0;
  static const fitrahKgPerPerson = 2.5;

  static int nisabYearly(int goldPricePerGram) => (nisabGoldGrams * goldPricePerGram).round();
  static int nisabMonthly(int goldPricePerGram) => (nisabYearly(goldPricePerGram) / 12).round();

  /// Zakat penghasilan for one month's income; 0 below the monthly nisab.
  static int income({required int monthlyIncome, required int goldPricePerGram}) =>
      monthlyIncome >= nisabMonthly(goldPricePerGram) ? (monthlyIncome * rate).round() : 0;

  /// Zakat mal on wealth held a full lunar year (haul), net of debts due.
  static int wealth({required int assets, required int debtsDue, required int goldPricePerGram, required bool haulReached}) {
    final net = assets - debtsDue;
    if (!haulReached || net < nisabYearly(goldPricePerGram)) return 0;
    return (net * rate).round();
  }

  static int fitrah({required int people, required int ricePricePerKg}) =>
      (people * fitrahKgPerPerson * ricePricePerKg).round();
}

/// Remembers the prices the user last entered, per device.
class ZakatPrefs {
  static const _gold = 'zakat.goldPrice';
  static const _rice = 'zakat.ricePrice';

  static Future<(int?, int?)> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getInt(_gold), p.getInt(_rice));
    } catch (_) {
      return (null, null);
    }
  }

  static Future<void> save({int? gold, int? rice}) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (gold != null) await p.setInt(_gold, gold);
      if (rice != null) await p.setInt(_rice, rice);
    } catch (_) {}
  }
}
