import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/time_zone_aliases.dart';
import 'package:heliumapp/utils/time_zone_constants.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart' as tz;

final _log = Logger('utils');

class HeliumTime {
  static String get timePattern =>
      LocaleNotifier().uses24HourClock ? 'HH:mm' : 'h:mm a';

  static String get timeRulerPattern =>
      LocaleNotifier().uses24HourClock ? 'HH:mm' : 'h a';

  static String shortenOnTheHour(String formatted) {
    return LocaleNotifier().uses24HourClock ? formatted : formatted.replaceAll(':00', '');
  }

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
    return DateFormat(timePattern).format(dateTime);
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

  /// The end that keeps an item's length when its start moves from
  /// [previousStartDate] at [previousStartTime] to [startDate] at [startTime]:
  /// [endDate] at [endTime] shifted by the same wall-clock amount. Times are
  /// null for an all-day item, which keeps its number of days.
  static ({DateTime date, TimeOfDay? time}) followStart({
    required DateTime previousStartDate,
    required TimeOfDay? previousStartTime,
    required DateTime startDate,
    required TimeOfDay? startTime,
    required DateTime endDate,
    required TimeOfDay? endTime,
  }) {
    final length = _wallClock(endDate, endTime).difference(_wallClock(previousStartDate, previousStartTime));
    final end = _wallClock(startDate, startTime).add(length);
    return (
      date: DateTime(end.year, end.month, end.day),
      time: endTime == null ? null : TimeOfDay(hour: end.hour, minute: end.minute),
    );
  }

  static int _minuteOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

  static DateTime _wallClock(DateTime date, TimeOfDay? time) =>
      DateTime.utc(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);

