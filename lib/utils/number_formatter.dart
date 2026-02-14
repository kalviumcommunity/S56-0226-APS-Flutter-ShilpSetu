import 'package:intl/intl.dart';

/// Utility class for formatting numbers, currency, and dates
class NumberFormatter {
  /// Formats a number as Indian Rupee currency
  /// Example: 12450.50 -> ₹12,450.50
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  /// Formats a number with comma separators
  /// Example: 12450 -> 12,450
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return formatter.format(number);
  }

  /// Formats a DateTime as relative time
  /// Example: 2 days ago, 3 hours ago, just now
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }

  /// Formats a DateTime as a short date string
  /// Example: Jan 15, 2024
  static String formatShortDate(DateTime dateTime) {
    final formatter = DateFormat('MMM d, y');
    return formatter.format(dateTime);
  }
}
