import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _plain = NumberFormat.decimalPattern('id_ID');

extension MoneyX on int {
  String get rupiah => _rupiah.format(this);

  /// e.g. "Rp 1.234.567" with an explicit +/- sign for cashflow contexts.
  String get signedRupiah => this >= 0 ? '+$rupiah' : '-${(-this).rupiah}';

  String get plain => _plain.format(this);

  /// Compact form for chart axis labels, e.g. "1,2 jt", "850 rb".
  String get compact {
    final v = abs();
    final sign = this < 0 ? '-' : '';
    if (v >= 1000000000) return '$sign${(v / 1000000000).toStringAsFixed(1)} M';
    if (v >= 1000000) return '$sign${(v / 1000000).toStringAsFixed(1)} jt';
    if (v >= 1000) return '$sign${(v / 1000).toStringAsFixed(0)} rb';
    return '$sign$v';
  }
}