  static DateTime _combine(DateTime date, TimeOfDay? time) {
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class HeliumDateTime {
  static final _utcUntil = RegExp(r'UNTIL=(\d{8}T\d{6}Z)');
  static final _recurrenceDateTime = DateFormat("yyyyMMdd'T'HHmmss");
  static const dayNameShortPattern = 'EEE';

  /// The earliest date a date picker offers when nothing narrower bounds it.
  static DateTime earliestPickableDate() =>
      DateTime.now().subtract(const Duration(days: 365 * 10));

  /// The latest date a date picker offers when nothing narrower bounds it.
  static DateTime latestPickableDate() =>
      DateTime.now().add(const Duration(days: 365 * 10));

  /// Returns a DateTime with only the date part (time set to midnight)
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// The later of two ISO 8601 timestamps, or whichever one parses.
  static String? laterTimestamp(String? first, String? second) {
    final firstAt = first == null ? null : DateTime.tryParse(first);
    final secondAt = second == null ? null : DateTime.tryParse(second);
    if (firstAt == null) return second;
    if (secondAt == null) return first;
    return secondAt.isAfter(firstAt) ? second : first;
  }

  /// A calendar display date that scrolls a day or week view to two hours
  /// before [time], so [time] shows with context above it. Never earlier than
  /// the start of [time]'s day, so the visible day, week, and month stay put.
  static DateTime visibleAnchorFor(DateTime time) {
    final anchor = DateTime(time.year, time.month, time.day, time.hour - 2);
    final startOfDay = dateOnly(time);
    return anchor.isBefore(startOfDay) ? startOfDay : anchor;
  }

  /// Steps [date] by whole calendar days, keeping its wall clock time and zone,
  /// unlike `add(Duration(days:))`, which shifts the wall clock across DST.
  static DateTime addDays(DateTime date, int days) {
    if (date is tz.TZDateTime) {
      return tz.TZDateTime(date.location, date.year, date.month, date.day + days, date.hour,
          date.minute, date.second, date.millisecond, date.microsecond);
    }
    if (date.isUtc) {
      return DateTime.utc(date.year, date.month, date.day + days, date.hour, date.minute,
          date.second, date.millisecond, date.microsecond);
    }
    return DateTime(date.year, date.month, date.day + days, date.hour, date.minute, date.second,
        date.millisecond, date.microsecond);
  }

  /// The exclusive end of an all-day item moved to [newStart], keeping the
  /// calendar-day length of [originalStart]..[originalEnd] across DST.
  static DateTime allDayEndAfterMove(DateTime newStart, DateTime originalStart, DateTime originalEnd) =>
      addDays(newStart, calendarDaysBetween(originalStart, originalEnd));

  /// An all-day occurrence keeps the series' span of dates in [timeZone], not
  /// its duration, so it stays whole days across DST.
  static (DateTime, DateTime) occurrenceBounds(
    DateTime seriesStart,
    DateTime seriesEnd,
    DateTime occurrenceStart, {
    required bool allDay,
    required tz.Location timeZone,
  }) {
    if (!allDay) {
      return (occurrenceStart, occurrenceStart.add(seriesEnd.difference(seriesStart)));
    }
    final spanDays = calendarDaysBetween(toLocal(seriesStart, timeZone), toLocal(seriesEnd, timeZone));
    final local = toLocal(occurrenceStart, timeZone);
    return (occurrenceStart, tz.TZDateTime(timeZone, local.year, local.month, local.day + spanDays));
  }

  /// The last date an item occupies, given its [end]: the day before an
  /// all-day item's exclusive end, or the day a timed item's end falls on.
  static DateTime lastDayOf(DateTime end, {required bool allDay}) =>
      dateOnly(allDay ? addDays(end, -1) : end);

  /// Whether an item from [start] to [end] falls within [rangeStart] up to
  /// [rangeEnd]. An item with no length counts when its instant is in range.
  static bool occursWithin(DateTime start, DateTime end, DateTime rangeStart, DateTime rangeEnd) =>
      start.isBefore(rangeEnd) && (end.isAfter(rangeStart) || !start.isBefore(rangeStart));

  /// [rule] with a UTC `UNTIL` rewritten as wall clock in [timeZone], the zone
  /// its occurrences are expanded in.
  static String recurrenceRuleWithLocalUntil(String rule, tz.Location timeZone) {
    final match = _utcUntil.firstMatch(rule);
    if (match == null) {
      return rule;
    }
    final until = tz.TZDateTime.from(DateTime.parse(match.group(1)!), timeZone);
    return rule.replaceRange(match.start, match.end, 'UNTIL=${_recurrenceDateTime.format(until)}');
  }

  /// The number of calendar days from [start]'s date to [end]'s date, read
  /// from each value's own components.
  static int calendarDaysBetween(DateTime start, DateTime end) {
    return DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
  }

  /// Converts DateTime.weekday (1=Mon, 7=Sun) to 0-based index (0=Sun, 6=Sat)
  static int getDayIndex(DateTime date) {
    return date.weekday == 7 ? 0 : date.weekday;
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

  /// The week of a term that [now] falls in, by its date in [timeZone]: 0 for
  /// the first seven days from the date-only [termStart], negative before it.
  static int weekOfTerm(DateTime termStart, DateTime now, tz.Location timeZone) {
    final today = midnightIn(now, timeZone);
    final days = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(termStart.year, termStart.month, termStart.day))
        .inDays;
    return (days / 7).floor();
  }

  /// Midnight on the date [instant] falls on in [timeZone]. The UTC date would
  /// be a day early for any positive offset.
  static tz.TZDateTime midnightIn(DateTime instant, tz.Location timeZone) {
    final local = tz.TZDateTime.from(instant, timeZone);
    return tz.TZDateTime(timeZone, local.year, local.month, local.day);
  }

  /// Resolves an all-day series' exception date to its midnight in [timeZone].
  /// A date-only exception can arrive as UTC midnight (`2026-10-05T00:00:00Z`),
  /// which names a calendar date rather than an instant; any other value is a
  /// real instant and resolves by wall clock.
  static tz.TZDateTime allDayExceptionIn(DateTime exception, tz.Location timeZone) {
    final isDateOnly = exception.isUtc &&
        exception.hour == 0 &&
        exception.minute == 0 &&
        exception.second == 0 &&
        exception.millisecond == 0 &&
        exception.microsecond == 0;
    if (isDateOnly) {
      return tz.TZDateTime(timeZone, exception.year, exception.month, exception.day);
    }
    return wallClockIn(exception, timeZone);
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

  /// Whether the device locale writes the month before the day; year-first
  /// locales count as day-first, since the app renders word-month dates and
  /// has no year-first form. Falls back to month-first for an unknown locale.
  static Future<int> detectDateFormat(Locale locale) async {
    await initializeDateFormatting();
    final String pattern;
    try {
      pattern = DateFormat.yMd(locale.toString()).pattern ?? '';
    } on ArgumentError {
      return RegionalFormatConstants.dateFormatMonthDayYear;
    }
    final monthFirst = !pattern.startsWith('y') && pattern.indexOf('M') < pattern.indexOf('d');
    return monthFirst
        ? RegionalFormatConstants.dateFormatMonthDayYear
        : RegionalFormatConstants.dateFormatDayMonthYear;
  }

  /// The device's time zone, mapped to one Helium supports; UTC when the device
  /// reports none Helium can map.
  static Future<String> detectTimeZone() async =>
      resolveTimeZone((await FlutterTimezone.getLocalTimezone()).identifier);

  /// The weekday the device locale starts its week on, as the API's
  /// Sunday-based index; falls back to Sunday for an unknown locale.
  static Future<int> detectWeekStartsOn(Locale locale) async {
    await initializeDateFormatting();
    try {
      final mondayBased = DateFormat.yMd(locale.toString()).dateSymbols.FIRSTDAYOFWEEK;
      return (mondayBased + 1) % DateTime.daysPerWeek;
    } on ArgumentError {
      return RegionalFormatConstants.weekStartsOnSunday;
    }
  }

  /// The clock the device uses: the OS 24-hour toggle when the platform
  /// reports one, otherwise the device locale's convention.
  static Future<int> detectTimeFormat(Locale locale, {bool? alwaysUse24HourFormat}) async {
    if (alwaysUse24HourFormat != null) {
      return alwaysUse24HourFormat
          ? RegionalFormatConstants.timeFormatTwentyFourHour
          : RegionalFormatConstants.timeFormatTwelveHour;
    }
    await initializeDateFormatting();
    try {
      final pattern = DateFormat.jm(locale.toString()).pattern ?? '';
      return pattern.contains('H')
          ? RegionalFormatConstants.timeFormatTwentyFourHour
          : RegionalFormatConstants.timeFormatTwelveHour;
    } on ArgumentError {
      return RegionalFormatConstants.timeFormatTwelveHour;
    }
  }

  static String dateFormatExample(int dateFormat, DateTime date) {
    return dateFormat == RegionalFormatConstants.dateFormatDayMonthYear
        ? DateFormat('d MMM yyyy').format(date)
        : DateFormat('MMM d, yyyy').format(date);
  }

  static String timeFormatExample(int timeFormat, DateTime date) {
    return timeFormat == RegionalFormatConstants.timeFormatTwentyFourHour
        ? DateFormat('HH:mm').format(date)
        : DateFormat('h:mm a').format(date);
  }

  static List<String> get weekdayNames => DateFormat().dateSymbols.STANDALONEWEEKDAYS;

  static List<String> get weekdayNamesShort => DateFormat().dateSymbols.STANDALONESHORTWEEKDAYS;

  static String formatDayNameShort(DateTime date) {
    return DateFormat(dayNameShortPattern).format(date);
  }

  static String formatDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static DateFormat get dateFormatForChartAxis => DateFormat(_ordered('MMM d', 'd MMM'));

  static String formatMonthAndYear(
    DateTime date, {
    bool abbreviateMonth = true,
  }) {
    final format = abbreviateMonth ? 'MMM yyyy' : 'MMMM yyyy';
    return DateFormat(format).format(date);
  }

  static String formatDateWithDay(DateTime date) {
    return DateFormat(_ordered('EEEE, MMMM d', 'EEEE, d MMMM')).format(date);
  }

  static String formatDate(
    DateTime date, {
    bool abbreviateMonth = true,
    bool showYear = true,
  }) {
    final month = abbreviateMonth ? 'MMM' : 'MMMM';
    final format = showYear
        ? _ordered('$month d, yyyy', 'd $month yyyy')
        : _ordered('$month d', 'd $month');
    return DateFormat(format).format(date);
  }

  static String formatDateForTodos(DateTime date, {bool showWeekday = true}) {
    return DateFormat(_todosDatePattern(showWeekday)).format(date);
  }

  static String formatDateAndTimeForTodos(
    DateTime date, {
    bool showWeekday = true,
  }) {
    final pattern = '${_todosDatePattern(showWeekday)} • ${HeliumTime.timePattern}';
    return HeliumTime.shortenOnTheHour(DateFormat(pattern).format(date));
  }

  static String formatTime(DateTime date) {
    return HeliumTime.shortenOnTheHour(DateFormat(HeliumTime.timePattern).format(date));
  }

  static String formatDateTimeRange(
    DateTime startDate,
    DateTime endDate,
    bool showEndTime,
    bool isAllDay,
  ) {
    if (isAllDay) {
      return showEndTime
          ? formatDateRange(startDate, lastDayOf(endDate, allDay: true))
          : formatDate(startDate);
    }

    final String dateDisplay = formatDate(startDate);
    if (showEndTime && endDate.isAfter(startDate) && dateOnly(endDate) != dateOnly(startDate)) {
      return LocaleNotifier().localizations.dateTimeMultiDayRange(dateDisplay, formatTime(startDate), formatDate(endDate), formatTime(endDate));
    }
    return '$dateDisplay • ${formatTimeRange(startDate, endDate, showEndTime)}';
  }

  /// The first day of [day]'s week, as a date, when weeks start on
  /// [weekStartsOn] (0 for Sunday through 6 for Saturday).
  static DateTime startOfWeek(DateTime day, int weekStartsOn) {
    return DateTime(
      day.year,
      day.month,
      day.day - (day.weekday % 7 - weekStartsOn) % 7,
    );
  }

  /// [startDate] to [endDate] as dates, or just the date when both fall on
  /// the same day.
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (!dateOnly(endDate).isAfter(dateOnly(startDate))) {
      return formatDate(startDate);
    }
    return LocaleNotifier().localizations.dateTimeDateRange(formatDate(startDate), formatDate(endDate));
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

  static tz.TZDateTime dateAndTimeIn(DateTime date, TimeOfDay? time, tz.Location timeZone) =>
      tz.TZDateTime(timeZone, date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);

  static String formatDateAndTimeForApi(DateTime date, TimeOfDay? time, tz.Location timeZone) =>
      dateAndTimeIn(date, time, timeZone).toIso8601String();

  /// The instants spanning whole days in [timeZone]: midnight of [firstDay]
  /// through the exclusive midnight after [lastDay], each read by its date.
  static (tz.TZDateTime, tz.TZDateTime) dayRangeIn(
    DateTime firstDay,
    DateTime lastDay,
    tz.Location timeZone,
  ) {
    return (
      tz.TZDateTime(timeZone, firstDay.year, firstDay.month, firstDay.day),
      tz.TZDateTime(timeZone, lastDay.year, lastDay.month, lastDay.day + 1),
    );
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

  /// Returns the ISO-8601 week number for [date], matching what SfCalendar
  /// paints in its own week number column.
  static int isoWeekNumber(DateTime date) {
    // Counted in UTC so a DST boundary cannot shorten the span and drop a day.
    final yearEndDate = DateTime.utc(date.year - 1, 12, 31);
    final dayOfYear = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(yearEndDate).inDays;
    final weekNumber = (dayOfYear - date.weekday + 10) ~/ 7;

    if (weekNumber < 1) {
      return _weeksInYear(date.year - 1);
    }
    if (weekNumber > _weeksInYear(date.year)) {
      return 1;
    }
    return weekNumber;
  }

  /// A readable wait, rounded up to the minute under an hour and to the nearest
  /// hour beyond: "a minute", "59 minutes", "about an hour", "about 3 hours".
  @visibleForTesting
  static String describeWait(Duration wait) {
    final l10n = LocaleNotifier().localizations;
    final minutes = (wait.inSeconds / 60).ceil();
    if (minutes < 60) return l10n.dateTimeMinutes(minutes < 1 ? 1 : minutes);
    return l10n.dateTimeAboutHours((minutes / 60).round());
  }

  /// How [instant] falls relative to [reference]: a [direction] of `before`
  /// or `after` with the [gap] between them ("about 2 days"), or `sameTime`
  /// with no gap within a minute.
  static ({String direction, String gap}) describeRelativeTo(DateTime instant, DateTime reference) {
    final gap = instant.difference(reference);
    if (gap.abs() < const Duration(minutes: 1)) return (direction: 'sameTime', gap: '');
    return (direction: gap.isNegative ? 'before' : 'after', gap: _describeGap(gap.abs()));
  }

  /// When [instant] happened in [timeZone], in only as much detail as places
  /// it from today: "at 5:42 PM", "on Tue at 5:42 PM" within the past week,
  /// then "on Oct 21 at 5:42 PM", with the year once it differs.
  static String describeWhen(
    DateTime instant,
    tz.Location timeZone, {
    DateTime? now,
  }) {
    final l10n = LocaleNotifier().localizations;
    final local = toLocal(instant, timeZone);
    final today = toLocal(now ?? DateTime.now(), timeZone);
    final time = formatTime(local);
    final daysAgo = calendarDaysBetween(local, today);
    if (daysAgo <= 0) return l10n.dateTimeAtTime(time);
    if (daysAgo < DateTime.daysPerWeek) {
      return l10n.dateTimeOnWeekdayAtTime(formatDayNameShort(local), time);
    }
    return l10n.dateTimeOnDateAtTime(formatDate(local, showYear: local.year != today.year), time);
  }

  static String _describeGap(Duration gap) {
    if ((gap.inMinutes / 60).round() < Duration.hoursPerDay) {
      return describeWait(gap);
    }
    return LocaleNotifier().localizations.dateTimeAboutDays((gap.inMinutes / Duration.minutesPerDay).round());
  }

  /// Word-month dates read month-first only for the month/day/year setting.
  static bool get _monthFirst =>
      LocaleNotifier().dateFormat == RegionalFormatConstants.dateFormatMonthDayYear;

  static String _ordered(String monthFirst, String dayFirst) => _monthFirst ? monthFirst : dayFirst;

  static String _todosDatePattern(bool showWeekday) => showWeekday
      ? _ordered('EEE, MMM d', 'EEE, d MMM')
      : _ordered('MMM d', 'd MMM');

  static int _weeksInYear(int year) {
    int p(int y) => (y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400)) % 7;
    return p(year) == 4 || p(year - 1) == 3 ? 53 : 52;
  }
}

enum RecurrenceFrequency { none, daily, weekly, monthly, yearly }

/// How a repeat ends. [defaultEnd] is the item's natural end: never for an
/// Event, the end of its class for an Assignment.
enum RecurrenceEnd { defaultEnd, onDate, afterCount }

/// A repeat as the picker edits it. Weekdays are Sunday-indexed (0 = Sunday).
class RecurrenceDraft {
  final RecurrenceFrequency frequency;
  final int interval;
  final Set<int> weekdays;
  final bool lastDayOfMonth;
  final RecurrenceEnd end;
  final DateTime? until;
  final int? count;

  const RecurrenceDraft({
    this.frequency = RecurrenceFrequency.none,
    this.interval = 1,
    this.weekdays = const {},
    this.lastDayOfMonth = false,
    this.end = RecurrenceEnd.defaultEnd,
    this.until,
    this.count,
  });

  bool get repeats => frequency != RecurrenceFrequency.none;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceDraft &&
      other.frequency == frequency &&
      other.interval == interval &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays) &&
      other.lastDayOfMonth == lastDayOfMonth &&
      other.end == end &&
      other.until == until &&
      other.count == count;

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        Object.hashAllUnordered(weekdays),
        lastDayOfMonth,
        end,
        until,
        count,
      );

  RecurrenceDraft copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    Set<int>? weekdays,
    bool? lastDayOfMonth,
    RecurrenceEnd? end,
    DateTime? until,
    int? count,
  }) {
    return RecurrenceDraft(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      lastDayOfMonth: lastDayOfMonth ?? this.lastDayOfMonth,
      end: end ?? this.end,
      until: until ?? this.until,
      count: count ?? this.count,
    );
  }
}

