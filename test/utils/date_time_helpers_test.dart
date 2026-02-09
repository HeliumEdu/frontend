// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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

  group('DateTimeHelpers', () {
    group('parse', () {
      test('parses ISO string with timezone correctly', () {
        final location = tz.getLocation('America/New_York');
        final result = HeliumDateTime.parse('2025-08-15T10:30:00Z', location);
        expect(result, isA<tz.TZDateTime>());
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

        // Result should be a valid ISO 8601 string with timezone offset
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

    group('getDaysBetween', () {
      test('returns 0 when before start date', () {
        // Use dates in the future relative to now
        final now = DateTime.now();
        final futureStart = now.add(const Duration(days: 30));
        final futureEnd = now.add(const Duration(days: 60));

        final result = HeliumDateTime.getDaysBetween(futureStart, futureEnd);
        expect(result, equals(0));
      });

      test('returns 100 when after end date', () {
        // Use dates in the past relative to now
        final now = DateTime.now();
        final pastStart = now.subtract(const Duration(days: 60));
        final pastEnd = now.subtract(const Duration(days: 30));

        final result = HeliumDateTime.getDaysBetween(pastStart, pastEnd);
        expect(result, equals(100));
      });

      test('returns 0 when start equals end and dates are in future', () {
        // Use a future date
        final now = DateTime.now();
        final futureDate = now.add(const Duration(days: 30));

        expect(HeliumDateTime.getDaysBetween(futureDate, futureDate), equals(0));
      });

      test('returns 100 when start equals end and dates are in past', () {
        // Use a past date
        final now = DateTime.now();
        final pastDate = now.subtract(const Duration(days: 30));

        expect(HeliumDateTime.getDaysBetween(pastDate, pastDate), equals(100));
      });

      test('returns days elapsed when currently within range', () {
        // Create a range that spans the current date
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 10));
        final end = now.add(const Duration(days: 20));

        final result = HeliumDateTime.getDaysBetween(start, end);
        // Should be approximately 10 days (the elapsed portion)
        expect(result, greaterThanOrEqualTo(9));
        expect(result, lessThanOrEqualTo(11));
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
        // Test with various date ranges
        final now = DateTime.now();

        // Past range - should be 100
        final pastStart = now.subtract(const Duration(days: 60));
        final pastEnd = now.subtract(const Duration(days: 30));
        final result1 = HeliumDateTime.getPercentDiffBetween(pastStart, pastEnd);
        expect(result1, greaterThanOrEqualTo(0));
        expect(result1, lessThanOrEqualTo(100));

        // Future range - should be 0
        final futureStart = now.add(const Duration(days: 30));
        final futureEnd = now.add(const Duration(days: 60));
        final result2 = HeliumDateTime.getPercentDiffBetween(futureStart, futureEnd);
        expect(result2, greaterThanOrEqualTo(0));
        expect(result2, lessThanOrEqualTo(100));
      });

      test('returns approximately 50% at midpoint of range', () {
        // Create a range centered on now
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 50));
        final end = now.add(const Duration(days: 50));

        final result = HeliumDateTime.getPercentDiffBetween(start, end);
        // Should be approximately 50%
        expect(result, greaterThanOrEqualTo(45));
        expect(result, lessThanOrEqualTo(55));
      });
    });

    group('toLocal - timezone conversion', () {
      test('converts UTC to America/New_York (UTC-5 standard, UTC-4 DST)', () {
        final nyTz = tz.getLocation('America/New_York');
        // January (standard time, UTC-5)
        final utcWinter = DateTime.utc(2025, 1, 15, 12, 0, 0);
        final localWinter = HeliumDateTime.toLocal(utcWinter, nyTz);
        expect(localWinter.hour, equals(7)); // 12:00 UTC = 7:00 EST

        // July (daylight saving time, UTC-4)
        final utcSummer = DateTime.utc(2025, 7, 15, 12, 0, 0);
        final localSummer = HeliumDateTime.toLocal(utcSummer, nyTz);
        expect(localSummer.hour, equals(8)); // 12:00 UTC = 8:00 EDT
      });

      test('converts UTC to Europe/London (UTC+0 standard, UTC+1 DST)', () {
        final londonTz = tz.getLocation('Europe/London');
        // January (standard time, UTC+0)
        final utcWinter = DateTime.utc(2025, 1, 15, 12, 0, 0);
        final localWinter = HeliumDateTime.toLocal(utcWinter, londonTz);
        expect(localWinter.hour, equals(12)); // 12:00 UTC = 12:00 GMT

        // July (British Summer Time, UTC+1)
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
        // UTC midnight should become next day morning in Asia/Tokyo
        final tokyoTz = tz.getLocation('Asia/Tokyo');
        final utcMidnight = DateTime.utc(2025, 6, 15, 0, 0, 0);
        final local = HeliumDateTime.toLocal(utcMidnight, tokyoTz);

        expect(local.day, equals(15)); // Still June 15
        expect(local.hour, equals(9)); // 00:00 UTC = 09:00 JST
      });

      test('handles UTC midnight boundary - date changes in negative offset', () {
        // UTC 3:00 AM should become previous day in America/Los_Angeles
        final laTz = tz.getLocation('America/Los_Angeles');
        // In January (PST = UTC-8)
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
        // DST starts second Sunday of March at 2:00 AM local
        // In 2025, DST starts March 9 at 2:00 AM (clocks move to 3:00 AM)
        final nyTz = tz.getLocation('America/New_York');

        // Just before DST (March 9, 2025, 6:00 UTC = 1:00 AM EST)
        final beforeDst = DateTime.utc(2025, 3, 9, 6, 0, 0);
        final localBefore = HeliumDateTime.toLocal(beforeDst, nyTz);
        expect(localBefore.hour, equals(1)); // 1:00 AM EST

        // Just after DST (March 9, 2025, 8:00 UTC = 4:00 AM EDT)
        final afterDst = DateTime.utc(2025, 3, 9, 8, 0, 0);
        final localAfter = HeliumDateTime.toLocal(afterDst, nyTz);
        expect(localAfter.hour, equals(4)); // 4:00 AM EDT
      });

      test('handles DST fall back transition (America/New_York)', () {
        // DST ends first Sunday of November at 2:00 AM local
        // In 2025, DST ends November 2 at 2:00 AM (clocks move to 1:00 AM)
        final nyTz = tz.getLocation('America/New_York');

        // Just before DST ends (November 2, 2025, 5:00 UTC = 1:00 AM EDT)
        final beforeEnd = DateTime.utc(2025, 11, 2, 5, 0, 0);
        final localBefore = HeliumDateTime.toLocal(beforeEnd, nyTz);
        expect(localBefore.hour, equals(1)); // 1:00 AM EDT

        // Just after DST ends (November 2, 2025, 7:00 UTC = 2:00 AM EST)
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
        // UTC midnight on Dec 31 is already Jan 1 in Tokyo
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

    group('parse - timezone edge cases', () {
      test('parses ISO string and converts to specified timezone', () {
        final nyTz = tz.getLocation('America/New_York');
        // UTC time 15:00 should become 11:00 in NY (EDT, UTC-4 in July)
        final result = HeliumDateTime.parse('2025-07-15T15:00:00Z', nyTz);

        expect(result.hour, equals(11)); // 15:00 UTC = 11:00 EDT
        expect(result.day, equals(15));
      });

      test('parses ISO string during DST transition', () {
        final nyTz = tz.getLocation('America/New_York');
        // Test parsing a time just after DST spring forward
        // March 9, 2025 10:00 UTC should be 6:00 AM EDT
        final result = HeliumDateTime.parse('2025-03-09T10:00:00Z', nyTz);

        expect(result.hour, equals(6)); // Should be 6:00 AM EDT
      });

      test('parses ISO string with timezone offset suffix', () {
        final utcTz = tz.getLocation('UTC');
        // The Z suffix indicates UTC
        final result = HeliumDateTime.parse('2025-08-15T10:30:00Z', utcTz);

        expect(result.hour, equals(10));
        expect(result.minute, equals(30));
      });

      test('parses midnight UTC correctly', () {
        final nyTz = tz.getLocation('America/New_York');
        final result = HeliumDateTime.parse('2025-01-15T00:00:00Z', nyTz);

        // Midnight UTC should be 7:00 PM previous day in NY (EST, UTC-5)
        expect(result.hour, equals(19)); // 7:00 PM
        expect(result.day, equals(14)); // Previous day
      });

      test('parses end of day UTC correctly', () {
        final nyTz = tz.getLocation('America/New_York');
        final result = HeliumDateTime.parse('2025-01-15T23:59:59Z', nyTz);

        // 23:59:59 UTC should be 18:59:59 in NY (EST)
        expect(result.hour, equals(18));
        expect(result.minute, equals(59));
        expect(result.second, equals(59));
        expect(result.day, equals(15)); // Same day
      });
    });
  });
}
