import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountTextInputFormatter extends TextInputFormatter {
  AmountTextInputFormatter({this.maxDecimals = 2, String? locale})
      : _numberFormat = NumberFormat.decimalPattern(locale);

  final int maxDecimals;
  final NumberFormat _numberFormat;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;

    if (raw.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final localeDecimal = _numberFormat.symbols.DECIMAL_SEP;

    // Keep only digits and separators (dot/comma)
    String onlyAllowed = raw.replaceAll(RegExp(r'[^0-9\.,]'), '');

    // Find the last occurrence of a separator to treat as decimal
    final lastDot = onlyAllowed.lastIndexOf('.');
    final lastComma = onlyAllowed.lastIndexOf(',');
    int lastSep = lastDot > lastComma ? lastDot : lastComma;

    String integerDigits;
    String? fractionalDigits;

    if (lastSep == -1) {
      // No decimal separator typed yet
      integerDigits = onlyAllowed.replaceAll(RegExp(r'[\.,]'), '');
      fractionalDigits = null;
    } else {
      final intPartRaw = onlyAllowed.substring(0, lastSep);
      final fracPartRaw = onlyAllowed.substring(lastSep + 1);
      integerDigits = intPartRaw.replaceAll(RegExp(r'[\.,]'), '');
      fractionalDigits = fracPartRaw.replaceAll(RegExp(r'[^0-9]'), '');
      if (fractionalDigits.length > maxDecimals) {
        fractionalDigits = fractionalDigits.substring(0, maxDecimals);
      }
    }

    // Format integer part with grouping
    final intVal = int.tryParse(integerDigits) ?? 0;
    String formattedInt = _numberFormat.format(intVal);
    if (integerDigits.isEmpty) {
      formattedInt = '';
    }

    final newText = fractionalDigits == null
        ? formattedInt
        : fractionalDigits.isEmpty
            ? formattedInt + localeDecimal
            : formattedInt + localeDecimal + fractionalDigits;

    // Maintain cursor position relative to end
    final selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
    final newSelectionIndex = newText.length - selectionIndexFromTheRight;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex.clamp(0, newText.length)),
    );
  }
}


