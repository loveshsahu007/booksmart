import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyTextInputFormatter extends TextInputFormatter {
  // final NumberFormat _formatter = NumberFormat.currency(
  //   locale: 'en_US',
  //   symbol: '\$',
  //   decimalDigits: 2,
  // );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Allow empty
    if (text.isEmpty) return newValue;

    // Keep digits + decimal point only
    text = text.replaceAll(RegExp(r'[^\d.]'), '');

    // Prevent multiple decimals
    if ('.'.allMatches(text).length > 1) {
      return oldValue;
    }

    // Split integer & decimal
    final parts = text.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Limit decimals to 2 digits
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    // Format integer part with commas
    String formattedInteger = NumberFormat(
      '#,###',
      'en_US',
    ).format(int.parse(integerPart.isEmpty ? '0' : integerPart));

    // Build final string
    String result = '\$$formattedInteger';

    if (parts.length > 1) {
      result += '.$decimalPart';
    }

    // Maintain cursor position (basic but better)
    int cursorPosition = result.length;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
