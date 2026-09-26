import 'dart:math' as math;

import 'package:intl/intl.dart';

/// A currency an account can be held in. Amounts are stored as whole
/// numbers of the smallest unit ([decimals] places): rupiah as-is, dollars
/// as cents, and gold (`XAU`) as milligrams so a balance of 1,250 g is
/// stored as 1250.
class Currency {
  const Currency(this.code, this.name, this.symbol, this.decimals, this.flag);

  final String code;
  final String name;
  final String symbol;
  final int decimals;
  final String flag;

  bool get isRupiah => code == idr;
  bool get isGold => code == gold;

  /// 10^[decimals]: how many stored units make one whole unit.
  int get unit => math.pow(10, decimals).toInt();

  static const idr = 'IDR';
  static const gold = 'XAU';

  /// Supported currencies; rupiah and gold first, then the ones Indonesians
  /// most often hold.
  static const all = [
    Currency('IDR', 'Rupiah', 'Rp', 0, '🇮🇩'),
    Currency('XAU', 'Emas (gram)', 'g', 3, '🥇'),
    Currency('USD', 'Dolar AS', 'US\$', 2, '🇺🇸'),
    Currency('SGD', 'Dolar Singapura', 'S\$', 2, '🇸🇬'),
    Currency('MYR', 'Ringgit Malaysia', 'RM', 2, '🇲🇾'),
    Currency('SAR', 'Riyal Saudi', 'SR', 2, '🇸🇦'),
    Currency('EUR', 'Euro', '€', 2, '🇪🇺'),
    Currency('JPY', 'Yen Jepang', '¥', 0, '🇯🇵'),
    Currency('CNY', 'Yuan Tiongkok', 'CN¥', 2, '🇨🇳'),
    Currency('AUD', 'Dolar Australia', 'A\$', 2, '🇦🇺'),
    Currency('GBP', 'Pound Inggris', '£', 2, '🇬🇧'),
    Currency('HKD', 'Dolar Hong Kong', 'HK\$', 2, '🇭🇰'),
    Currency('KRW', 'Won Korea', '₩', 0, '🇰🇷'),
    Currency('TWD', 'Dolar Taiwan', 'NT\$', 0, '🇹🇼'),
    Currency('THB', 'Baht Thailand', '฿', 2, '🇹🇭'),
    Currency('AED', 'Dirham UEA', 'AED', 2, '🇦🇪'),
    Currency('CHF', 'Franc Swiss', 'CHF', 2, '🇨🇭'),
    Currency('CAD', 'Dolar Kanada', 'C\$', 2, '🇨🇦'),
  ];

  static Currency of(String? code) => all.firstWhere((c) => c.code == code, orElse: () => all.first);

  /// "US$ 1.234,50", "Rp 15.000", "1,250 g".
  String format(int minor, {bool compactGold = true}) {
    final value = minor / unit;
    if (isGold) {
      final g = NumberFormat.decimalPatternDigits(locale: 'id_ID', decimalDigits: 3).format(value);
      // "1,250 g" reads better than "1,250000 g"; trailing zeros are noise.
      final trimmed = compactGold ? g.replaceFirst(RegExp(r',?0+$'), '') : g;
      return '${trimmed.isEmpty ? '0' : trimmed} g';
    }
    return NumberFormat.currency(locale: 'id_ID', symbol: '$symbol ', decimalDigits: decimals).format(value);
  }
}
