import 'package:intl/intl.dart';

/// Central formatting helpers for dates, times and status text.

class AppFormatters {
  AppFormatters._();

  static final DateFormat _dayFormat = DateFormat('EEE d MMM yyyy');
  static final DateFormat _shortDayFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dayNumberFormat = DateFormat('d');

  static String fullDay(DateTime date) => _dayFormat.format(date);

  static String shortDay(DateTime date) => _shortDayFormat.format(date);

  static String dayNumber(DateTime date) => _dayNumberFormat.format(date);

  static String time(DateTime? dateTime) {
    if (dateTime == null) {
      return '—';
    }
    return _timeFormat.format(dateTime);
  }

  static String workedMinutes(int minutes) {
    if (minutes <= 0) {
      return '—';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  static String prettyStatus(String status) {
    switch (status) {
      case 'clocked_in':
        return 'Clocked in';
      case 'clocked_out':
        return 'Clocked out';
      default:
        return 'Not started';
    }
  }
}
