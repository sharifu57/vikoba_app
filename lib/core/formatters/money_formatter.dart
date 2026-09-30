import 'package:intl/intl.dart';

/// Formats API amounts consistently, independent of the device locale.
String formatMoney(Object? value, {String? currency, int decimalDigits = 2}) {
  final amount = value is num
      ? value
      : num.tryParse(value?.toString() ?? '') ?? 0;
  final formatted = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits: decimalDigits,
  ).format(amount);
  return currency == null || currency.isEmpty
      ? formatted
      : '$currency $formatted';
}
