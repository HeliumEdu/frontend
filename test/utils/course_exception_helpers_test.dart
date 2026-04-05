// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/course_exception_helpers.dart';

void main() {
  group('CourseExceptionHelpers', () {
    group('parseCsvExceptions', () {
      test('returns empty list for empty string', () {
        // WHEN
        final result = CourseExceptionHelpers.parseCsvExceptions('');

        // THEN
        expect(result, isEmpty);
      });

      test('returns empty list for whitespace-only string', () {
        // WHEN
        final result = CourseExceptionHelpers.parseCsvExceptions('   ');

        // THEN
        expect(result, isEmpty);
      });

      test('parses a single YYYYMMDD date', () {
        // WHEN
        final result = CourseExceptionHelpers.parseCsvExceptions('20251107');

        // THEN
        expect(result, equals([DateTime(2025, 11, 7)]));
      });

      test('parses multiple comma-separated dates', () {
        // WHEN
        final result = CourseExceptionHelpers.parseCsvExceptions(
          '20251107,20251128,20260101',
        );

        // THEN
        expect(result, equals([
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 28),
          DateTime(2026, 1, 1),
        ]));
      });

      test('skips entries with wrong length', () {
        // GIVEN - mix of valid and invalid length tokens
        // WHEN
        final result = CourseExceptionHelpers.parseCsvExceptions(
          '20251107,2025110,202511070,20251128',
        );

        // THEN - only the two valid 8-char tokens survive
        expect(result, equals([
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 28),
        ]));
      });

      test('skips entries with non-numeric characters', () {
        // GIVEN
        // WHEN
        final result = CourseExceptionHelpers.parseCsvExceptions(
          '20251107,2025XX07,20251128',
        );

        // THEN
        expect(result, equals([
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 28),
        ]));
      });

      test('preserves original order (does not sort)', () {
        // GIVEN - dates in descending order
        // WHEN
        final result = CourseExceptionHelpers.parseCsvExceptions(
          '20260101,20251128,20251107',
        );

        // THEN - order is preserved as-is from the CSV
        expect(result, equals([
          DateTime(2026, 1, 1),
          DateTime(2025, 11, 28),
          DateTime(2025, 11, 7),
        ]));
      });
    });

    group('formatExceptionsCsv', () {
      test('returns empty string for empty list', () {
        // WHEN
        final result = CourseExceptionHelpers.formatExceptionsCsv([]);

        // THEN
        expect(result, equals(''));
      });

      test('formats a single date as YYYYMMDD', () {
        // WHEN
        final result = CourseExceptionHelpers.formatExceptionsCsv([
          DateTime(2025, 11, 7),
        ]);

        // THEN
        expect(result, equals('20251107'));
      });

      test('formats multiple dates as comma-separated YYYYMMDD', () {
        // WHEN
        final result = CourseExceptionHelpers.formatExceptionsCsv([
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 28),
          DateTime(2026, 1, 1),
        ]);

        // THEN
        expect(result, equals('20251107,20251128,20260101'));
      });

      test('sorts dates ascending before formatting', () {
        // GIVEN - dates in descending order
        // WHEN
        final result = CourseExceptionHelpers.formatExceptionsCsv([
          DateTime(2026, 1, 1),
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 28),
        ]);

        // THEN - output is sorted ascending
        expect(result, equals('20251107,20251128,20260101'));
      });

      test('zero-pads single-digit months and days', () {
        // GIVEN - Jan 5 (month=1, day=5)
        // WHEN
        final result = CourseExceptionHelpers.formatExceptionsCsv([
          DateTime(2026, 1, 5),
        ]);

        // THEN
        expect(result, equals('20260105'));
      });

      test('round-trips with parseCsvExceptions', () {
        // GIVEN
        final dates = [
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 28),
          DateTime(2026, 1, 1),
        ];

        // WHEN
        final csv = CourseExceptionHelpers.formatExceptionsCsv(dates);
        final parsed = CourseExceptionHelpers.parseCsvExceptions(csv);

        // THEN
        expect(parsed, equals(dates));
      });
    });

    group('mergeExceptions', () {
      test('returns empty list when both inputs are empty', () {
        // WHEN
        final result = CourseExceptionHelpers.mergeExceptions([], []);

        // THEN
        expect(result, isEmpty);
      });

      test('returns course exceptions when group exceptions are empty', () {
        // GIVEN
        final courseExceptions = [DateTime(2025, 11, 7), DateTime(2025, 11, 28)];

        // WHEN
        final result = CourseExceptionHelpers.mergeExceptions(
          courseExceptions,
          [],
        );

        // THEN
        expect(result, equals([DateTime(2025, 11, 7), DateTime(2025, 11, 28)]));
      });

      test('returns group exceptions when course exceptions are empty', () {
        // GIVEN
        final groupExceptions = [
          DateTime(2025, 11, 27),
          DateTime(2025, 12, 25),
        ];

        // WHEN
        final result = CourseExceptionHelpers.mergeExceptions([], groupExceptions);

        // THEN
        expect(result, equals([
          DateTime(2025, 11, 27),
          DateTime(2025, 12, 25),
        ]));
      });

      test('combines course and group exceptions without overlap', () {
        // GIVEN
        final courseExceptions = [DateTime(2025, 11, 7)];
        final groupExceptions = [DateTime(2025, 11, 27)];

        // WHEN
        final result = CourseExceptionHelpers.mergeExceptions(
          courseExceptions,
          groupExceptions,
        );

        // THEN
        expect(result, equals([
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 27),
        ]));
      });

      test('deduplicates dates that appear in both lists', () {
        // GIVEN - Thanksgiving appears in both
        final courseExceptions = [
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 27),
        ];
        final groupExceptions = [
          DateTime(2025, 11, 27),
          DateTime(2025, 12, 25),
        ];

        // WHEN
        final result = CourseExceptionHelpers.mergeExceptions(
          courseExceptions,
          groupExceptions,
        );

        // THEN - Nov 27 appears only once
        expect(result, equals([
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 27),
          DateTime(2025, 12, 25),
        ]));
      });

      test('returns sorted result regardless of input order', () {
        // GIVEN - inputs are out of order
        final courseExceptions = [DateTime(2025, 12, 25), DateTime(2025, 11, 7)];
        final groupExceptions = [DateTime(2025, 11, 27)];

        // WHEN
        final result = CourseExceptionHelpers.mergeExceptions(
          courseExceptions,
          groupExceptions,
        );

        // THEN - result is sorted ascending
        expect(result, equals([
          DateTime(2025, 11, 7),
          DateTime(2025, 11, 27),
          DateTime(2025, 12, 25),
        ]));
      });

      test('does not mutate the input lists', () {
        // GIVEN
        final courseExceptions = [DateTime(2025, 12, 25)];
        final groupExceptions = [DateTime(2025, 11, 27)];
        final originalCourse = List<DateTime>.from(courseExceptions);
        final originalGroup = List<DateTime>.from(groupExceptions);

        // WHEN
        CourseExceptionHelpers.mergeExceptions(courseExceptions, groupExceptions);

        // THEN - originals unchanged
        expect(courseExceptions, equals(originalCourse));
        expect(groupExceptions, equals(originalGroup));
      });
    });
  });
}