/// Composes and parses the RRULE subset the picker offers.
class HeliumRecurrence {
  static const repeatingFrequencies = [
    RecurrenceFrequency.daily,
    RecurrenceFrequency.weekly,
    RecurrenceFrequency.monthly,
    RecurrenceFrequency.yearly,
  ];

  static const _icalWeekdays = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

  static const _frequencies = {
    'DAILY': RecurrenceFrequency.daily,
    'WEEKLY': RecurrenceFrequency.weekly,
    'MONTHLY': RecurrenceFrequency.monthly,
    'YEARLY': RecurrenceFrequency.yearly,
  };

  static const _frequencyNames = {
    RecurrenceFrequency.daily: 'DAILY',
    RecurrenceFrequency.weekly: 'WEEKLY',
    RecurrenceFrequency.monthly: 'MONTHLY',
    RecurrenceFrequency.yearly: 'YEARLY',
  };
  static final _utcUntil = DateFormat("yyyyMMdd'T'HHmmss'Z'");

  static const _positionKeys = {1: 'first', 2: 'second', 3: 'third', 4: 'fourth', -1: 'last', -2: 'secondToLast'};

  HeliumRecurrence._();

  /// A monthly repeat from the 29th or later would skip the months without
  /// that day.
  static bool offersLastDayOfMonth(DateTime localStart) => localStart.day >= 29;

