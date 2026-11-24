import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('DateRangeEnforcer.followStart', () {
    test('moving a timed item keeps its length, across midnight', () {
      // WHEN
      final end = DateRangeEnforcer.followStart(
        previousStartDate: DateTime(2027, 5, 31),
        previousStartTime: const TimeOfDay(hour: 23, minute: 30),
        startDate: DateTime(2027, 6, 2),
        startTime: const TimeOfDay(hour: 23, minute: 30),
        endDate: DateTime(2027, 6, 1),
        endTime: const TimeOfDay(hour: 0, minute: 30),
      );

      // THEN
      expect(end.date, DateTime(2027, 6, 3));
      expect(end.time, const TimeOfDay(hour: 0, minute: 30));
    });

    test('moving the start earlier keeps the length', () {
      // WHEN
      final end = DateRangeEnforcer.followStart(
        previousStartDate: DateTime(2026, 11, 13),
        previousStartTime: const TimeOfDay(hour: 14, minute: 0),
        startDate: DateTime(2026, 11, 13),
        startTime: const TimeOfDay(hour: 9, minute: 15),
        endDate: DateTime(2026, 11, 13),
        endTime: const TimeOfDay(hour: 15, minute: 30),
      );

      // THEN
      expect(end.date, DateTime(2026, 11, 13));
      expect(end.time, const TimeOfDay(hour: 10, minute: 45));
    });

    test('moving an all-day item keeps its number of days', () {
      // WHEN
      final end = DateRangeEnforcer.followStart(
        previousStartDate: DateTime(2026, 1, 9),
        previousStartTime: null,
        startDate: DateTime(2026, 5, 30),
        startTime: null,
        endDate: DateTime(2026, 1, 10),
        endTime: null,
      );

      // THEN
      expect(end.date, DateTime(2026, 5, 31));
      expect(end.time, isNull);
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

  group('startOfWeek', () {
    test('a Sunday-start week begins on the Sunday before a Wednesday', () {
      // WHEN
      final start = HeliumDateTime.startOfWeek(DateTime(2026, 11, 18), 0);

      // THEN
      expect(start, DateTime(2026, 11, 15));
    });

    test('a Monday-start week puts Sunday at its end', () {
      // WHEN
      final start = HeliumDateTime.startOfWeek(DateTime(2026, 11, 22), 1);

      // THEN
      expect(start, DateTime(2026, 11, 16));
    });

    test('a day that starts the week is its own start', () {
      // WHEN
      final start = HeliumDateTime.startOfWeek(DateTime(2026, 11, 21), 6);

      // THEN
      expect(start, DateTime(2026, 11, 21), reason: 'Nov 21, 2026 is a Saturday');
    });

    test('a week can start in the previous month', () {
      // WHEN
      final start = HeliumDateTime.startOfWeek(DateTime(2026, 12, 2), 0);

      // THEN
      expect(start, DateTime(2026, 11, 29));
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

  group('weekOfTerm', () {
    final termStart = DateTime(2026, 8, 31);

    test('a positive-offset zone counts by its own date, not the UTC date', () {
      // GIVEN
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      final now = DateTime.utc(2026, 9, 6, 23, 30);

      // WHEN
      final week = HeliumDateTime.weekOfTerm(termStart, now, amsterdam);

      // THEN
      expect(week, 1, reason: 'It is already 7 Sep in Amsterdam, a week after the start');
    });

    test('a negative-offset zone still counts the day before', () {
      // GIVEN
      final losAngeles = tz.getLocation('America/Los_Angeles');
      final now = DateTime.utc(2026, 9, 7, 6, 30);

      // WHEN
      final week = HeliumDateTime.weekOfTerm(termStart, now, losAngeles);

      // THEN
      expect(week, 0, reason: 'It is still 6 Sep in Los Angeles');
    });

    test('a week holding a daylight saving change is still seven days', () {
      // GIVEN
      final amsterdam = tz.getLocation('Europe/Amsterdam');
      final now = tz.TZDateTime(amsterdam, 2026, 10, 26, 0, 30);

      // WHEN
      final week = HeliumDateTime.weekOfTerm(DateTime(2026, 10, 19), now, amsterdam);

      // THEN
      expect(week, 1, reason: 'The 25-hour day of 25 Oct must not push 26 Oct back into week 0');
    });

    test('days before the term count as negative weeks', () {
      // GIVEN
      final losAngeles = tz.getLocation('America/Los_Angeles');
      final now = tz.TZDateTime(losAngeles, 2026, 8, 30, 12);

      // WHEN
      final week = HeliumDateTime.weekOfTerm(termStart, now, losAngeles);

      // THEN
      expect(week, -1);
    });
  });
}
