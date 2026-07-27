import 'package:intl/intl.dart';

class DateFormatterHelper {
  DateFormatterHelper._();

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
  }

  static String formatDayMonth(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM').format(date);
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM yyyy').format(date);
  }

  static String formatTimeAgo(DateTime? date) {
    if (date == null) return '';

    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) {
      final d = difference.inDays;
      return '$d days ago';
    }

    return formatDate(date);
  }
}