  static RecurrenceDraft defaultFor(RecurrenceFrequency frequency, DateTime localStart) {
    return RecurrenceDraft(
      frequency: frequency,
      weekdays: {HeliumDateTime.getDayIndex(localStart)},
    );
  }

  /// A weekly repeat on only the old start's weekday moves to the new one.
  static RecurrenceDraft followStart(RecurrenceDraft draft, DateTime previousStart, DateTime newStart) {
    final previousDay = HeliumDateTime.getDayIndex(previousStart);
    if (draft.frequency != RecurrenceFrequency.weekly ||
        draft.weekdays.length != 1 ||
        draft.weekdays.first != previousDay) {
      return draft;
    }
    return draft.copyWith(weekdays: {HeliumDateTime.getDayIndex(newStart)});
  }

  /// An end date includes its whole local day.
  static String? compose(RecurrenceDraft draft, DateTime localStart, tz.Location timeZone) {
    if (!draft.repeats) {
      return null;
    }

    final parts = <String>['FREQ=${_frequencyNames[draft.frequency]}'];
    if (draft.interval > 1) {
      parts.add('INTERVAL=${draft.interval}');
    }

    switch (draft.frequency) {
      case RecurrenceFrequency.weekly:
        final weekdays = draft.weekdays.isEmpty
            ? {HeliumDateTime.getDayIndex(localStart)}
            : draft.weekdays;
        parts.add('BYDAY=${(weekdays.toList()..sort()).map((day) => _icalWeekdays[day]).join(',')}');
      case RecurrenceFrequency.monthly:
        parts.add('BYMONTHDAY=${draft.lastDayOfMonth && offersLastDayOfMonth(localStart) ? -1 : localStart.day}');
      case RecurrenceFrequency.yearly:
        parts.add('BYMONTH=${localStart.month}');
        parts.add('BYMONTHDAY=${localStart.day}');
      case RecurrenceFrequency.daily:
      case RecurrenceFrequency.none:
        break;
    }

    if (draft.end == RecurrenceEnd.afterCount && draft.count != null) {
      parts.add('COUNT=${draft.count}');
    } else if (draft.end == RecurrenceEnd.onDate && draft.until != null) {
      parts.add('UNTIL=${_endOfDayUntil(draft.until!, timeZone)}');
    }

    return parts.join(';');
  }

