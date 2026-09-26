import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _grouping = NumberFormat('#,###', 'id_ID');

/// "1500000" → "1.500.000". Negative values keep their minus sign.
String formatThousands(int value) => value < 0 ? '-${_grouping.format(-value)}' : _grouping.format(value);

/// Reads a grouped amount back ("1.500.000" → 1500000); 0 when empty.
int parseThousands(String text, {bool allowNegative = false}) => parseAmount(text, allowNegative: allowNegative);

/// Formats a stored amount of [decimals]-place smallest units for editing:
/// 125050 with 2 decimals → "1.250,5"; trailing zero decimals are dropped.
String formatAmount(int minor, {int decimals = 0}) {
  if (decimals == 0) return formatThousands(minor);
  final unit = math.pow(10, decimals).toInt();
  final neg = minor < 0;
  final v = minor.abs();
  final whole = formatThousands(v ~/ unit);
  final frac = (v % unit).toString().padLeft(decimals, '0').replaceFirst(RegExp(r'0+$'), '');
  return '${neg ? '-' : ''}$whole${frac.isEmpty ? '' : ',$frac'}';
}

/// Parses "1.250,5" into smallest units ([decimals] places): 125050 for 2.
int parseAmount(String text, {int decimals = 0, bool allowNegative = false}) {
  final t = text.trim();
  final neg = allowNegative && t.startsWith('-');
  final comma = decimals > 0 ? t.indexOf(',') : -1;
  final wholeDigits = (comma < 0 ? t : t.substring(0, comma)).replaceAll(RegExp(r'[^0-9]'), '');
  var fracDigits = comma < 0 ? '' : t.substring(comma + 1).replaceAll(RegExp(r'[^0-9]'), '');
  if (fracDigits.length > decimals) fracDigits = fracDigits.substring(0, decimals);
  final whole = int.tryParse(wholeDigits) ?? 0;
  final frac = int.tryParse(fracDigits.padRight(decimals, '0')) ?? 0;
  final v = whole * math.pow(10, decimals).toInt() + frac;
  return neg ? -v : v;
}

/// Groups digits with dots as the user types, keeping the caret after the
/// same digit it was after — so editing the middle of "1.250.000" doesn't
/// throw the cursor to the end. With [decimals] > 0 a comma starts the
/// decimal part (dollars and cents, grams of gold).
class ThousandsFormatter extends TextInputFormatter {
  ThousandsFormatter({this.allowNegative = false, this.decimals = 0, this.maxDigits = 15});

  final bool allowNegative;
  final int decimals;

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
    // Many keyboards only offer "." for decimals; a freshly typed "." is
    // taken as the decimal comma.
    if (decimals > 0 && text.length == oldValue.text.length + 1 && caret > 0 && text[caret - 1] == '.' && !text.contains(',')) {
      text = '${text.substring(0, caret - 1)},${text.substring(caret)}';
    }
    // Pasted "1250.75": a dot followed by fewer than three digits at the end
    // can't be a thousands separator, so it's the decimal point.
    if (decimals > 0 && text.length > oldValue.text.length + 1 && !text.contains(',')) {
      final m = RegExp('\\.(\\d{1,$decimals})\$').firstMatch(text);
      if (m != null && m.group(1)!.length < 3) text = '${text.substring(0, m.start)},${m.group(1)}';
    }

    final negative = allowNegative && text.trimLeft().startsWith('-');
    final commaAt = decimals > 0 ? text.indexOf(',') : -1;
    final wholeRaw = commaAt < 0 ? text : text.substring(0, commaAt);
    final frac = commaAt < 0 ? '' : text.substring(commaAt + 1).replaceAll(RegExp(r'[^0-9]'), '');
    if (frac.length > decimals) return oldValue;
    var digits = wholeRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;
    final rawWholeDigits = digits.length;
    // Leading zeros carry no meaning in an amount ("007" → "7").
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty && commaAt >= 0) digits = '0';

    if (digits.isEmpty) {
      final t = negative ? '-' : '';
      return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
    }

    final sign = negative ? '-' : '';
    final formatted = '$sign${_grouping.format(int.parse(digits))}${commaAt >= 0 ? ',$frac' : ''}';

    // Caret after the decimal comma stays at the same place in the
    // fraction; otherwise after the same digit of the whole part.
    if (commaAt >= 0 && caret > commaAt) {
      final intoFrac = text.substring(commaAt + 1, caret).replaceAll(RegExp(r'[^0-9]'), '').length;
      final offset = formatted.indexOf(',') + 1 + intoFrac;
      return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: offset.clamp(0, formatted.length)));
    }
    var digitsBefore = text.substring(0, caret).replaceAll(RegExp(r'[^0-9]'), '').length;
    // Account for stripped leading zeros.
    digitsBefore = (digitsBefore - (rawWholeDigits - digits.length)).clamp(0, digits.length);

    var offset = sign.length;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBefore) {
      if (RegExp(r'[0-9]').hasMatch(formatted[offset])) seen++;
      offset++;
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: offset));
  }
}
