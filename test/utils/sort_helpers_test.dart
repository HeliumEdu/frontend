// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_event_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
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

    group('byStartDate', () {
      test('sorts course groups by start date ascending', () {
        final groups = [
          _createCourseGroup(id: 1, startDate: '2025-09-01'),
          _createCourseGroup(id: 2, startDate: '2025-01-15'),
          _createCourseGroup(id: 3, startDate: '2025-06-01'),
        ];

        Sort.byStartDate(groups);

        expect(groups[0].id, 2); // Jan 15
        expect(groups[1].id, 3); // Jun 1
        expect(groups[2].id, 1); // Sep 1
      });
    });

    group('byStartThenTitle', () {
      test('sorts by date first', () {
        final items = [
          _createHomework(id: 1, start: '2025-01-20T10:00:00Z'),
          _createHomework(id: 2, start: '2025-01-10T10:00:00Z'),
          _createHomework(id: 3, start: '2025-01-15T10:00:00Z'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Jan 10
        expect(items[1].id, 3); // Jan 15
        expect(items[2].id, 1); // Jan 20
      });

      test('all-day events appear before timed events when end dates match', () {
        // All-day priority only applies when end dates are the same day
        final items = [
          _createHomework(
            id: 1,
            start: '2025-01-15T10:00:00Z',
            end: '2025-01-15T11:00:00Z',
            allDay: false,
          ),
          _createHomework(
            id: 2,
            start: '2025-01-15T00:00:00Z',
            end: '2025-01-15T00:00:00Z', // Same end date as item 1
            allDay: true,
          ),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // All-day first
        expect(items[1].id, 1); // Timed second
      });

      test('sorts by start time when on same day', () {
        final items = [
          _createHomework(id: 1, start: '2025-01-15T14:00:00Z'),
          _createHomework(id: 2, start: '2025-01-15T09:00:00Z'),
          _createHomework(id: 3, start: '2025-01-15T11:00:00Z'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // 9am
        expect(items[1].id, 3); // 11am
        expect(items[2].id, 1); // 2pm
      });

      test('type priority: homework before event at same time', () {
        final items = [
          _createEvent(id: 1, start: '2025-01-15T10:00:00Z'),
          _createHomework(id: 2, start: '2025-01-15T10:00:00Z'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Homework first (priority 0)
        expect(items[1].id, 1); // Event second (priority 2)
      });

      test('type priority: homework before course schedule at same time', () {
        final items = [
          _createCourseScheduleEvent(id: 1, start: '2025-01-15T10:00:00Z'),
          _createHomework(id: 2, start: '2025-01-15T10:00:00Z'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Homework first (priority 0)
        expect(items[1].id, 1); // CourseSchedule second (priority 1)
      });

      test('type priority: course schedule before event at same time', () {
        final items = [
          _createEvent(id: 1, start: '2025-01-15T10:00:00Z'),
          _createCourseScheduleEvent(id: 2, start: '2025-01-15T10:00:00Z'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // CourseSchedule first (priority 1)
        expect(items[1].id, 1); // Event second (priority 2)
      });

      test('type priority: event before external at same time', () {
        final items = [
          _createExternalEvent(id: 1, start: '2025-01-15T10:00:00Z'),
          _createEvent(id: 2, start: '2025-01-15T10:00:00Z'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Event first (priority 2)
        expect(items[1].id, 1); // External second (priority 3)
      });

      test('full priority order: homework → schedule → event → external', () {
        final items = [
          _createExternalEvent(id: 1, start: '2025-01-15T10:00:00Z'),
          _createEvent(id: 2, start: '2025-01-15T10:00:00Z'),
          _createCourseScheduleEvent(id: 3, start: '2025-01-15T10:00:00Z'),
          _createHomework(id: 4, start: '2025-01-15T10:00:00Z'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 4); // Homework (priority 0)
        expect(items[1].id, 3); // CourseSchedule (priority 1)
        expect(items[2].id, 2); // Event (priority 2)
        expect(items[3].id, 1); // External (priority 3)
      });

      test('shorter duration items appear first when same start, different end date', () {
        final items = [
          _createHomework(
            id: 1,
            start: '2025-01-15T10:00:00Z',
            end: '2025-01-17T10:00:00Z', // 2 days
          ),
          _createHomework(
            id: 2,
            start: '2025-01-15T10:00:00Z',
            end: '2025-01-16T10:00:00Z', // 1 day
          ),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Shorter duration first
        expect(items[1].id, 1); // Longer duration second
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

CourseGroupModel _createCourseGroup({
  required int id,
  required String startDate,
}) {
  return CourseGroupModel(
    id: id,
    title: 'Course Group $id',
    shownOnCalendar: true,
    startDate: startDate,
    endDate: '2025-12-31',
    averageGrade: null,
  );
}

HomeworkModel _createHomework({
  required int id,
  String start = '2025-01-15T10:00:00Z',
  String end = '2025-01-15T11:00:00Z',
  bool allDay = false,
}) {
  return HomeworkModel(
    id: id,
    title: 'Homework $id',
    allDay: allDay,
    showEndTime: true,
    start: start,
    end: end,
    priority: 50,
    comments: '',
    attachments: [],
    reminders: [],
    completed: false,
    currentGrade: '-1/100',
    course: IdOrEntity<CourseModel>(id: 1),
    category: IdOrEntity<CategoryModel>(id: 1),
    materials: [],
  );
}

EventModel _createEvent({
  required int id,
  String start = '2025-01-15T10:00:00Z',
  String end = '2025-01-15T11:00:00Z',
  bool allDay = false,
}) {
  return EventModel(
    id: id,
    title: 'Event $id',
    allDay: allDay,
    showEndTime: true,
    start: start,
    end: end,
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    color: const Color(0xFF4CAF50),
  );
}

CourseScheduleEventModel _createCourseScheduleEvent({
  required int id,
  String start = '2025-01-15T10:00:00Z',
  String end = '2025-01-15T11:00:00Z',
}) {
  return CourseScheduleEventModel(
    id: id,
    title: 'Class $id',
    allDay: false,
    showEndTime: true,
    start: start,
    end: end,
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    ownerId: '1',
    color: const Color(0xFFFF5722),
  );
}

ExternalCalendarEventModel _createExternalEvent({
  required int id,
  String start = '2025-01-15T10:00:00Z',
  String end = '2025-01-15T11:00:00Z',
}) {
  return ExternalCalendarEventModel(
    id: id,
    title: 'External $id',
    allDay: false,
    showEndTime: true,
    start: start,
    end: end,
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    ownerId: '1',
    color: const Color(0xFF9C27B0),
  );
}
