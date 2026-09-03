import 'package:flutter/material.dart';
import 'package:heliumapp/utils/time_zone_aliases.dart';
import 'package:heliumapp/utils/time_zone_constants.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart' as tz;

final _log = Logger('utils');

class HeliumTime {
  static TimeOfDay? parse(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String format(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('h:mm a').format(dateTime);
  }

  static String formatTimeRange(TimeOfDay startTime, TimeOfDay endTime) {
    return '${format(startTime)} - ${format(endTime)}';
  }

  static String formatForApi(TimeOfDay time) {
    final now = DateTime.now();
    return DateFormat(
      'HH:mm:00',
    ).format(DateTime(now.year, now.month, now.day, time.hour, time.minute));
  }
}

class DateRangeEnforcer {
  static DateTime adjustEndDate(DateTime start, DateTime end) {
    return end.isBefore(start) ? start : end;
  }

  static DateTime adjustStartDate(DateTime start, DateTime end) {
    return start.isAfter(end) ? end : start;
  }

  static TimeOfDay adjustEndTime(TimeOfDay start, TimeOfDay end) {
    return _minuteOfDay(start) > _minuteOfDay(end) ? start : end;
  }

  static TimeOfDay adjustStartTime(TimeOfDay start, TimeOfDay end) {
    return _minuteOfDay(start) > _minuteOfDay(end) ? end : start;
  }

  static ({DateTime date, TimeOfDay? time}) adjustEnd({
    required DateTime startDate,
    required TimeOfDay? startTime,
    required DateTime endDate,
    required TimeOfDay? endTime,
  }) {
    final effectiveStart = _combine(startDate, startTime);
    final effectiveEnd = _combine(endDate, endTime);
    if (effectiveEnd.isBefore(effectiveStart)) {
      return (date: startDate, time: startTime);
    }
    return (date: endDate, time: endTime);
  }

  static ({DateTime date, TimeOfDay? time}) adjustStart({
    required DateTime startDate,
    required TimeOfDay? startTime,
    required DateTime endDate,
    required TimeOfDay? endTime,
  }) {
    final effectiveStart = _combine(startDate, startTime);
    final effectiveEnd = _combine(endDate, endTime);
    if (effectiveStart.isAfter(effectiveEnd)) {
      return (date: endDate, time: endTime);
    }
    return (date: startDate, time: startTime);
  }

  static int _minuteOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

  static DateTime _combine(DateTime date, TimeOfDay? time) {
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class HeliumDateTime {
  /// Returns a DateTime with only the date part (time set to midnight)
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Converts DateTime.weekday (1=Mon, 7=Sun) to 0-based index (0=Sun, 6=Sat)
  static int getDayIndex(DateTime date) {
    return date.weekday == 7 ? 0 : date.weekday;
  }

  static DateTime parse(String isoString, tz.Location timeZone) {
    return tz.TZDateTime.from(DateTime.parse(isoString), timeZone);
  }

  /// Resolves a device-reported identifier into one the API accepts, or `'UTC'`.
  ///
  /// Neither allow-list carries IANA link names, and device APIs report whatever
  /// the device is set to without canonicalizing.
  static String resolveTimeZone(String reported) {
    if (TimeZoneConstants.all.contains(reported)) {
      return reported;
    }

    final canonical = TimeZoneAliases.all[reported];
    if (canonical != null) {
      return canonical;
    }

    // The OAuth setup path shows no timezone, so a silent fallback sticks.
    _log.warning('Unmappable device timezone reported, defaulting to UTC');
    return 'UTC';
  }

  static DateTime toLocal(DateTime utc, tz.Location timeZone) {
    return tz.TZDateTime.from(utc, timeZone);
  }

  /// Midnight on the date [instant] falls on in [timeZone]. The UTC date would
  /// be a day early for any positive offset.
  static tz.TZDateTime midnightIn(DateTime instant, tz.Location timeZone) {
    final local = tz.TZDateTime.from(instant, timeZone);
    return tz.TZDateTime(timeZone, local.year, local.month, local.day);
  }

  /// Anchors [value] to [timeZone], reading a naive value as wall clock already
  /// in that zone and a UTC one as an instant. SfCalendar returns both forms.
  static tz.TZDateTime wallClockIn(DateTime value, tz.Location timeZone) {
    final local = value.isUtc ? tz.TZDateTime.from(value, timeZone) : value;
    return tz.TZDateTime(
      timeZone,
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
  }

  static String formatDayNameShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  static String formatMonthAndYear(
    DateTime date, {
    bool abbreviateMonth = true,
  }) {
    final format = abbreviateMonth ? 'MMM yyyy' : 'MMMM yyyy';
    return DateFormat(format).format(date);
  }

  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }

  static String formatDate(
    DateTime date, {
    bool abbreviateMonth = true,
    bool showYear = true,
  }) {
    final String format;
    if (showYear) {
      format = abbreviateMonth ? 'MMM d, yyyy' : 'MMMM d, yyyy';
    } else {
      format = abbreviateMonth ? 'MMM d' : 'MMMM d';
    }
    return DateFormat(format).format(date);
  }

  static String formatDateAndTime(DateTime date) {
    return DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(date).replaceAll(':00', '');
  }

  static String formatDateForTodos(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  static String formatDateAndTimeForTodos(DateTime date) {
    return DateFormat('EEE, MMM d • h:mm a').format(date).replaceAll(':00', '');
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date).replaceAll(':00', '');
  }

  static String formatDateTimeRange(
    DateTime startDate,
    DateTime endDate,
    bool showEndTime,
    bool isAllDay,
  ) {
    final String dateDisplay = HeliumDateTime.formatDate(startDate);

    if (!isAllDay) {
      return '$dateDisplay • ${HeliumDateTime.formatTimeRange(startDate, endDate, showEndTime)}';
    } else {
      return dateDisplay;
    }
  }

  static String formatTimeRange(
    DateTime startDate,
    DateTime endDate,
    bool showEndTime,
  ) {
    final formattedTime = HeliumDateTime.formatTime(startDate);
    if (showEndTime && startDate != endDate) {
      final formattedEndTime = HeliumDateTime.formatTime(endDate);
      return '$formattedTime - $formattedEndTime';
    } else {
      return formattedTime;
    }
  }

  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateAndTimeForApi(
    DateTime date,
    TimeOfDay? time,
    tz.Location timeZone,
  ) {
    final dateTime = tz.TZDateTime(
      timeZone,
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    return dateTime.toIso8601String();
  }

  static int getDaysBetween(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return 0;
    }

    if (now.isAfter(endDate)) {
      return 100;
    }

    final totalDays = endDate.difference(startDate).inDays;
    if (totalDays <= 0) {
      return 0;
    }

    return now.difference(startDate).inDays;
  }

  static int getPercentDiffBetween(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();

    // If before start date, return 0%
    if (now.isBefore(startDate)) {
      return 0;
    }

    // If after end date, return 100%
    if (now.isAfter(endDate)) {
      return 100;
    }

    // Calculate percentage
    final totalDays = endDate.difference(startDate).inDays;
    if (totalDays <= 0) {
      return 0;
    }

    final daysElapsed = now.difference(startDate).inDays;
    final percentage = (daysElapsed / totalDays * 100).round();

    // Clamp between 0 and 100
    if (percentage < 0) return 0;
    if (percentage > 100) return 100;
    return percentage;
  }
}
