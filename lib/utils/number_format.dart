import 'package:intl/intl.dart';

/// Formats numbers with grouping separators and two decimal places.
/// Example: `formatNumberWithCommas(1234567.89)` -> `1,234,567.89`
String formatNumberWithCommas(num? value, {String? locale}) {
  final fmt = NumberFormat('#,##0.00', locale ?? 'en_US');
  if (value == null) return fmt.format(0);
  return fmt.format(value);
}
