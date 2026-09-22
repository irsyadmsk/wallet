import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    String formatted = '';
    if (cleaned.isNotEmpty) {
      final number = int.parse(cleaned);
      formatted = NumberFormat("#,###", "id_ID").format(number);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
