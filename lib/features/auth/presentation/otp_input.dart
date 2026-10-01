import 'package:flutter/services.dart';

/// Accepts a code alone or one unambiguous six-digit code inside an SMS.
String? extractOtp(String text) {
  final matches = RegExp(
    r'(?<![0-9])[0-9]{6}(?![0-9])',
  ).allMatches(text).toList();
  return matches.length == 1 ? matches.single.group(0) : null;
}

class OtpInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final code = extractOtp(newValue.text);
    if (code != null) {
      return TextEditingValue(
        text: code,
        selection: const TextSelection.collapsed(offset: 6),
      );
    }
    return RegExp(r'^[0-9]{0,6}$').hasMatch(newValue.text)
        ? newValue
        : oldValue;
  }
}
