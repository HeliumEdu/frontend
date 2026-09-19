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
  });
}
