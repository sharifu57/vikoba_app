import 'package:flutter/services.dart';

/// Parses the grouped amount shown in a money input into an API number.
double? parseMoneyInput(String? value) =>
    double.tryParse((value ?? '').replaceAll(',', '').trim());

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final raw = newValue.text.replaceAll(',', '');
    if (!RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(raw)) return oldValue;
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final parts = raw.split('.');
    final whole = parts.first.replaceAll(RegExp(r'^0+(?=\d)'), '');
    final grouped = whole.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final formatted = '$grouped${parts.length > 1 ? '.${parts[1]}' : ''}';
    final cursor = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsAfter = newValue.text
        .substring(cursor)
        .replaceAll(',', '')
        .length;
    var offset = formatted.length;
    var remaining = digitsAfter;
    while (offset > 0 && remaining > 0) {
      offset--;
      if (formatted[offset] != ',') remaining--;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
