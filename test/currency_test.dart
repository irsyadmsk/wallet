import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/util/money/money_format.dart';
import 'package:financial_recording/util/thousands_formatter/thousands_formatter.dart';

TextEditingValue _v(String text, [int? caret]) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: caret ?? text.length));

void main() {
  group('Mata uang', () {
    test('format per mata uang', () {
      expect(1250.money('USD'), 'US\$ 12,50');
      expect(15000.money('IDR'), 'Rp 15.000');
      expect(1250.money('XAU'), '1,25 g');
      expect(10000.money('XAU'), '10 g');
      expect(500.money('JPY'), '¥ 500');
    });

    test('isian desimal: dolar & gram', () {
      expect(parseAmount('1.250,5', decimals: 2), 125050);
      expect(parseAmount('0,125', decimals: 3), 125);
      expect(formatAmount(125050, decimals: 2), '1.250,5');
      expect(formatAmount(10000, decimals: 3), '10');

      final f = ThousandsFormatter(decimals: 2);
      expect(f.formatEditUpdate(_v('1250'), _v('12500')).text, '12.500');
      // Titik yang baru diketik dianggap koma desimal.
      expect(f.formatEditUpdate(_v('12.500'), _v('12.500.')).text, '12.500,');
      expect(f.formatEditUpdate(_v('12,5'), _v('12,55')).text, '12,55');
      // Ditempel sekaligus: titik terakhir = desimal.
      expect(f.formatEditUpdate(_v(''), _v('1250.75')).text, '1.250,75');
      // Lebih dari 2 desimal ditolak.
      expect(f.formatEditUpdate(_v('12,55'), _v('12,555')).text, '12,55');
    });

    test('kurs dari feed dunia & konversi ke rupiah', () {
      final parsed = CurrencyService.parseFxFeed({
        'date': '2026-09-26',
        'idr': {'usd': 1 / 16000, 'eur': 1 / 18000, 'xau': 1 / (2400000 * 31.1034768)},
      });
      expect(parsed.date, '2026-09-26');
      expect(parsed.rates['USD']!.round(), 16000);
      expect(parsed.spotGoldPerGram!.round(), 2400000);

      final fx = CurrencyService.instance;
      fx.debugSetRates(parsed.rates, gold: const GoldPrice(sell: 2650000, buyback: 2385000, source: 'tes'));
      expect(fx.toIdr(1250, 'USD'), 200000); // US$ 12,50
      expect(fx.toIdr(2500, Currency.gold), 5962500); // 2,5 g × buyback
      expect(fx.toIdr(99, 'IDR'), 99);
      expect(fx.toIdr(100, 'KRW'), 0); // kurs tak dikenal: tidak dinilai
      expect(fx.fromIdr(160000, 'USD'), 1000);
      expect(fx.convert(1000, 'USD', 'EUR'), 889);
    });
  });
}
