// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

import '../mocks/mock_models.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Sort', () {
    group('byTitle', () {
      test('sorts list alphabetically by title', () {
        final courses = [
          MockModels.createCourse(id: 1, title: 'Zebra Studies'),
          MockModels.createCourse(id: 2, title: 'Alpha Course'),
          MockModels.createCourse(id: 3, title: 'Middle Course'),
        ];

        Sort.byTitle(courses);

        expect(courses[0].title, 'Alpha Course');
        expect(courses[1].title, 'Middle Course');
        expect(courses[2].title, 'Zebra Studies');
      });

      test('handles list with duplicate titles', () {
        final courses = [
          MockModels.createCourse(id: 1, title: 'Same Title'),
          MockModels.createCourse(id: 2, title: 'Same Title'),
          MockModels.createCourse(id: 3, title: 'Another Title'),
        ];

        Sort.byTitle(courses);

        expect(courses[0].title, 'Another Title');
        expect(courses[1].title, 'Same Title');
        expect(courses[2].title, 'Same Title');
      });

      test('is case sensitive', () {
        final courses = [
          MockModels.createCourse(id: 1, title: 'banana'),
          MockModels.createCourse(id: 2, title: 'Apple'),
          MockModels.createCourse(id: 3, title: 'cherry'),
        ];

        Sort.byTitle(courses);

        // Uppercase letters come before lowercase in ASCII
        expect(courses[0].title, 'Apple');
        expect(courses[1].title, 'banana');
        expect(courses[2].title, 'cherry');
      });
    });

    group('byStartOfRange', () {
      test('sorts reminders by startOfRange in descending order (newest first)',
          () {
        final timeZone = tz.getLocation('America/New_York');
        final reminders = [
          _createReminder(id: 1, startOfRange: '2025-01-01T10:00:00Z'),
          _createReminder(id: 2, startOfRange: '2025-01-15T10:00:00Z'),
          _createReminder(id: 3, startOfRange: '2025-01-10T10:00:00Z'),
        ];

        Sort.byStartOfRange(reminders, timeZone);

        expect(reminders[0].id, 2); // Jan 15 (newest)
        expect(reminders[1].id, 3); // Jan 10
        expect(reminders[2].id, 1); // Jan 1 (oldest)
      });

      test('handles same date reminders', () {
        final timeZone = tz.getLocation('America/New_York');
        final reminders = [
          _createReminder(id: 1, startOfRange: '2025-01-10T10:00:00Z'),
          _createReminder(id: 2, startOfRange: '2025-01-10T10:00:00Z'),
        ];

        Sort.byStartOfRange(reminders, timeZone);

        expect(reminders.length, 2);
      });

      test('works with different time zones', () {
        final utcZone = tz.getLocation('UTC');
        final reminders = [
          _createReminder(id: 1, startOfRange: '2025-01-01T00:00:00Z'),
          _createReminder(id: 2, startOfRange: '2025-01-02T00:00:00Z'),
        ];

        Sort.byStartOfRange(reminders, utcZone);

        expect(reminders[0].id, 2); // Jan 2 first
        expect(reminders[1].id, 1); // Jan 1 second
      });
    });
  });
}

ReminderModel _createReminder({
  required int id,
  required String startOfRange,
}) {
  return ReminderModel(
    id: id,
    title: 'Reminder $id',
    message: 'Test message',
    startOfRange: startOfRange,
    offset: 15,
    offsetType: 0,
    type: 0,
    sent: false,
    dismissed: false,
  );
}
