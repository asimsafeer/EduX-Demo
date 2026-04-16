/// EduX School Management System
/// Date and time utility extensions
library;

import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Format date for display (e.g., "15 Jan 2026")
  String toDisplayDate() {
    return DateFormat(AppConstants.displayDateFormat).format(this);
  }

  /// Format date for database storage (e.g., "2026-01-15")
  String toDbDate() {
    return DateFormat(AppConstants.dbDateFormat).format(this);
  }

  /// Format time for display (e.g., "08:30 AM")
  String toDisplayTime() {
    return DateFormat(AppConstants.displayTimeFormat).format(this);
  }

  /// Format time for database storage (e.g., "08:30")
  String toDbTime() {
    return DateFormat(AppConstants.dbTimeFormat).format(this);
  }

  /// Format date and time for display
  String toDisplayDateTime() {
    return DateFormat(AppConstants.displayDateTimeFormat).format(this);
  }

  /// Get start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get end of day (23:59:59.999)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  DateTime get startOfWeek {
    final int daysFromMonday = weekday - 1;
    return DateTime(year, month, day - daysFromMonday);
  }

  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    final int daysUntilSunday = 7 - weekday;
    return DateTime(year, month, day + daysUntilSunday, 23, 59, 59, 999);
  }

  /// Get start of month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Get end of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Get start of year
  DateTime get startOfYear {
    return DateTime(year, 1, 1);
  }

  /// Get end of year
  DateTime get endOfYear {
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if date is in current week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfCurrentWeek = now.startOfWeek;
    final endOfCurrentWeek = now.endOfWeek;
    return isAfter(startOfCurrentWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfCurrentWeek.add(const Duration(days: 1)));
  }

  /// Check if date is in current month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Check if date is in current year
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  /// Get age from date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Get month name
  String get monthName {
    return DateFormat('MMMM').format(this);
  }

  /// Get month name abbreviated
  String get monthNameShort {
    return DateFormat('MMM').format(this);
  }

  /// Get day name
  String get dayName {
    return DateFormat('EEEE').format(this);
  }

  /// Get day name abbreviated
  String get dayNameShort {
    return DateFormat('EEE').format(this);
  }

  /// Get relative time string (e.g., "2 hours ago", "Yesterday")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      // Future date
      final futureDiff = difference.abs();
      if (futureDiff.inMinutes < 60) {
        return 'in ${futureDiff.inMinutes} minutes';
      } else if (futureDiff.inHours < 24) {
        return 'in ${futureDiff.inHours} hours';
      } else if (isTomorrow) {
        return 'Tomorrow';
      } else if (futureDiff.inDays < 7) {
        return 'in ${futureDiff.inDays} days';
      } else {
        return toDisplayDate();
      }
    } else {
      // Past date
      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        if (isToday) {
          final hours = difference.inHours;
          return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
        } else {
          return 'Yesterday';
        }
      } else if (isYesterday) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      }
    }
  }

  /// Get days in current month
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }

  /// Check if year is leap year
  bool get isLeapYear {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Copy with optional parameters
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }

  /// Get academic year string (e.g., "2025-2026")
  String get academicYear {
    if (month >= 4) {
      // April onwards is new academic year
      return '$year-${year + 1}';
    } else {
      return '${year - 1}-$year';
    }
  }

  /// Get month-year string (e.g., "2026-01")
  String get monthYear {
    return '$year-${month.toString().padLeft(2, '0')}';
  }
}

/// Extension methods for nullable DateTime
extension NullableDateTimeExtensions on DateTime? {
  /// Format date for display with fallback
  String toDisplayDateOrEmpty([String fallback = '-']) {
    return this?.toDisplayDate() ?? fallback;
  }

  /// Format date for database with fallback
  String toDbDateOrEmpty([String fallback = '']) {
    return this?.toDbDate() ?? fallback;
  }
}