  /// Null when the picker can't represent [rule]. An `UNTIL` at the end of
  /// [classEndDate], the end the server gives an assignment's repeat, reads as
  /// [RecurrenceEnd.defaultEnd].
  static RecurrenceDraft? parse(
    String? rule,
    DateTime localStart,
    tz.Location timeZone, {
    DateTime? classEndDate,
  }) {
    if (rule == null || rule.isEmpty) {
      return const RecurrenceDraft();
    }

    final parts = _parts(rule);
    final frequency = _frequencies[parts.remove('FREQ')];
    if (frequency == null) {
      return null;
    }

    final interval = int.tryParse(parts.remove('INTERVAL') ?? '1');
    if (interval == null || interval < 1) {
      return null;
    }

    var draft = RecurrenceDraft(frequency: frequency, interval: interval);

    final count = parts.remove('COUNT');
    final until = parts.remove('UNTIL');
    if (count != null && until != null) {
      return null;
    }
    if (count != null) {
      final parsedCount = int.tryParse(count);
      if (parsedCount == null) {
        return null;
      }
      draft = draft.copyWith(end: RecurrenceEnd.afterCount, count: parsedCount);
    } else if (classEndDate != null && until == _endOfDayUntil(classEndDate, timeZone)) {
      draft = draft.copyWith(end: RecurrenceEnd.defaultEnd);
    } else if (until != null) {
      final untilDate = _untilDate(until, timeZone);
      if (untilDate == null) {
        return null;
      }
      draft = draft.copyWith(end: RecurrenceEnd.onDate, until: untilDate);
    }

    final byDay = parts.remove('BYDAY');
    final byMonthDay = parts.remove('BYMONTHDAY');
    final byMonth = parts.remove('BYMONTH');
    if (parts.isNotEmpty) {
      return null;
    }

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return byDay == null && byMonthDay == null && byMonth == null ? draft : null;
      case RecurrenceFrequency.weekly:
        if (byMonthDay != null || byMonth != null) {
          return null;
        }
        final weekdays = byDay == null
            ? {HeliumDateTime.getDayIndex(localStart)}
            : byDay.split(',').map(_icalWeekdays.indexOf).toSet();
        return weekdays.contains(-1) ? null : draft.copyWith(weekdays: weekdays);
      case RecurrenceFrequency.monthly:
        if (byDay != null || byMonth != null) {
          return null;
        }
        if (byMonthDay == '-1') {
          return draft.copyWith(lastDayOfMonth: true);
        }
        return byMonthDay == null || byMonthDay == '${localStart.day}' ? draft : null;
      case RecurrenceFrequency.yearly:
        final matchesStart = (byMonth == null || byMonth == '${localStart.month}') &&
            (byMonthDay == null || byMonthDay == '${localStart.day}');
        return byDay == null && matchesStart ? draft : null;
      case RecurrenceFrequency.none:
        return null;
    }
  }

  /// How [rule] repeats, in words, for a rule [parse] can't represent. A rule
  /// with a part it can't put into words reads as a custom schedule.
  static String describe(String rule, DateTime localStart, tz.Location timeZone, {int weekStartsOn = 0}) {
    return _describe(rule, localStart, timeZone, weekStartsOn) ??
        LocaleNotifier().localizations.recurrenceCustomSchedule;
  }

  static String? _describe(String rule, DateTime localStart, tz.Location timeZone, int weekStartsOn) {
    final l10n = LocaleNotifier().localizations;
    final parts = _parts(rule);
    final frequency = _frequencies[parts.remove('FREQ')];
    final interval = int.tryParse(parts.remove('INTERVAL') ?? '1');
    if (frequency == null || interval == null || interval < 1) {
      return null;
    }

    final byDay = parts.remove('BYDAY');
    final bySetPos = parts.remove('BYSETPOS');
    final byMonthDay = parts.remove('BYMONTHDAY');
    final byMonth = parts.remove('BYMONTH');
    final count = parts.remove('COUNT');
    final until = parts.remove('UNTIL');
    if (parts.isNotEmpty || (byDay != null && byMonthDay != null)) {
      return null;
    }

    final repeats = _describeInterval(l10n, frequency, interval);
    final String? schedule;
    if (byDay != null) {
      schedule = _describeWeekdays(l10n, repeats, frequency, byDay, bySetPos, byMonth, weekStartsOn);
    } else if (bySetPos != null) {
      return null;
    } else if (byMonth != null) {
      schedule = frequency == RecurrenceFrequency.yearly
          ? _describeDayOfMonth(l10n, repeats, byMonth, byMonthDay ?? '${localStart.day}')
          : null;
    } else if (byMonthDay != null) {
      schedule = _describeMonthDay(l10n, repeats, byMonthDay);
    } else {
      schedule = repeats;
    }
    if (schedule == null) {
      return null;
    }

    return _describeEnd(l10n, schedule, count, until, timeZone);
  }

  static String _describeInterval(AppLocalizations l10n, RecurrenceFrequency frequency, int interval) {
    return switch (frequency) {
      RecurrenceFrequency.daily => l10n.recurrenceRepeatsDaily(interval),
      RecurrenceFrequency.weekly => l10n.recurrenceRepeatsWeekly(interval),
      RecurrenceFrequency.monthly => l10n.recurrenceRepeatsMonthly(interval),
      RecurrenceFrequency.yearly => l10n.recurrenceRepeatsYearly(interval),
      RecurrenceFrequency.none => throw ArgumentError.value(frequency, 'frequency'),
    };
  }

  static String? _describeWeekdays(
    AppLocalizations l10n,
    String repeats,
    RecurrenceFrequency frequency,
    String byDay,
    String? bySetPos,
    String? byMonth,
    int weekStartsOn,
  ) {
    final positioned = frequency == RecurrenceFrequency.monthly || frequency == RecurrenceFrequency.yearly;
    if (!positioned) {
      if (bySetPos != null || byMonth != null) {
        return null;
      }
      final weekdays = byDay.split(',').map(_icalWeekdays.indexOf).toList();
      if (weekdays.contains(-1)) {
        return null;
      }
      final ordered = weekdays.toSet().toList()..sort((a, b) => (a - weekStartsOn) % 7 - (b - weekStartsOn) % 7);
      final names = ordered.map((day) => _weekdayName(day, 'EEE'));
      return l10n.recurrenceOnWeekdays(repeats, names.reduce(l10n.commonListJoin));
    }

    final match = RegExp(r'^([+-]?\d{1,2})?([A-Z]{2})$').firstMatch(byDay);
    final weekday = match == null ? -1 : _icalWeekdays.indexOf(match.group(2)!);
    if (weekday == -1 || (match!.group(1) != null && bySetPos != null)) {
      return null;
    }
    final position = _positionKeys[int.tryParse(match.group(1) ?? bySetPos ?? '')];
    if (position == null) {
      return null;
    }
    final weekdayName = _weekdayName(weekday, 'EEEE');
    if (byMonth == null) {
      return frequency == RecurrenceFrequency.yearly
          ? null
          : l10n.recurrenceOnPositionWeekday(repeats, position, weekdayName);
    }
    final month = _monthName(byMonth);
    return frequency == RecurrenceFrequency.yearly && month != null
        ? l10n.recurrenceOnPositionWeekdayOfMonth(repeats, position, weekdayName, month)
        : null;
  }

  static String? _describeDayOfMonth(AppLocalizations l10n, String repeats, String byMonth, String byMonthDay) {
    final month = int.tryParse(byMonth);
    final day = int.tryParse(byMonthDay);
    if (month == null || day == null || month < 1 || month > 12) {
      return null;
    }
    if (day == -1) {
      return l10n.recurrenceOnLastDayOfMonth(repeats, _monthName(byMonth)!);
    }
    final date = DateTime(2000, month, day);
    if (day < 1 || date.month != month) {
      return null;
    }
    return l10n.recurrenceOnDate(repeats, HeliumDateTime.formatDate(date, abbreviateMonth: false, showYear: false));
  }

  static String? _describeMonthDay(AppLocalizations l10n, String repeats, String byMonthDay) {
    final day = int.tryParse(byMonthDay);
    if (day == -1) {
      return l10n.recurrenceOnLastDay(repeats);
    }
    return day == null || day < 1 || day > 31 ? null : l10n.recurrenceOnDay(repeats, day);
  }

  static String? _describeEnd(
    AppLocalizations l10n,
    String schedule,
    String? count,
    String? until,
    tz.Location timeZone,
  ) {
    final times = count == null ? null : int.tryParse(count);
    final untilDate = until == null ? null : _untilDate(until, timeZone);
    if ((count != null && (times == null || times < 1)) || (until != null && untilDate == null)) {
      return null;
    }
    final untilText = untilDate == null ? null : HeliumDateTime.formatDate(untilDate);
    if (times != null && untilText != null) {
      return l10n.recurrenceTimesUntil(schedule, times, untilText);
    }
    if (times != null) {
      return l10n.recurrenceTimes(schedule, times);
    }
    return untilText == null ? schedule : l10n.recurrenceUntil(schedule, untilText);
  }

  static String _weekdayName(int icalIndex, String pattern) =>
      DateFormat(pattern).format(DateTime(2023, 1, 1 + icalIndex));

  static String? _monthName(String byMonth) {
    final month = int.tryParse(byMonth);
    return month == null || month < 1 || month > 12 ? null : DateFormat('MMMM').format(DateTime(2000, month));
  }

  static Map<String, String> _parts(String rule) {
    final body = rule.toUpperCase().startsWith('RRULE:') ? rule.substring(6) : rule;
    final parts = <String, String>{};
    for (final part in body.split(';')) {
      final separator = part.indexOf('=');
      if (separator > 0) {
        parts[part.substring(0, separator).toUpperCase()] = part.substring(separator + 1).toUpperCase();
      }
    }
    return parts;
  }

  static String _endOfDayUntil(DateTime date, tz.Location timeZone) =>
      _utcUntil.format(tz.TZDateTime(timeZone, date.year, date.month, date.day, 23, 59, 59).toUtc());

  static DateTime? _untilDate(String until, tz.Location timeZone) {
    final match = RegExp(r'^(\d{4})(\d{2})(\d{2})(T(\d{2})(\d{2})(\d{2})(Z?))?$').firstMatch(until);
    if (match == null) {
      return null;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (match.group(8) != 'Z') {
      return DateTime(year, month, day);
    }
    final instant = DateTime.utc(year, month, day, int.parse(match.group(5)!), int.parse(match.group(6)!),
        int.parse(match.group(7)!));
    final local = tz.TZDateTime.from(instant, timeZone);
    return DateTime(local.year, local.month, local.day);
  }
}
