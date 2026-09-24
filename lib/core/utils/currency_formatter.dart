import 'package:intl/intl.dart';

/// Utility class for formatting UAE Dirham (AED) currency values.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat('#,##0.00', 'en_US');

  /// Formats [amount] as a standard AED string.
  /// Example: 1234.56 → 'AED 1,234.56'
  static String formatAED(double amount) {
    return 'AED ${_formatter.format(amount)}';
  }

  /// Formats [amount] in compact notation.
  /// Example: 1200.0 → 'AED 1.2K', 1500000.0 → 'AED 1.5M'
  static String formatAEDCompact(double amount) {
    if (amount.abs() >= 1000000) {
      final val = amount / 1000000;
      return 'AED ${_trimTrailingZeros(val.toStringAsFixed(1))}M';
    } else if (amount.abs() >= 1000) {
      final val = amount / 1000;
      return 'AED ${_trimTrailingZeros(val.toStringAsFixed(1))}K';
    }
    return formatAED(amount);
  }

  /// Converts AED amount to fils (smallest unit) for Stripe integration.
  /// Example: 12.50 AED → 1250 fils
  static int toFils(double aed) => (aed * 100).round();

  /// Converts fils back to AED.
  /// Example: 1250 fils → 12.50 AED
  static double fromFils(int fils) => fils / 100.0;

  static String _trimTrailingZeros(String value) {
    if (value.contains('.')) {
      value = value.replaceAll(RegExp(r'0+$'), '');
      if (value.endsWith('.')) value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
