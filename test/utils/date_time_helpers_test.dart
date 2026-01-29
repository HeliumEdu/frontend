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
        expect(HeliumTime.formatForDisplay(time), equals('9:30 AM'));
      });

      test('formats PM time correctly', () {
        const time = TimeOfDay(hour: 14, minute: 45);
        expect(HeliumTime.formatForDisplay(time), equals('2:45 PM'));
      });

      test('formats noon correctly', () {
        const time = TimeOfDay(hour: 12, minute: 0);
        expect(HeliumTime.formatForDisplay(time), equals('12:00 PM'));
      });

      test('formats midnight correctly', () {
        const time = TimeOfDay(hour: 0, minute: 0);
        expect(HeliumTime.formatForDisplay(time), equals('12:00 AM'));
      });

      test('pads single digit minutes', () {
        const time = TimeOfDay(hour: 10, minute: 5);
        expect(HeliumTime.formatForDisplay(time), equals('10:05 AM'));
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
        expect(HeliumDateTime.formatDateForDisplay(date), equals('Aug 15, 2025'));
      });

      test('formats January date correctly', () {
        final date = DateTime(2025, 1, 1);
        expect(HeliumDateTime.formatDateForDisplay(date), equals('Jan 01, 2025'));
      });

      test('formats December date correctly', () {
        final date = DateTime(2025, 12, 31);
        expect(HeliumDateTime.formatDateForDisplay(date), equals('Dec 31, 2025'));
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
        // Using dates far in the future to ensure we're "before" start
        final result = HeliumDateTime.getDaysBetween(
          '2099-01-01',
          '2099-12-31',
        );
        expect(result, equals(0));
      });

      test('returns 100 when after end date', () {
        // Using dates in the past to ensure we're "after" end
        final result = HeliumDateTime.getDaysBetween(
          '2020-01-01',
          '2020-12-31',
        );
        expect(result, equals(100));
      });

      test('returns 0 for empty start date', () {
        expect(HeliumDateTime.getDaysBetween('', '2025-12-31'), equals(0));
      });

      test('returns 0 for empty end date', () {
        expect(HeliumDateTime.getDaysBetween('2025-01-01', ''), equals(0));
      });

      test('returns 0 when start equals end and dates are in future', () {
        // Using future dates where we're "before" start
        expect(
          HeliumDateTime.getDaysBetween('2099-06-15', '2099-06-15'),
          equals(0),
        );
      });

      test('returns 100 when start equals end and dates are in past', () {
        // Using past dates where we're "after" end
        expect(
          HeliumDateTime.getDaysBetween('2020-06-15', '2020-06-15'),
          equals(100),
        );
      });
    });

    group('getPercentDiffBetween', () {
      test('returns 0 when before start date', () {
        final result = HeliumDateTime.getPercentDiffBetween(
          '2099-01-01',
          '2099-12-31',
        );
        expect(result, equals(0));
      });

      test('returns 100 when after end date', () {
        final result = HeliumDateTime.getPercentDiffBetween(
          '2020-01-01',
          '2020-12-31',
        );
        expect(result, equals(100));
      });

      test('returns 0 for empty start date', () {
        expect(
          HeliumDateTime.getPercentDiffBetween('', '2025-12-31'),
          equals(0),
        );
      });

      test('returns 0 for empty end date', () {
        expect(
          HeliumDateTime.getPercentDiffBetween('2025-01-01', ''),
          equals(0),
        );
      });

      test('returns 0 when before start (even if same dates)', () {
        // For future dates where now is before start
        expect(
          HeliumDateTime.getPercentDiffBetween('2099-06-15', '2099-06-16'),
          equals(0),
        );
      });

      test('returns 100 when after end (even if same dates)', () {
        // For past dates where now is after end
        expect(
          HeliumDateTime.getPercentDiffBetween('2020-06-14', '2020-06-15'),
          equals(100),
        );
      });

      test('result is always between 0 and 100', () {
        // After end date should return 100
        final result = HeliumDateTime.getPercentDiffBetween(
          '2020-01-01',
          '2020-06-30',
        );
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(100));
      });
    });
  });
}
