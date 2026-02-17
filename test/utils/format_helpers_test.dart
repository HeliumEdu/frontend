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

    test('uses custom plural suffix', () {
      expect(2.plural('box', 'es'), 'boxes');
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
    startOfRange: DateTime.parse('2025-01-01T10:00:00Z'),
    offset: offset,
    offsetType: offsetType,
    type: 0,
    sent: false,
    dismissed: false,
  );
}
