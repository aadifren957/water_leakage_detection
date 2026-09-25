import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, h:mm a');
  static final DateFormat _shortDateTimeFormat = DateFormat('MMM dd, h:mm a');

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatShortDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _shortDateTimeFormat.format(dateTime);
  }

  static String timeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'Just now';
    }
    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hr${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return _dateFormat.format(dateTime);
    }
  }

  static String formatDuration(Duration duration) {
    if (duration.isNegative) return '0 min';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}'.trim();
    }
    return '$minutes min${minutes == 1 ? '' : 's'}';
  }

  static String calculateDurationBetween(DateTime start, DateTime? end) {
    if (end == null) return 'Ongoing';
    return formatDuration(end.difference(start));
  }
}
