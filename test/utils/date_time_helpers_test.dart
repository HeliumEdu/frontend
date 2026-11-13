import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/regional_settings_notifier.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('TimeHelpers', () {
    group('parse', () {
      test('parses valid time string correctly', () {
        final result = HeliumTime.parse('14:30:00');
        expect(result, isNotNull);
        expect(result!.hour, equals(14));
        expect(result.minute, equals(30));
      });

      test('parses morning time correctly', () {
        final result = HeliumTime.parse('09:15:00');
        expect(result, isNotNull);
        expect(result!.hour, equals(9));
        expect(result.minute, equals(15));
      });

      test('parses midnight adjacent time correctly', () {
        final result = HeliumTime.parse('23:59:00');
        expect(result, isNotNull);
        expect(result!.hour, equals(23));
        expect(result.minute, equals(59));
      });
    });

    group('formatForDisplay', () {
      test('formats AM time correctly', () {
        const time = TimeOfDay(hour: 9, minute: 30);
        expect(HeliumTime.format(time), equals('9:30 AM'));
      });

      test('formats PM time correctly', () {
        const time = TimeOfDay(hour: 14, minute: 45);
        expect(HeliumTime.format(time), equals('2:45 PM'));
      });

      test('formats noon correctly', () {
        const time = TimeOfDay(hour: 12, minute: 0);
        expect(HeliumTime.format(time), equals('12:00 PM'));
      });

      test('formats midnight correctly', () {
        const time = TimeOfDay(hour: 0, minute: 0);
        expect(HeliumTime.format(time), equals('12:00 AM'));
      });

      test('pads single digit minutes', () {
        const time = TimeOfDay(hour: 10, minute: 5);
        expect(HeliumTime.format(time), equals('10:05 AM'));
      });
    });

    group('formatForApi', () {
      test('formats time with seconds for API', () {
        const time = TimeOfDay(hour: 14, minute: 30);
        expect(HeliumTime.formatForApi(time), equals('14:30:00'));
      });

      test('pads single digit hours', () {
        const time = TimeOfDay(hour: 9, minute: 15);
        expect(HeliumTime.formatForApi(time), equals('09:15:00'));
      });

      test('pads single digit minutes', () {
        const time = TimeOfDay(hour: 10, minute: 5);
        expect(HeliumTime.formatForApi(time), equals('10:05:00'));
      });

      test('formats midnight correctly', () {
        const time = TimeOfDay(hour: 0, minute: 0);
        expect(HeliumTime.formatForApi(time), equals('00:00:00'));
      });
    });
  });

  group('DateTimeHelpers', () {
    group('dateOnly', () {
      test('strips time from datetime', () {
        final dateTime = DateTime(2025, 8, 15, 14, 30, 45);
        final result = HeliumDateTime.dateOnly(dateTime);
        expect(result, equals(DateTime(2025, 8, 15)));
        expect(result.hour, equals(0));
        expect(result.minute, equals(0));
        expect(result.second, equals(0));
      });

      test('preserves date when already at midnight', () {
        final dateTime = DateTime(2025, 8, 15);
        final result = HeliumDateTime.dateOnly(dateTime);
        expect(result, equals(DateTime(2025, 8, 15)));
      });

      test('handles end of day time', () {
        final dateTime = DateTime(2025, 8, 15, 23, 59, 59, 999);
        final result = HeliumDateTime.dateOnly(dateTime);
        expect(result, equals(DateTime(2025, 8, 15)));
      });
    });

    group('describeWait', () {
      test('rounds a wait under an hour up to the minute', () {
        expect(HeliumDateTime.describeWait(const Duration(seconds: 30)), 'a minute');
        expect(HeliumDateTime.describeWait(const Duration(seconds: 61)), '2 minutes');
        expect(HeliumDateTime.describeWait(const Duration(seconds: 3540)), '59 minutes');
      });

      test('rounds a wait of an hour or more to the nearest hour', () {
        expect(HeliumDateTime.describeWait(const Duration(seconds: 3599)), 'about an hour');
        expect(HeliumDateTime.describeWait(const Duration(minutes: 89)), 'about an hour');
        expect(HeliumDateTime.describeWait(const Duration(minutes: 90)), 'about 2 hours');
        expect(HeliumDateTime.describeWait(const Duration(hours: 3)), 'about 3 hours');
      });
    });

    group('describeRelativeTo', () {
      final reference = DateTime.utc(2026, 11, 3, 15, 10);

      test('within a minute either way is around the same time', () {
        // WHEN
        final later = HeliumDateTime.describeRelativeTo(
          reference.add(const Duration(seconds: 40)),
          reference,
        );
        final earlier = HeliumDateTime.describeRelativeTo(
          reference.subtract(const Duration(seconds: 40)),
          reference,
        );

        // THEN
        expect(later, 'around the same time as');
        expect(earlier, 'around the same time as');
      });

      test('under a day reads in minutes or hours, with its direction', () {
        // WHEN
        final minutesAfter = HeliumDateTime.describeRelativeTo(
          reference.add(const Duration(minutes: 3)),
          reference,
        );
        final hoursBefore = HeliumDateTime.describeRelativeTo(
          reference.subtract(const Duration(hours: 3, minutes: 10)),
          reference,
        );

        // THEN
        expect(minutesAfter, '3 minutes after');
        expect(hoursBefore, 'about 3 hours before');
      });

      test('a day or more reads in whole days', () {
        // WHEN
        final nearlyADay = HeliumDateTime.describeRelativeTo(
          reference.add(const Duration(hours: 23, minutes: 40)),
          reference,
        );
        final days = HeliumDateTime.describeRelativeTo(
          reference.add(const Duration(days: 2, hours: 5)),
          reference,
        );

        // THEN
        expect(nearlyADay, 'about a day after');
        expect(days, 'about 2 days after');
      });
    });

    group('laterTimestamp', () {
      test('picks the later of two timestamps', () {
        // GIVEN
        const earlier = '2026-11-03T15:10:00.123456Z';
        const later = '2026-11-04T09:05:00.654321Z';

        // WHEN
        final picked = HeliumDateTime.laterTimestamp(earlier, later);
        final pickedReversed = HeliumDateTime.laterTimestamp(later, earlier);

        // THEN
        expect(picked, later);
        expect(pickedReversed, later);
      });

      test('falls back to whichever timestamp parses', () {
        // GIVEN
        const valid = '2026-11-04T09:05:00Z';

        // WHEN
        final firstMissing = HeliumDateTime.laterTimestamp(null, valid);
        final secondInvalid = HeliumDateTime.laterTimestamp(valid, 'bad');

        // THEN
        expect(firstMissing, valid);
        expect(secondInvalid, valid);
      });
    });

    group('describeWhen', () {
      final now = DateTime.utc(2026, 11, 4, 20);

      test('a change earlier today shows only the time', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final instant = DateTime.utc(2026, 11, 4, 18, 30);

        // WHEN
        final inLa = HeliumDateTime.describeWhen(instant, la, now: now);
        final inAmsterdam = HeliumDateTime.describeWhen(
          instant,
          amsterdam,
          now: now,
        );

        // THEN
        expect(inLa, 'at 10:30 AM');
        expect(inAmsterdam, 'at 7:30 PM');
      });

      test('the day is read in the user zone, not UTC', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final instant = DateTime.utc(2026, 11, 3, 23, 30);

        // WHEN
        final inLa = HeliumDateTime.describeWhen(instant, la, now: now);
        final inAmsterdam = HeliumDateTime.describeWhen(
          instant,
          amsterdam,
          now: now,
        );

        // THEN
        expect(inAmsterdam, 'at 12:30 AM');
        expect(inLa, 'on Tue at 3:30 PM');
      });

      test('a change within the past week names the weekday', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final instant = DateTime.utc(2026, 10, 29, 20);

        // WHEN
        final described = HeliumDateTime.describeWhen(instant, la, now: now);

        // THEN
        expect(described, 'on Thu at 1 PM');
      });

      test('a change a week or more ago names the date', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final instant = DateTime.utc(2026, 10, 28, 20);

        // WHEN
        final described = HeliumDateTime.describeWhen(instant, la, now: now);

        // THEN
        expect(described, 'on Oct 28 at 1 PM');
      });

      test('a change in another year includes the year', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final instant = DateTime.utc(2025, 12, 20, 20);

        // WHEN
        final described = HeliumDateTime.describeWhen(instant, la, now: now);

        // THEN
        expect(described, 'on Dec 20, 2025 at 12 PM');
      });
    });

    group('visibleAnchorFor', () {
      test('anchors two hours before the time during the day', () {
        // GIVEN
        final time = DateTime(2026, 11, 4, 9);

        // WHEN
        final anchor = HeliumDateTime.visibleAnchorFor(time);

        // THEN
        expect(anchor, DateTime(2026, 11, 4, 7));
      });

      test('stays on the same day just after midnight', () {
        // GIVEN
        final time = DateTime(2026, 11, 4, 1);

        // WHEN
        final anchor = HeliumDateTime.visibleAnchorFor(time);

        // THEN
        expect(
          anchor,
          DateTime(2026, 11, 4),
          reason: 'Two hours back would show the previous day',
        );
      });

      test('stays in the same month on the first just after midnight', () {
        // GIVEN
        final time = DateTime(2026, 12, 1);

        // WHEN
        final anchor = HeliumDateTime.visibleAnchorFor(time);

        // THEN
        expect(
          anchor,
          DateTime(2026, 12, 1),
          reason: 'Two hours back would show the previous month',
        );
      });

      test('stays on the same day on a DST change day', () {
        // GIVEN
        final time = DateTime(2026, 11, 1, 1);

        // WHEN
        final anchor = HeliumDateTime.visibleAnchorFor(time);

        // THEN
        expect(anchor, DateTime(2026, 11, 1));
      });
    });

    group('addDays', () {
      test('lands on the next midnight across a fall-back day', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final midnight = tz.TZDateTime(amsterdam, 2026, 10, 25);

        // WHEN
        final next = HeliumDateTime.addDays(midnight, 1);

        // THEN
        expect(next, tz.TZDateTime(amsterdam, 2026, 10, 26));
        expect(midnight.add(const Duration(days: 1)), isNot(next),
            reason: 'an absolute 24h step lands on 23:00 on the 25-hour day');
      });

      test('lands on the previous midnight across a spring-forward day', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final midnight = tz.TZDateTime(amsterdam, 2026, 3, 30);

        // WHEN
        final previous = HeliumDateTime.addDays(midnight, -1);

        // THEN
        expect(previous, tz.TZDateTime(amsterdam, 2026, 3, 29));
      });

      test('matches an absolute day step on a day without a transition', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final midnight = tz.TZDateTime(la, 2026, 6, 10);

        // WHEN
        final next = HeliumDateTime.addDays(midnight, 1);

        // THEN
        expect(next, tz.TZDateTime(la, 2026, 6, 11));
        expect(next, midnight.add(const Duration(days: 1)));
      });

      test('keeps the wall clock time and zone of the value', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final value = tz.TZDateTime(la, 2026, 10, 31, 9, 30);

        // WHEN
        final next = HeliumDateTime.addDays(value, 1);

        // THEN
        expect(next, isA<tz.TZDateTime>());
        expect((next as tz.TZDateTime).location, la);
        expect([next.year, next.month, next.day, next.hour, next.minute], [2026, 11, 1, 9, 30]);
      });

      test('steps a naive date by calendar day', () {
        // GIVEN
        final date = DateTime(2026, 12, 31);

        // WHEN
        final next = HeliumDateTime.addDays(date, 1);

        // THEN
        expect(next, DateTime(2027, 1, 1));
        expect(next.isUtc, isFalse);
      });
    });

    group('allDayExceptionIn', () {
      test('reads a UTC-midnight exception as its calendar date west of UTC', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final exception = DateTime.parse('2026-10-05T00:00:00Z');

        // WHEN
        final resolved = HeliumDateTime.allDayExceptionIn(exception, la);

        // THEN
        expect(resolved, tz.TZDateTime(la, 2026, 10, 5));
        expect(HeliumDateTime.wallClockIn(exception, la).day, 4,
            reason: 'reading it as an instant lands on the previous day');
      });

      test('reads a UTC-midnight exception as its calendar date east of UTC', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final exception = DateTime.parse('2026-10-05T00:00:00Z');

        // WHEN
        final resolved = HeliumDateTime.allDayExceptionIn(exception, amsterdam);

        // THEN
        expect(resolved, tz.TZDateTime(amsterdam, 2026, 10, 5));
      });

      test('keeps an exception that is a local-midnight instant on its date', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final exception = tz.TZDateTime(la, 2026, 10, 5).toUtc();

        // WHEN
        final resolved = HeliumDateTime.allDayExceptionIn(exception, la);

        // THEN
        expect(resolved, tz.TZDateTime(la, 2026, 10, 5));
      });
    });

    group('allDayEndAfterMove', () {
      test('keeps the calendar-day length when moved onto a fall-back day', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final originalStart = tz.TZDateTime(amsterdam, 2026, 10, 17);
        final originalEnd = tz.TZDateTime(amsterdam, 2026, 10, 19);
        final newStart = tz.TZDateTime(amsterdam, 2026, 10, 24);

        // WHEN
        final newEnd = HeliumDateTime.allDayEndAfterMove(newStart, originalStart, originalEnd);

        // THEN
        expect(newEnd, tz.TZDateTime(amsterdam, 2026, 10, 26));
        expect(newStart.add(originalEnd.difference(originalStart)), isNot(newEnd),
            reason: 'keeping the absolute duration lands on 23:00 and drops the last day');
      });

      test('keeps the calendar-day length when moved off a spring-forward day', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final originalStart = tz.TZDateTime(la, 2026, 3, 8);
        final originalEnd = tz.TZDateTime(la, 2026, 3, 9);
        final newStart = tz.TZDateTime(la, 2026, 3, 15);

        // WHEN
        final newEnd = HeliumDateTime.allDayEndAfterMove(newStart, originalStart, originalEnd);

        // THEN
        expect(newEnd, tz.TZDateTime(la, 2026, 3, 16));
      });
    });

    group('calendarDaysBetween', () {
      test('counts calendar days across a fall-back day', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');
        final start = tz.TZDateTime(amsterdam, 2026, 10, 23);
        final end = tz.TZDateTime(amsterdam, 2026, 10, 26);

        // WHEN
        final days = HeliumDateTime.calendarDaysBetween(start, end);

        // THEN
        expect(days, 3);
        expect(end.difference(start).inHours, 73);
      });

      test('counts calendar days on days without a transition', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');
        final start = tz.TZDateTime(la, 2026, 6, 10);
        final end = tz.TZDateTime(la, 2026, 6, 12);

        // WHEN
        final days = HeliumDateTime.calendarDaysBetween(start, end);

        // THEN
        expect(days, 2);
      });
    });

    group('getDayIndex', () {
      test('returns 0 for Sunday', () {
        final sunday = DateTime(2025, 8, 24); // Sunday
        expect(HeliumDateTime.getDayIndex(sunday), equals(0));
      });

      test('returns 1 for Monday', () {
        final monday = DateTime(2025, 8, 25); // Monday
        expect(HeliumDateTime.getDayIndex(monday), equals(1));
      });

      test('returns 2 for Tuesday', () {
        final tuesday = DateTime(2025, 8, 26); // Tuesday
        expect(HeliumDateTime.getDayIndex(tuesday), equals(2));
      });

      test('returns 3 for Wednesday', () {
        final wednesday = DateTime(2025, 8, 27); // Wednesday
        expect(HeliumDateTime.getDayIndex(wednesday), equals(3));
      });

      test('returns 4 for Thursday', () {
        final thursday = DateTime(2025, 8, 28); // Thursday
        expect(HeliumDateTime.getDayIndex(thursday), equals(4));
      });

      test('returns 5 for Friday', () {
        final friday = DateTime(2025, 8, 29); // Friday
        expect(HeliumDateTime.getDayIndex(friday), equals(5));
      });

      test('returns 6 for Saturday', () {
        final saturday = DateTime(2025, 8, 30); // Saturday
        expect(HeliumDateTime.getDayIndex(saturday), equals(6));
      });
    });

    group('formatName', () {
      test('returns abbreviated day name', () {
        final monday = DateTime(2025, 1, 20); // Monday
        expect(HeliumDateTime.formatDayNameShort(monday), equals('Mon'));
      });

      test('returns 3-character day abbreviation', () {
        final sunday = DateTime(2025, 1, 19); // Sunday
        final result = HeliumDateTime.formatDayNameShort(sunday);
        expect(result.length, equals(3));
      });
    });

    group('time formatting follows the regional clock', () {
      final afternoon = DateTime(2026, 9, 20, 15, 0);
      final afternoonWithMinutes = DateTime(2026, 9, 20, 15, 5);

      Future<void> useClock(int timeFormat) => RegionalSettingsNotifier().update(
            weekStartsOn: 0,
            dateFormat: 0,
            timeFormat: timeFormat,
            numberFormat: 0,
          );

      tearDown(() => useClock(RegionalFormatConstants.timeFormatTwelveHour));

      test('12-hour keeps the short form on the hour', () async {
        await useClock(RegionalFormatConstants.timeFormatTwelveHour);
        expect(HeliumTime.format(const TimeOfDay(hour: 15, minute: 0)), '3:00 PM');
        expect(HeliumDateTime.formatTime(afternoon), '3 PM');
        expect(HeliumDateTime.formatTime(afternoonWithMinutes), '3:05 PM');
        expect(HeliumDateTime.formatDateAndTimeForTodos(afternoon), 'Sun, Sep 20 • 3 PM');
        expect(HeliumTime.timeRulerPattern, 'h a');
      });

      test('24-hour never drops the minutes', () async {
        await useClock(RegionalFormatConstants.timeFormatTwentyFourHour);
        expect(HeliumTime.format(const TimeOfDay(hour: 15, minute: 0)), '15:00');
        expect(HeliumDateTime.formatTime(afternoon), '15:00');
        expect(HeliumDateTime.formatTime(afternoonWithMinutes), '15:05');
        expect(HeliumDateTime.formatTime(DateTime(2026, 9, 20, 0, 5)), '00:05');
        expect(HeliumDateTime.formatDateAndTimeForTodos(afternoon), 'Sun, Sep 20 • 15:00');
        expect(HeliumTime.timeRulerPattern, 'HH:mm');
      });
    });

    group('date formatting follows the regional order', () {
      final date = DateTime(2026, 9, 4, 15, 0);

      Future<void> useOrder(int dateFormat) => RegionalSettingsNotifier().update(
            weekStartsOn: 0,
            dateFormat: dateFormat,
            timeFormat: 0,
            numberFormat: 0,
          );

      tearDown(() => useOrder(RegionalFormatConstants.dateFormatMonthDayYear));

      test('month/day/year reads month-first', () async {
        await useOrder(RegionalFormatConstants.dateFormatMonthDayYear);
        expect(HeliumDateTime.formatDate(date), 'Sep 4, 2026');
        expect(HeliumDateTime.formatDate(date, abbreviateMonth: false, showYear: false), 'September 4');
        expect(HeliumDateTime.formatDateForTodos(date), 'Fri, Sep 4');
        expect(HeliumDateTime.formatDateAndTimeForTodos(date), 'Fri, Sep 4 • 3 PM');
        expect(HeliumDateTime.formatDateWithDay(date), 'Friday, September 4');
        expect(HeliumDateTime.dateFormatForChartAxis.format(date), 'Sep 4');
      });

      test('day/month/year reads day-first', () async {
        await useOrder(RegionalFormatConstants.dateFormatDayMonthYear);
        expect(HeliumDateTime.formatDate(date), '4 Sep 2026');
        expect(HeliumDateTime.formatDate(date, abbreviateMonth: false, showYear: false), '4 September');
        expect(HeliumDateTime.formatDateForTodos(date), 'Fri, 4 Sep');
        expect(HeliumDateTime.formatDateAndTimeForTodos(date), 'Fri, 4 Sep • 3 PM');
        expect(HeliumDateTime.formatDateWithDay(date), 'Friday, 4 September');
        expect(HeliumDateTime.dateFormatForChartAxis.format(date), '4 Sep');
      });

      test('month and year are order-independent', () async {
        await useOrder(RegionalFormatConstants.dateFormatDayMonthYear);
        expect(HeliumDateTime.formatMonthAndYear(date), 'Sep 2026');
      });
    });

    group('detectDateFormat', () {
      test('detects month-first for the US', () async {
        expect(await HeliumDateTime.detectDateFormat(const Locale('en', 'US')),
            RegionalFormatConstants.dateFormatMonthDayYear);
      });

      test('detects day-first for the UK, Germany, and India', () async {
        for (final locale in [const Locale('en', 'GB'), const Locale('de', 'DE'), const Locale('en', 'IN')]) {
          expect(await HeliumDateTime.detectDateFormat(locale), RegionalFormatConstants.dateFormatDayMonthYear,
              reason: locale.toString());
        }
      });

      test('treats year-first locales such as Japan, Hungary, and Canada as day-first', () async {
        for (final locale in [const Locale('ja', 'JP'), const Locale('hu', 'HU'), const Locale('en', 'CA')]) {
          expect(await HeliumDateTime.detectDateFormat(locale), RegionalFormatConstants.dateFormatDayMonthYear,
              reason: locale.toString());
        }
      });

      test('falls back to month-first for an unknown locale', () async {
        expect(await HeliumDateTime.detectDateFormat(const Locale('xx', 'XX')), RegionalFormatConstants.dateFormatMonthDayYear);
      });
    });

    group('detectWeekStartsOn', () {
      test('detects Sunday for the US, Canada, and Japan', () async {
        for (final locale in [const Locale('en', 'US'), const Locale('en', 'CA'), const Locale('ja', 'JP')]) {
          expect(await HeliumDateTime.detectWeekStartsOn(locale), 0, reason: locale.toString());
        }
      });

      test('detects Monday for the UK, Germany, and the Netherlands', () async {
        for (final locale in [const Locale('en', 'GB'), const Locale('de', 'DE'), const Locale('nl', 'NL')]) {
          expect(await HeliumDateTime.detectWeekStartsOn(locale), 1, reason: locale.toString());
        }
      });

      test('detects Saturday for Saudi Arabia', () async {
        expect(await HeliumDateTime.detectWeekStartsOn(const Locale('ar', 'SA')), 6);
      });

      test('falls back to Sunday for an unknown locale', () async {
        expect(await HeliumDateTime.detectWeekStartsOn(const Locale('xx', 'XX')), RegionalFormatConstants.weekStartsOnSunday);
      });
    });

    group('detectTimeFormat', () {
      test('prefers the OS 24-hour toggle when reported', () async {
        expect(await HeliumDateTime.detectTimeFormat(const Locale('en', 'US'), alwaysUse24HourFormat: true),
            RegionalFormatConstants.timeFormatTwentyFourHour);
        expect(await HeliumDateTime.detectTimeFormat(const Locale('de', 'DE'), alwaysUse24HourFormat: false),
            RegionalFormatConstants.timeFormatTwelveHour);
      });

      test('infers from the locale when the OS reports nothing', () async {
        expect(await HeliumDateTime.detectTimeFormat(const Locale('en', 'US')),
            RegionalFormatConstants.timeFormatTwelveHour);
        expect(await HeliumDateTime.detectTimeFormat(const Locale('de', 'DE')),
            RegionalFormatConstants.timeFormatTwentyFourHour);
        expect(await HeliumDateTime.detectTimeFormat(const Locale('en', 'GB')),
            RegionalFormatConstants.timeFormatTwentyFourHour);
      });

      test('falls back to 12-hour for an unknown locale', () async {
        expect(await HeliumDateTime.detectTimeFormat(const Locale('xx', 'XX')), RegionalFormatConstants.timeFormatTwelveHour);
      });
    });

    group('formatExamples', () {
      test('render each date and time format', () {
        final date = DateTime(2026, 9, 20, 13, 5);
        expect(HeliumDateTime.dateFormatExample(RegionalFormatConstants.dateFormatMonthDayYear, date), 'Sep 20, 2026');
        expect(HeliumDateTime.dateFormatExample(RegionalFormatConstants.dateFormatDayMonthYear, date), '20 Sep 2026');
        expect(HeliumDateTime.timeFormatExample(RegionalFormatConstants.timeFormatTwelveHour, date), '1:05 PM');
        expect(HeliumDateTime.timeFormatExample(RegionalFormatConstants.timeFormatTwentyFourHour, date), '13:05');
      });
    });

    group('dateFormatForChartAxis', () {
      test('formats without a zero-padded day', () {
        final date = DateTime(2025, 8, 4);
        expect(HeliumDateTime.dateFormatForChartAxis.format(date), equals('Aug 4'));
      });
    });

    group('formatForDisplay', () {
      test('formats date in MMM dd, yyyy format', () {
        final date = DateTime(2025, 8, 15);
        expect(HeliumDateTime.formatDate(date), equals('Aug 15, 2025'));
      });

      test('formats January date correctly', () {
        final date = DateTime(2025, 1, 1);
        expect(HeliumDateTime.formatDate(date), equals('Jan 1, 2025'));
      });

      test('formats December date correctly', () {
        final date = DateTime(2025, 12, 31);
        expect(HeliumDateTime.formatDate(date), equals('Dec 31, 2025'));
      });
    });

    group('formatForApi', () {
      test('formats date as ISO date string (YYYY-MM-DD)', () {
        final date = DateTime(2025, 8, 15, 10, 30, 0);
        expect(HeliumDateTime.formatDateForApi(date), equals('2025-08-15'));
      });

      test('pads single digit month', () {
        final date = DateTime(2025, 5, 15);
        expect(HeliumDateTime.formatDateForApi(date), equals('2025-05-15'));
      });

      test('pads single digit day', () {
        final date = DateTime(2025, 10, 5);
        expect(HeliumDateTime.formatDateForApi(date), equals('2025-10-05'));
      });
    });

    group('formatDateAndTimeForApi', () {
      test('returns valid ISO 8601 string with time component', () {
        final location = tz.getLocation('America/New_York');
        final date = DateTime(2025, 8, 15);
        const time = TimeOfDay(hour: 14, minute: 30);

        final result = HeliumDateTime.formatDateAndTimeForApi(
          date,
          time,
          location,
        );

        expect(
          result,
          matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+')),
        );
      });

      test('returns ISO string for date only when time is null', () {
        final location = tz.getLocation('America/New_York');
        final date = DateTime(2025, 8, 15);

        final result = HeliumDateTime.formatDateAndTimeForApi(
          date,
          null,
          location,
        );

        expect(result, contains('2025-08-15'));
      });
    });

    group('dayRangeIn', () {
      for (final zoneName in ['Europe/Amsterdam', 'America/Los_Angeles']) {
        test('reads only the dates of month-cell times ($zoneName)', () {
          // GIVEN
          final zone = tz.getLocation(zoneName);
          final monthCellStart = DateTime(2026, 11, 10, 0, 2);
          final monthCellEnd = DateTime(2026, 11, 12, 23, 59, 59);

          // WHEN
          final (start, end) = HeliumDateTime.dayRangeIn(monthCellStart, monthCellEnd, zone);

          // THEN
          expect(start, tz.TZDateTime(zone, 2026, 11, 10));
          expect(end, tz.TZDateTime(zone, 2026, 11, 13));
        });
      }

      test('spans whole days across a fall-back day', () {
        // GIVEN
        final amsterdam = tz.getLocation('Europe/Amsterdam');

        // WHEN
        final (start, endExclusive) = HeliumDateTime.dayRangeIn(
          DateTime(2026, 10, 24),
          DateTime(2026, 10, 25),
          amsterdam,
        );

        // THEN
        expect(start, tz.TZDateTime(amsterdam, 2026, 10, 24));
        expect(endExclusive, tz.TZDateTime(amsterdam, 2026, 10, 26));
        expect(endExclusive.difference(start).inHours, 49);
      });

      test('spans whole days on days without a transition', () {
        // GIVEN
        final la = tz.getLocation('America/Los_Angeles');

        // WHEN
        final (start, endExclusive) = HeliumDateTime.dayRangeIn(
          DateTime(2026, 6, 10),
          DateTime(2026, 6, 10),
          la,
        );

        // THEN
        expect(start, tz.TZDateTime(la, 2026, 6, 10));
        expect(endExclusive, tz.TZDateTime(la, 2026, 6, 11));
      });
    });

    group('getPercentDiffBetween', () {
      test('returns 0 when before start date', () {
        final now = DateTime.now();
        final futureStart = now.add(const Duration(days: 30));
        final futureEnd = now.add(const Duration(days: 60));

        final result = HeliumDateTime.getPercentDiffBetween(futureStart, futureEnd);
        expect(result, equals(0));
      });

      test('returns 100 when after end date', () {
        final now = DateTime.now();
        final pastStart = now.subtract(const Duration(days: 60));
        final pastEnd = now.subtract(const Duration(days: 30));

        final result = HeliumDateTime.getPercentDiffBetween(pastStart, pastEnd);
        expect(result, equals(100));
      });

      test('returns 0 when before start (even if consecutive dates)', () {
        final now = DateTime.now();
        final futureStart = now.add(const Duration(days: 30));
        final futureEnd = now.add(const Duration(days: 31));

        expect(
          HeliumDateTime.getPercentDiffBetween(futureStart, futureEnd),
          equals(0),
        );
      });

      test('returns 100 when after end (even if consecutive dates)', () {
        final now = DateTime.now();
        final pastStart = now.subtract(const Duration(days: 31));
        final pastEnd = now.subtract(const Duration(days: 30));

        expect(
          HeliumDateTime.getPercentDiffBetween(pastStart, pastEnd),
          equals(100),
        );
      });

      test('result is always between 0 and 100', () {
        final now = DateTime.now();

        final pastStart = now.subtract(const Duration(days: 60));
        final pastEnd = now.subtract(const Duration(days: 30));
        final result1 = HeliumDateTime.getPercentDiffBetween(pastStart, pastEnd);
        expect(result1, greaterThanOrEqualTo(0));
        expect(result1, lessThanOrEqualTo(100));

        final futureStart = now.add(const Duration(days: 30));
        final futureEnd = now.add(const Duration(days: 60));
        final result2 = HeliumDateTime.getPercentDiffBetween(futureStart, futureEnd);
        expect(result2, greaterThanOrEqualTo(0));
        expect(result2, lessThanOrEqualTo(100));
      });

      test('returns approximately 50% at midpoint of range', () {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 50));
        final end = now.add(const Duration(days: 50));

        final result = HeliumDateTime.getPercentDiffBetween(start, end);
        expect(result, greaterThanOrEqualTo(45));
        expect(result, lessThanOrEqualTo(55));
      });
    });

    group('toLocal - timezone conversion', () {
      test('converts UTC to America/New_York (UTC-5 standard, UTC-4 DST)', () {
        final nyTz = tz.getLocation('America/New_York');
        final utcWinter = DateTime.utc(2025, 1, 15, 12, 0, 0);
        final localWinter = HeliumDateTime.toLocal(utcWinter, nyTz);
        expect(localWinter.hour, equals(7)); // 12:00 UTC = 7:00 EST

        final utcSummer = DateTime.utc(2025, 7, 15, 12, 0, 0);
        final localSummer = HeliumDateTime.toLocal(utcSummer, nyTz);
        expect(localSummer.hour, equals(8)); // 12:00 UTC = 8:00 EDT
      });

      test('converts UTC to Europe/London (UTC+0 standard, UTC+1 DST)', () {
        final londonTz = tz.getLocation('Europe/London');
        final utcWinter = DateTime.utc(2025, 1, 15, 12, 0, 0);
        final localWinter = HeliumDateTime.toLocal(utcWinter, londonTz);
        expect(localWinter.hour, equals(12)); // 12:00 UTC = 12:00 GMT

        final utcSummer = DateTime.utc(2025, 7, 15, 12, 0, 0);
        final localSummer = HeliumDateTime.toLocal(utcSummer, londonTz);
        expect(localSummer.hour, equals(13)); // 12:00 UTC = 13:00 BST
      });

      test('converts UTC to Asia/Tokyo (UTC+9, no DST)', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utc = DateTime.utc(2025, 6, 15, 12, 0, 0);
        final local = HeliumDateTime.toLocal(utc, tokyoTz);
        expect(local.hour, equals(21)); // 12:00 UTC = 21:00 JST
      });

      test('handles UTC midnight boundary - date changes in positive offset', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utcMidnight = DateTime.utc(2025, 6, 15, 0, 0, 0);
        final local = HeliumDateTime.toLocal(utcMidnight, tokyoTz);

        expect(local.day, equals(15)); // Still June 15
        expect(local.hour, equals(9)); // 00:00 UTC = 09:00 JST
      });

      test('handles UTC midnight boundary - date changes in negative offset', () {
        final laTz = tz.getLocation('America/Los_Angeles');
        final utcEarlyMorning = DateTime.utc(2025, 1, 15, 3, 0, 0);
        final local = HeliumDateTime.toLocal(utcEarlyMorning, laTz);

        expect(local.day, equals(14)); // Should be January 14
        expect(local.hour, equals(19)); // 03:00 UTC = 19:00 PST previous day
      });

      test('handles extreme positive timezone (Pacific/Kiritimati UTC+14)', () {
        final kiritimatiTz = tz.getLocation('Pacific/Kiritimati');
        final utc = DateTime.utc(2025, 6, 15, 10, 0, 0);
        final local = HeliumDateTime.toLocal(utc, kiritimatiTz);

        expect(local.day, equals(16)); // Should be next day
        expect(local.hour, equals(0)); // 10:00 UTC = 00:00+14 next day
      });

      test('handles extreme negative timezone (Pacific/Midway UTC-11)', () {
        final midwayTz = tz.getLocation('Pacific/Midway');
        final utc = DateTime.utc(2025, 6, 15, 5, 0, 0);
        final local = HeliumDateTime.toLocal(utc, midwayTz);

        expect(local.day, equals(14)); // Should be previous day
        expect(local.hour, equals(18)); // 05:00 UTC = 18:00-11 previous day
      });

      test('handles DST spring forward transition (America/New_York)', () {
        final nyTz = tz.getLocation('America/New_York');

        final beforeDst = DateTime.utc(2025, 3, 9, 6, 0, 0);
        final localBefore = HeliumDateTime.toLocal(beforeDst, nyTz);
        expect(localBefore.hour, equals(1)); // 1:00 AM EST

        final afterDst = DateTime.utc(2025, 3, 9, 8, 0, 0);
        final localAfter = HeliumDateTime.toLocal(afterDst, nyTz);
        expect(localAfter.hour, equals(4)); // 4:00 AM EDT
      });

      test('handles DST fall back transition (America/New_York)', () {
        final nyTz = tz.getLocation('America/New_York');

        final beforeEnd = DateTime.utc(2025, 11, 2, 5, 0, 0);
        final localBefore = HeliumDateTime.toLocal(beforeEnd, nyTz);
        expect(localBefore.hour, equals(1)); // 1:00 AM EDT

        final afterEnd = DateTime.utc(2025, 11, 2, 7, 0, 0);
        final localAfter = HeliumDateTime.toLocal(afterEnd, nyTz);
        expect(localAfter.hour, equals(2)); // 2:00 AM EST
      });

      test('handles fractional hour timezone (Asia/Kolkata UTC+5:30)', () {
        final kolkataTz = tz.getLocation('Asia/Kolkata');
        final utc = DateTime.utc(2025, 6, 15, 12, 0, 0);
        final local = HeliumDateTime.toLocal(utc, kolkataTz);

        expect(local.hour, equals(17)); // 12:00 UTC + 5:30 = 17:30 IST
        expect(local.minute, equals(30));
      });

      test('handles quarter-hour timezone (Asia/Kathmandu UTC+5:45)', () {
        final kathmanduTz = tz.getLocation('Asia/Kathmandu');
        final utc = DateTime.utc(2025, 6, 15, 12, 0, 0);
        final local = HeliumDateTime.toLocal(utc, kathmanduTz);

        expect(local.hour, equals(17)); // 12:00 UTC + 5:45 = 17:45 NPT
        expect(local.minute, equals(45));
      });

      test('preserves microseconds through conversion', () {
        final nyTz = tz.getLocation('America/New_York');
        final utc = DateTime.utc(2025, 6, 15, 12, 30, 45, 123, 456);
        final local = HeliumDateTime.toLocal(utc, nyTz);

        expect(local.second, equals(45));
        expect(local.millisecond, equals(123));
        expect(local.microsecond, equals(456));
      });

      test('year boundary - UTC midnight Dec 31 in positive offset', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utcNewYearsEve = DateTime.utc(2025, 12, 31, 0, 0, 0);
        final local = HeliumDateTime.toLocal(utcNewYearsEve, tokyoTz);

        expect(local.year, equals(2025)); // Still Dec 31 in Tokyo
        expect(local.month, equals(12));
        expect(local.day, equals(31));
        expect(local.hour, equals(9)); // 9:00 AM Dec 31 in Tokyo
      });

      test('year boundary - UTC 23:00 Dec 31 in positive offset crosses to new year', () {
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utcLateNewYearsEve = DateTime.utc(2025, 12, 31, 23, 0, 0);
        final local = HeliumDateTime.toLocal(utcLateNewYearsEve, tokyoTz);

        expect(local.year, equals(2026)); // New Year in Tokyo
        expect(local.month, equals(1));
        expect(local.day, equals(1));
        expect(local.hour, equals(8)); // 8:00 AM Jan 1 in Tokyo
      });
    });

    group('isoWeekNumber', () {
      test('numbers weeks from the first Thursday of the year', () {
        expect(HeliumDateTime.isoWeekNumber(DateTime(2026, 1, 1)), equals(1));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2021, 1, 4)), equals(1));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2023, 1, 1)), equals(52));
      });

      test('carries the trailing week into the previous year', () {
        expect(HeliumDateTime.isoWeekNumber(DateTime(2021, 1, 1)), equals(53));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2021, 1, 3)), equals(53));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2016, 1, 3)), equals(53));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2000, 1, 1)), equals(52));
      });

      test('rolls the final days into week one of the next year', () {
        expect(HeliumDateTime.isoWeekNumber(DateTime(2019, 12, 30)), equals(1));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2024, 12, 30)), equals(1));
      });

      test('reaches week 53 only in long years', () {
        expect(HeliumDateTime.isoWeekNumber(DateTime(2020, 12, 28)), equals(53));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2015, 12, 28)), equals(53));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2026, 12, 31)), equals(53));
      });

      test('counts whole days across a daylight saving transition', () {
        expect(HeliumDateTime.isoWeekNumber(DateTime(2026, 8, 31)), equals(36));
        expect(HeliumDateTime.isoWeekNumber(DateTime(2026, 9, 21)), equals(39));
      });
    });
  });

  group('unresolved UTC instants', () {
    final storedInstant = DateTime.parse('2025-09-03T22:00:00Z');

    test('midnightIn resolves before truncating', () {
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      final losAngeles = tz.getLocation('America/Los_Angeles');
      expect(HeliumDateTime.midnightIn(storedInstant, amsterdam),
          tz.TZDateTime(amsterdam, 2025, 9, 4));
      expect(
        HeliumDateTime.midnightIn(
            DateTime.parse('2025-01-15T08:00:00Z'), losAngeles),
        tz.TZDateTime(losAngeles, 2025, 1, 15),
      );
    });

    test('wallClockIn reads a naive value as already in the zone', () {
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      expect(
        HeliumDateTime.wallClockIn(DateTime(2025, 9, 18, 9, 0), amsterdam),
        tz.TZDateTime(amsterdam, 2025, 9, 18, 9, 0),
      );
      expect(
        HeliumDateTime.wallClockIn(storedInstant, amsterdam),
        tz.TZDateTime(amsterdam, 2025, 9, 4),
      );
    });

  });

  group('occursWithin', () {
    late tz.Location chicago;
    late tz.TZDateTime rangeStart;
    late tz.TZDateTime rangeEnd;

    setUp(() {
      chicago = tz.getLocation('America/Chicago');
      rangeStart = tz.TZDateTime(chicago, 2026, 11, 1);
      rangeEnd = tz.TZDateTime(chicago, 2026, 11, 2);
    });

    test('counts an item due at the very start of the range', () {
      // WHEN
      final within = HeliumDateTime.occursWithin(rangeStart, rangeStart, rangeStart, rangeEnd);

      // THEN
      expect(within, isTrue);
    });

    test('leaves out an item that ends as the range starts', () {
      // GIVEN
      final start = tz.TZDateTime(chicago, 2026, 10, 31, 23);

      // WHEN
      final within = HeliumDateTime.occursWithin(start, rangeStart, rangeStart, rangeEnd);

      // THEN
      expect(within, isFalse);
    });

    test('leaves out an item that starts as the range ends', () {
      // WHEN
      final within = HeliumDateTime.occursWithin(rangeEnd, rangeEnd, rangeStart, rangeEnd);

      // THEN
      expect(within, isFalse);
    });

    test('counts an item spanning the whole range', () {
      // GIVEN
      final start = tz.TZDateTime(chicago, 2026, 10, 30);
      final end = tz.TZDateTime(chicago, 2026, 11, 3);

      // WHEN
      final within = HeliumDateTime.occursWithin(start, end, rangeStart, rangeEnd);

      // THEN
      expect(within, isTrue);
    });
  });

  group('lastDayOf', () {
    test('an all-day item ends on the day before its exclusive end', () {
      // GIVEN
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      final exclusiveEnd = tz.TZDateTime(amsterdam, 2026, 11, 21);

      // WHEN
      final lastDay = HeliumDateTime.lastDayOf(exclusiveEnd, allDay: true);

      // THEN
      expect(lastDay, DateTime(2026, 11, 20));
    });

    test('a timed item ends on the day its end falls on', () {
      // GIVEN
      final la = tz.getLocation('America/Los_Angeles');
      final end = tz.TZDateTime(la, 2026, 11, 20, 15);

      // WHEN
      final lastDay = HeliumDateTime.lastDayOf(end, allDay: false);

      // THEN
      expect(lastDay, DateTime(2026, 11, 20));
    });
  });

  group('recurrenceRuleWithLocalUntil', () {
    test('reads a UTC UNTIL as wall clock in the account zone (positive offset)', () {
      // GIVEN
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      const rule = 'FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20261211T225959Z';

      // WHEN
      final localized = HeliumDateTime.recurrenceRuleWithLocalUntil(rule, amsterdam);

      // THEN
      expect(localized, 'FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20261211T235959');
    });

    test('reads a UTC UNTIL as wall clock in the account zone (negative offset)', () {
      // GIVEN
      final la = tz.getLocation('America/Los_Angeles');
      const rule = 'FREQ=WEEKLY;UNTIL=20261212T075959Z;BYDAY=FR';

      // WHEN
      final localized = HeliumDateTime.recurrenceRuleWithLocalUntil(rule, la);

      // THEN
      expect(localized, 'FREQ=WEEKLY;UNTIL=20261211T235959;BYDAY=FR');
    });

    test('leaves a rule without a UTC UNTIL alone', () {
      // GIVEN
      final la = tz.getLocation('America/Los_Angeles');

      // WHEN
      final counted = HeliumDateTime.recurrenceRuleWithLocalUntil('FREQ=DAILY;COUNT=5', la);
      final dateOnly = HeliumDateTime.recurrenceRuleWithLocalUntil('FREQ=DAILY;UNTIL=20261211', la);

      // THEN
      expect(counted, 'FREQ=DAILY;COUNT=5');
      expect(dateOnly, 'FREQ=DAILY;UNTIL=20261211');
    });
  });

  group('HeliumRecurrence', () {
    late tz.Location amsterdam;
    late tz.Location losAngeles;
    late tz.TZDateTime mondayStart;

    setUp(() {
      amsterdam = tz.getLocation('Europe/Amsterdam');
      losAngeles = tz.getLocation('America/Los_Angeles');
      mondayStart = tz.TZDateTime(amsterdam, 2026, 9, 7, 9);
    });

    group('compose', () {
      test('returns null for a draft that does not repeat', () {
        // WHEN
        final rule = HeliumRecurrence.compose(const RecurrenceDraft(), mondayStart, amsterdam);

        // THEN
        expect(rule, isNull);
      });

      test('emits frequency alone, adding INTERVAL only when it is above 1', () {
        // WHEN
        final daily = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.daily), mondayStart, amsterdam);
        final everyOtherDay = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.daily, interval: 2), mondayStart, amsterdam);

        // THEN
        expect(daily, 'FREQ=DAILY');
        expect(everyOtherDay, 'FREQ=DAILY;INTERVAL=2');
      });

      test('weekly emits weekdays sorted Sunday-first as iCal codes', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {6, 3, 0, 1}),
          mondayStart,
          amsterdam,
        );

        // THEN
        expect(rule, 'FREQ=WEEKLY;BYDAY=SU,MO,WE,SA');
      });

      test('weekly with no weekdays repeats on the start weekday', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.weekly), mondayStart, amsterdam);

        // THEN
        expect(rule, 'FREQ=WEEKLY;BYDAY=MO');
      });

      test('monthly anchors on the start day, ignoring last day of month before the 29th', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
          const RecurrenceDraft(frequency: RecurrenceFrequency.monthly, lastDayOfMonth: true),
          mondayStart,
          amsterdam,
        );

        // THEN
        expect(rule, 'FREQ=MONTHLY;BYMONTHDAY=7');
      });

      test('monthly on the 31st emits -1 only when last day of month is checked', () {
        // GIVEN
        final start = tz.TZDateTime(amsterdam, 2026, 10, 31, 9);

        // WHEN
        final lastDay = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.monthly, lastDayOfMonth: true), start, amsterdam);
        final thirtyFirst = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.monthly), start, amsterdam);

        // THEN
        expect(lastDay, 'FREQ=MONTHLY;BYMONTHDAY=-1');
        expect(thirtyFirst, 'FREQ=MONTHLY;BYMONTHDAY=31');
      });

      test('yearly anchors on the start month and day', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
            const RecurrenceDraft(frequency: RecurrenceFrequency.yearly), mondayStart, amsterdam);

        // THEN
        expect(rule, 'FREQ=YEARLY;BYMONTH=9;BYMONTHDAY=7');
      });

      test('ending after a count emits COUNT', () {
        // WHEN
        final rule = HeliumRecurrence.compose(
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1}, end: RecurrenceEnd.afterCount, count: 10),
          mondayStart,
          amsterdam,
        );

        // THEN
        expect(rule, 'FREQ=WEEKLY;BYDAY=MO;COUNT=10');
      });

      test('ending on a date emits the end of that local day in UTC, per time zone', () {
        // GIVEN
        final draft = RecurrenceDraft(
          frequency: RecurrenceFrequency.daily,
          end: RecurrenceEnd.onDate,
          until: DateTime(2026, 12, 18),
        );

        // WHEN
        final inAmsterdam = HeliumRecurrence.compose(draft, mondayStart, amsterdam);
        final inLosAngeles = HeliumRecurrence.compose(
            draft, tz.TZDateTime(losAngeles, 2026, 9, 7, 9), losAngeles);

        // THEN
        expect(inAmsterdam, 'FREQ=DAILY;UNTIL=20261218T225959Z');
        expect(inLosAngeles, 'FREQ=DAILY;UNTIL=20261219T075959Z');
      });
    });

    group('parse', () {
      test('round-trips every draft the picker composes', () {
        // GIVEN
        final drafts = [
          const RecurrenceDraft(frequency: RecurrenceFrequency.daily),
          const RecurrenceDraft(frequency: RecurrenceFrequency.daily, interval: 3),
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1, 3, 5}),
          const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, interval: 2, weekdays: {1}),
          const RecurrenceDraft(frequency: RecurrenceFrequency.monthly),
          const RecurrenceDraft(frequency: RecurrenceFrequency.yearly),
          const RecurrenceDraft(
              frequency: RecurrenceFrequency.weekly, weekdays: {1}, end: RecurrenceEnd.afterCount, count: 12),
          RecurrenceDraft(
              frequency: RecurrenceFrequency.weekly,
              weekdays: const {1},
              end: RecurrenceEnd.onDate,
              until: DateTime(2026, 12, 18)),
        ];

        for (final location in [amsterdam, losAngeles]) {
          final start = tz.TZDateTime(location, 2026, 9, 7, 9);
          for (final draft in drafts) {
            // WHEN
            final rule = HeliumRecurrence.compose(draft, start, location);
            final parsed = HeliumRecurrence.parse(rule, start, location);

            // THEN
            expect(parsed, draft, reason: '$rule in ${location.name}');
          }
        }
      });

      test('round-trips last day of month from a start on the 31st', () {
        // GIVEN
        final start = tz.TZDateTime(losAngeles, 2026, 10, 31, 9);
        const draft = RecurrenceDraft(frequency: RecurrenceFrequency.monthly, lastDayOfMonth: true);

        // WHEN
        final parsed = HeliumRecurrence.parse(HeliumRecurrence.compose(draft, start, losAngeles), start, losAngeles);

        // THEN
        expect(parsed, draft);
      });

      test('returns a non-repeating draft for no rule', () {
        // WHEN
        final fromNull = HeliumRecurrence.parse(null, mondayStart, amsterdam);
        final fromEmpty = HeliumRecurrence.parse('', mondayStart, amsterdam);

        // THEN
        expect(fromNull, const RecurrenceDraft());
        expect(fromEmpty, const RecurrenceDraft());
      });

      test('accepts the forms the API normalizes rules into', () {
        // WHEN
        final weekly = HeliumRecurrence.parse('FREQ=WEEKLY', mondayStart, amsterdam);
        final prefixed = HeliumRecurrence.parse('RRULE:FREQ=MONTHLY;BYMONTHDAY=7', mondayStart, amsterdam);
        final monthlyBare = HeliumRecurrence.parse('FREQ=MONTHLY', mondayStart, amsterdam);
        final lowercase = HeliumRecurrence.parse('freq=yearly;bymonth=9;bymonthday=7', mondayStart, amsterdam);

        // THEN
        expect(weekly, const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1}),
            reason: 'a weekly rule without BYDAY repeats on the start weekday');
        expect(prefixed, const RecurrenceDraft(frequency: RecurrenceFrequency.monthly));
        expect(monthlyBare, const RecurrenceDraft(frequency: RecurrenceFrequency.monthly));
        expect(lowercase, const RecurrenceDraft(frequency: RecurrenceFrequency.yearly));
      });

      test('returns null for rules the picker cannot represent', () {
        // GIVEN
        const unrepresentable = [
          'FREQ=MONTHLY;BYDAY=TU;BYSETPOS=2',
          'FREQ=WEEKLY;BYDAY=2TU',
          'FREQ=MONTHLY;BYMONTHDAY=1,15',
          'FREQ=MONTHLY;BYMONTHDAY=8',
          'FREQ=YEARLY;BYMONTH=10;BYMONTHDAY=7',
          'FREQ=DAILY;BYDAY=MO',
          'FREQ=WEEKLY;COUNT=3;UNTIL=20261218',
          'FREQ=HOURLY',
          'FREQ=WEEKLY;UNTIL=tomorrow',
          'FREQ=WEEKLY;INTERVAL=0',
          'FREQ=WEEKLY;WKST=MO',
        ];

        for (final rule in unrepresentable) {
          // WHEN
          final parsed = HeliumRecurrence.parse(rule, mondayStart, amsterdam);

          // THEN
          expect(parsed, isNull, reason: rule);
        }
      });

      test('reads a UTC UNTIL as the local date it falls on in each time zone', () {
        // GIVEN
        const rule = 'FREQ=DAILY;UNTIL=20261219T065959Z';

        // WHEN
        final inLosAngeles = HeliumRecurrence.parse(rule, tz.TZDateTime(losAngeles, 2026, 9, 7, 9), losAngeles);
        final inAmsterdam = HeliumRecurrence.parse(rule, mondayStart, amsterdam);

        // THEN
        expect(inLosAngeles?.until, DateTime(2026, 12, 18));
        expect(inAmsterdam?.until, DateTime(2026, 12, 19));
        expect(inAmsterdam?.end, RecurrenceEnd.onDate);
      });

      test('reads a naive or date-only UNTIL as that date', () {
        // WHEN
        final naive = HeliumRecurrence.parse('FREQ=DAILY;UNTIL=20261218T235959', mondayStart, amsterdam);
        final dateOnly = HeliumRecurrence.parse('FREQ=DAILY;UNTIL=20261218', mondayStart, losAngeles);

        // THEN
        expect(naive?.until, DateTime(2026, 12, 18));
        expect(dateOnly?.until, DateTime(2026, 12, 18));
      });

      test('reads an UNTIL at the end of the class end date in each time zone as the default end', () {
        // GIVEN
        final classEndDate = DateTime(2026, 12, 18);

        // WHEN
        final inLosAngeles = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261219T075959Z',
          tz.TZDateTime(losAngeles, 2026, 9, 7, 9),
          losAngeles,
          classEndDate: classEndDate,
        );
        final inAmsterdam = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261218T225959Z',
          mondayStart,
          amsterdam,
          classEndDate: classEndDate,
        );

        // THEN
        expect(inLosAngeles?.end, RecurrenceEnd.defaultEnd);
        expect(inLosAngeles?.until, isNull);
        expect(inAmsterdam?.end, RecurrenceEnd.defaultEnd);
        expect(inAmsterdam?.until, isNull);
      });

      test('reads an UNTIL other than the end of the class end date as an end date', () {
        // GIVEN
        final classEndDate = DateTime(2026, 12, 18);

        // WHEN
        final otherZonesClassEnd = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261219T075959Z',
          mondayStart,
          amsterdam,
          classEndDate: classEndDate,
        );
        final dayBeforeClassEnd = HeliumRecurrence.parse(
          'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261218T075959Z',
          tz.TZDateTime(losAngeles, 2026, 9, 7, 9),
          losAngeles,
          classEndDate: classEndDate,
        );

        // THEN
        expect(otherZonesClassEnd?.end, RecurrenceEnd.onDate);
        expect(otherZonesClassEnd?.until, DateTime(2026, 12, 19));
        expect(dayBeforeClassEnd?.end, RecurrenceEnd.onDate);
        expect(dayBeforeClassEnd?.until, DateTime(2026, 12, 17));
      });

      test('round-trips a default-end assignment repeat bounded to its class end date', () {
        // GIVEN
        final classEndDate = DateTime(2026, 12, 18);
        final draft = HeliumRecurrence.defaultFor(RecurrenceFrequency.weekly, mondayStart);
        final rule = HeliumRecurrence.compose(
          draft.copyWith(end: RecurrenceEnd.onDate, until: classEndDate),
          mondayStart,
          amsterdam,
        );

        // WHEN
        final parsed = HeliumRecurrence.parse(rule, mondayStart, amsterdam, classEndDate: classEndDate);

        // THEN
        expect(parsed, draft);
      });
    });

    test('offers last day of month only for a start on the 29th or later', () {
      // WHEN/THEN
      expect(HeliumRecurrence.offersLastDayOfMonth(DateTime(2026, 1, 28)), isFalse);
      expect(HeliumRecurrence.offersLastDayOfMonth(DateTime(2026, 1, 29)), isTrue);
      expect(HeliumRecurrence.offersLastDayOfMonth(DateTime(2026, 1, 31)), isTrue);
    });

    test('defaultFor repeats once per period on the start weekday with no end', () {
      // WHEN
      final draft = HeliumRecurrence.defaultFor(RecurrenceFrequency.weekly, mondayStart);

      // THEN
      expect(draft, const RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1}));
    });
  });

  group('RecurrenceDraft', () {
    test('is equal regardless of weekday order, with a matching hashCode', () {
      // GIVEN
      const first = RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1, 3});
      const second = RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {3, 1});

      // THEN
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('differs when any field differs', () {
      // GIVEN
      const base = RecurrenceDraft(frequency: RecurrenceFrequency.weekly, weekdays: {1});

      // THEN
      expect(base, isNot(base.copyWith(interval: 2)));
      expect(base, isNot(base.copyWith(weekdays: {1, 2})));
      expect(base, isNot(base.copyWith(end: RecurrenceEnd.afterCount, count: 3)));
      expect(base, isNot(base.copyWith(frequency: RecurrenceFrequency.daily)));
    });
  });
}
