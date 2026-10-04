import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Extension for convenient locale detection on BuildContext.
extension LocalizedStringExtension on BuildContext {
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

/// Helper methods for handling bilingual formatting, time representation, and RTL constraints.
class LocalizationUtils {
  LocalizationUtils._();

  /// Formats relative time (e.g., '12m ago' vs 'منذ 12 دقيقة').
  static String formatRelativeTime(DateTime dateTime, {AppLocalizations? l10n, bool isArabic = false}) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Just now';
    }

    if (l10n != null) {
      if (diff.inMinutes < 60) {
        return l10n.minutesAgo(diff.inMinutes);
      }
      if (diff.inHours < 24) {
        return l10n.hoursAgo(diff.inHours);
      }
      if (diff.inDays == 1) {
        return l10n.yesterday;
      }
      return l10n.daysAgo(diff.inDays);
    }

    // Direct fallback if l10n is not passed
    if (isArabic) {
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays == 1) return 'أمس';
      return 'منذ ${diff.inDays} أيام';
    } else {
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays}d ago';
    }
  }

  /// Formats currency with correct localized placement and symbols.
  /// Example: 'AED 120.00' (en) vs '120.00 درهم' (ar)
  static String formatCurrency(num amount, {bool isArabic = false, int decimalDigits = 2}) {
    final formattedNum = amount.toStringAsFixed(decimalDigits);
    if (isArabic) {
      return '$formattedNum درهم';
    }
    return 'AED $formattedNum';
  }

  /// Formats compact currency representation (e.g., 'AED 12.5k' vs '12.5 ألف درهم').
  static String formatCurrencyCompact(num amount, {bool isArabic = false}) {
    if (amount >= 1000000) {
      final val = (amount / 1000000).toStringAsFixed(1);
      return isArabic ? '$val مليون درهم' : 'AED ${val}M';
    } else if (amount >= 1000) {
      final val = (amount / 1000).toStringAsFixed(1);
      return isArabic ? '$val ألف درهم' : 'AED ${val}k';
    }
    return formatCurrency(amount, isArabic: isArabic, decimalDigits: 0);
  }
}
