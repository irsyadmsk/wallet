import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/data/services/receipt_ocr_service.dart';

void main() {
  final service = ReceiptOcrService();

  test('parses a typical minimarket receipt', () {
    const text = '''
Indomaret
Jl. Sudirman No. 1
21/09/2026 14:32

Indomie Goreng       2   7.000
Teh Botol            1   5.000
Roti Tawar            1   12.000

Subtotal                 24.000
PPN 11%                    2.640
Total Bayar               26.640
Tunai                     30.000
Kembali                    3.360
''';
    final result = service.parseText(text);
    expect(result.amount, 26640);
    expect(result.date, DateTime(2026, 9, 21));
    expect(result.merchant, 'Indomaret');
  });

  test('picks the largest total-labeled line over subtotal', () {
    const text = '''
Warung Makan Bahagia
TOTAL ITEM: 3
Subtotal: 45.000
Total: 45.000
''';
    final result = service.parseText(text);
    expect(result.amount, 45000);
  });

  test('falls back to the largest plausible number with no total label', () {
    const text = '''
Toko Serba Ada
Item A 12.000
Item B 8.500
''';
    final result = service.parseText(text);
    expect(result.amount, 12000);
  });

  test('returns null amount when nothing plausible is found', () {
    const text = 'Hanya teks tanpa angka apapun di sini';
    final result = service.parseText(text);
    expect(result.amount, isNull);
  });

  test('handles "Rp" currency prefix and ISO-style date', () {
    const text = '''
Kopi Kenangan
Tanggal: 2026-09-15
Cappuccino          Rp 22.000
Grand Total         Rp22.000
''';
    final result = service.parseText(text);
    expect(result.amount, 22000);
    expect(result.date, DateTime(2026, 9, 15));
  });

  test('ignores a lone "Total Item" count line without currency context', () {
    const text = '''
Apotek Sehat
Total Item: 2
Total Bayar: 15.500
''';
    final result = service.parseText(text);
    expect(result.amount, 15500);
  });

  test('rejects an implausible far-future OCR-misread date', () {
    const text = '''
Kedai Kopi
99/99/9999
Total 20.000
''';
    final result = service.parseText(text);
    expect(result.date, isNull);
    expect(result.amount, 20000);
  });
}
