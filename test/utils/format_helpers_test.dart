// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/format_helpers.dart';

void main() {
  group('Format', () {
    group('percentForDisplay', () {
      test('formats whole number percentage without decimals', () {
        expect(Format.percentForDisplay('85', null), '85%');
      });

      test('formats decimal percentage with necessary precision', () {
        expect(Format.percentForDisplay('85.5', null), '85.5%');
      });

      test('formats percentage removing trailing zeros', () {
        expect(Format.percentForDisplay('85.50', null), '85.5%');
      });

      test('formats percentage with two decimal places', () {
        expect(Format.percentForDisplay('85.75', null), '85.75%');
      });

      test('returns N/A for zero when zeroAsNa is true', () {
        expect(Format.percentForDisplay('0', true), 'N/A');
      });

      test('returns 0% for zero when zeroAsNa is false', () {
        expect(Format.percentForDisplay('0', false), '0%');
      });

      test('returns 0% for zero when zeroAsNa is null', () {
        expect(Format.percentForDisplay('0', null), '0%');
      });

      test('returns N/A for invalid input', () {
        expect(Format.percentForDisplay('invalid', null), 'N/A');
      });

      test('returns N/A for empty string', () {
        expect(Format.percentForDisplay('', null), 'N/A');
      });

      test('handles 100% correctly', () {
        expect(Format.percentForDisplay('100', null), '100%');
      });

      test('handles very small decimals', () {
        expect(Format.percentForDisplay('0.01', null), '0.01%');
      });
    });

    group('gradeForDisplay', () {
      test('formats numeric grade as percentage', () {
        expect(Format.gradeForDisplay(85.5), '85.50%');
      });

      test('formats fraction string grade as percentage', () {
        expect(Format.gradeForDisplay('85/100'), '85.00%');
      });

      test('formats non-100 denominator fraction correctly', () {
        expect(Format.gradeForDisplay('17/20'), '85.00%');
      });

      test('returns N/A for null grade', () {
        expect(Format.gradeForDisplay(null), 'N/A');
      });

      test('returns N/A for empty string grade', () {
        expect(Format.gradeForDisplay(''), 'N/A');
      });

      test('returns N/A for -1/100 grade', () {
        expect(Format.gradeForDisplay('-1/100'), 'N/A');
      });

      test('returns N/A for 0 grade', () {
        expect(Format.gradeForDisplay(0), 'N/A');
      });

      test('returns N/A for -1.0 grade', () {
        expect(Format.gradeForDisplay(-1.0), 'N/A');
      });

      test('returns empty string for null when showNaAsBlank is true', () {
        expect(Format.gradeForDisplay(null, true), '');
      });

      test('returns empty string for -1/100 when showNaAsBlank is true', () {
        expect(Format.gradeForDisplay('-1/100', true), '');
      });

      test('formats 100% correctly', () {
        expect(Format.gradeForDisplay(100.0), '100.00%');
      });

      test('formats perfect fraction score correctly', () {
        expect(Format.gradeForDisplay('20/20'), '100.00%');
      });
    });

    group('reminderOffset', () {
      test('formats singular minute offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 0);
        expect(Format.reminderOffset(reminder), '1 minute');
      });

      test('formats plural minutes offset', () {
        final reminder = _createReminder(offset: 15, offsetType: 0);
        expect(Format.reminderOffset(reminder), '15 minutes');
      });

      test('formats singular hour offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 1);
        expect(Format.reminderOffset(reminder), '1 hour');
      });

      test('formats plural hours offset', () {
        final reminder = _createReminder(offset: 2, offsetType: 1);
        expect(Format.reminderOffset(reminder), '2 hours');
      });

      test('formats singular day offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 2);
        expect(Format.reminderOffset(reminder), '1 day');
      });

      test('formats plural days offset', () {
        final reminder = _createReminder(offset: 3, offsetType: 2);
        expect(Format.reminderOffset(reminder), '3 days');
      });

      test('formats singular week offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 3);
        expect(Format.reminderOffset(reminder), '1 week');
      });

      test('formats plural weeks offset', () {
        final reminder = _createReminder(offset: 2, offsetType: 3);
        expect(Format.reminderOffset(reminder), '2 weeks');
      });
    });
  });

  group('PluralExtension', () {
    test('returns plural for 0', () {
      expect(0.plural('item'), 'items');
    });

    test('returns singular for 1', () {
      expect(1.plural('item'), 'item');
    });

    test('returns plural for 2', () {
      expect(2.plural('item'), 'items');
    });

    test('returns plural for large numbers', () {
      expect(100.plural('item'), 'items');
    });

    test('uses custom plural suffix', () {
      expect(2.plural('box', 'es'), 'boxes');
    });

    test('uses custom plural suffix for singular', () {
      expect(1.plural('box', 'es'), 'box');
    });
  });
}

ReminderModel _createReminder({
  required int offset,
  required int offsetType,
}) {
  return ReminderModel(
    id: 1,
    title: 'Test Reminder',
    message: 'Test message',
    startOfRange: '2025-01-01T10:00:00Z',
    offset: offset,
    offsetType: offsetType,
    type: 0,
    sent: false,
    dismissed: false,
  );
}
