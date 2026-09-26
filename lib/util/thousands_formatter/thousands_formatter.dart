import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _grouping = NumberFormat('#,###', 'id_ID');

/// "1500000" → "1.500.000". Negative values keep their minus sign.
String formatThousands(int value) => value < 0 ? '-${_grouping.format(-value)}' : _grouping.format(value);

/// Reads a grouped amount back ("1.500.000" → 1500000); 0 when empty.
int parseThousands(String text, {bool allowNegative = false}) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  final v = int.tryParse(digits) ?? 0;
  return allowNegative && text.trimLeft().startsWith('-') ? -v : v;
}

/// Groups digits with dots as the user types, keeping the caret after the
/// same digit it was after — so editing the middle of "1.250.000" doesn't
/// throw the cursor to the end (the old behaviour).
class ThousandsFormatter extends TextInputFormatter {
  ThousandsFormatter({this.allowNegative = false, this.maxDigits = 15});

  final bool allowNegative;

  /// Stops input well before `int` overflow.
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var caret = newValue.selection.end.clamp(0, text.length);
    // Backspace over a separator: remove the digit before it instead of
    // letting the formatter put the dot straight back.
    final removedSeparator = oldValue.text.length == text.length + 1 &&
        caret < oldValue.text.length &&
        oldValue.text[caret] == '.' &&
        text == oldValue.text.substring(0, caret) + oldValue.text.substring(caret + 1);
    if (removedSeparator) {
      final before = text.substring(0, caret);
      final i = before.lastIndexOf(RegExp(r'[0-9]'));
      if (i >= 0) {
        text = text.substring(0, i) + text.substring(i + 1);
        caret = i;
      }
    }
    final negative = allowNegative && text.trimLeft().startsWith('-');
    var digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;
    // Leading zeros carry no meaning in an amount ("007" → "7").
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    if (digits.isEmpty) {
      final t = negative ? '-' : '';
      return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
    }

    final formatted = '${negative ? '-' : ''}${_grouping.format(int.parse(digits))}';

    // How many digits sat before the caret in the raw edit?
    var digitsBefore = text.substring(0, caret).replaceAll(RegExp(r'[^0-9]'), '').length;
    // Account for stripped leading zeros.
    final rawDigits = text.replaceAll(RegExp(r'[^0-9]'), '');
    digitsBefore = (digitsBefore - (rawDigits.length - digits.length)).clamp(0, digits.length);

    var offset = negative ? 1 : 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBefore) {
      if (RegExp(r'[0-9]').hasMatch(formatted[offset])) seen++;
      offset++;
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: offset));
  }
}
