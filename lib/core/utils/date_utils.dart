import 'package:intl/intl.dart';

class AppDateUtils {
  // Date formatters
  static final DateFormat _dayMonthYear = DateFormat('dd/MM/yyyy');
  static final DateFormat _dayMonthYearTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dayMonth = DateFormat('dd MMM');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _weekday = DateFormat('EEEE');
  static final DateFormat _weekdayShort = DateFormat('EEE');

  // Format date as dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dayMonthYear.format(date);
  }

  // Format date and time as dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime dateTime) {
    return _dayMonthYearTime.format(dateTime);
  }

  // Format time as HH:mm
  static String formatTime(DateTime dateTime) {
    return _time.format(dateTime);
  }

  // Format as dd MMM (e.g., 15 Jan)
  static String formatDayMonth(DateTime date) {
    return _dayMonth.format(date);
  }

  // Format as MMMM yyyy (e.g., January 2024)
  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  // Format weekday (e.g., Monday)
  static String formatWeekday(DateTime date) {
    return _weekday.format(date);
  }

  // Format short weekday (e.g., Mon)
  static String formatWeekdayShort(DateTime date) {
    return _weekdayShort.format(date);
  }

  // Get relative date string (Today, Tomorrow, Yesterday, or date)
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final difference = targetDate.difference(today).inDays;
    
    switch (difference) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      case -1:
        return 'Yesterday';
      default:
        if (difference > 1 && difference <= 7) {
          return formatWeekday(date);
        } else if (difference < -1 && difference >= -7) {
          return 'Last ${formatWeekday(date)}';
        } else {
          return formatDayMonth(date);
        }
    }
  }

  // Get time until date string
  static String getTimeUntilString(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'}';
    } else if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'}';
    } else if (minutes > 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    } else {
      return 'Now';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysUntilSunday)));
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  // Get days in month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  // Get list of dates in a month
  static List<DateTime> getDatesInMonth(DateTime date) {
    final startDate = startOfMonth(date);
    final daysInMonth = getDaysInMonth(date);
    
    return List.generate(
      daysInMonth,
      (index) => startDate.add(Duration(days: index)),
    );
  }
}