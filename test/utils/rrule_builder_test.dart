// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/rrule_builder.dart';

void main() {
  group('RRuleBuilder', () {
    group('dayIndexToCode', () {
      test('maps day indices to iCalendar codes correctly', () {
        expect(RRuleBuilder.dayIndexToCode[0], equals('SU'));
        expect(RRuleBuilder.dayIndexToCode[1], equals('MO'));
        expect(RRuleBuilder.dayIndexToCode[2], equals('TU'));
        expect(RRuleBuilder.dayIndexToCode[3], equals('WE'));
        expect(RRuleBuilder.dayIndexToCode[4], equals('TH'));
        expect(RRuleBuilder.dayIndexToCode[5], equals('FR'));
        expect(RRuleBuilder.dayIndexToCode[6], equals('SA'));
      });
    });

    group('buildWeeklyRecurrence', () {
      test('builds correct RRULE for single day', () {
        // WHEN
        final rrule = RRuleBuilder.buildWeeklyRecurrence(
          dayIndices: [1], // Monday
          until: DateTime(2025, 12, 15),
        );

        // THEN
        expect(rrule, contains('FREQ=WEEKLY'));
        expect(rrule, contains('BYDAY=MO'));
        expect(rrule, contains('UNTIL=20251215T235959Z'));
      });

      test('builds correct RRULE for MWF schedule', () {
        // WHEN
        final rrule = RRuleBuilder.buildWeeklyRecurrence(
          dayIndices: [1, 3, 5], // Mon, Wed, Fri
          until: DateTime(2025, 12, 15),
        );

        // THEN
        expect(rrule, equals('FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20251215T235959Z'));
      });

      test('builds correct RRULE for TTh schedule', () {
        // WHEN
        final rrule = RRuleBuilder.buildWeeklyRecurrence(
          dayIndices: [2, 4], // Tue, Thu
          until: DateTime(2025, 12, 15),
        );

        // THEN
        expect(rrule, contains('BYDAY=TU,TH'));
      });

      test('builds correct RRULE for weekend schedule', () {
        // WHEN
        final rrule = RRuleBuilder.buildWeeklyRecurrence(
          dayIndices: [0, 6], // Sun, Sat
          until: DateTime(2025, 12, 15),
        );

        // THEN
        expect(rrule, contains('BYDAY=SU,SA'));
      });

      test('builds correct RRULE for every day', () {
        // WHEN
        final rrule = RRuleBuilder.buildWeeklyRecurrence(
          dayIndices: [0, 1, 2, 3, 4, 5, 6],
          until: DateTime(2025, 12, 15),
        );

        // THEN
        expect(rrule, contains('BYDAY=SU,MO,TU,WE,TH,FR,SA'));
      });

      test('formats UNTIL date correctly with padding', () {
        // WHEN - Single digit month and day
        final rrule = RRuleBuilder.buildWeeklyRecurrence(
          dayIndices: [1],
          until: DateTime(2025, 1, 5),
        );

        // THEN
        expect(rrule, contains('UNTIL=20250105T235959Z'));
      });

      test('throws ArgumentError for empty dayIndices', () {
        // THEN
        expect(
          () => RRuleBuilder.buildWeeklyRecurrence(
            dayIndices: [],
            until: DateTime(2025, 12, 15),
          ),
          throwsArgumentError,
        );
      });

      test('ignores invalid day indices', () {
        // WHEN - Include invalid indices (7 and -1)
        final rrule = RRuleBuilder.buildWeeklyRecurrence(
          dayIndices: [1, 7, -1, 3], // Only 1 and 3 are valid
          until: DateTime(2025, 12, 15),
        );

        // THEN - Should only include valid days
        expect(rrule, contains('BYDAY=MO,WE'));
        expect(rrule, isNot(contains('null')));
      });

      test('throws ArgumentError when all day indices are invalid', () {
        // THEN
        expect(
          () => RRuleBuilder.buildWeeklyRecurrence(
            dayIndices: [7, 8, -1], // All invalid
            until: DateTime(2025, 12, 15),
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
