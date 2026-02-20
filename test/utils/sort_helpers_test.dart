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
import 'package:heliumapp/utils/planner_helper.dart';
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
          _createReminder(id: 1, startOfRange: DateTime.parse('2025-01-01T10:00:00Z')),
          _createReminder(id: 2, startOfRange: DateTime.parse('2025-01-15T10:00:00Z')),
          _createReminder(id: 3, startOfRange: DateTime.parse('2025-01-10T10:00:00Z')),
        ];

        Sort.byStartOfRange(reminders, timeZone);

        expect(reminders[0].id, 2); // Jan 15 (newest)
        expect(reminders[1].id, 3); // Jan 10
        expect(reminders[2].id, 1); // Jan 1 (oldest)
      });

      test('handles same date reminders', () {
        final timeZone = tz.getLocation('America/New_York');
        final reminders = [
          _createReminder(id: 1, startOfRange: DateTime.parse('2025-01-10T10:00:00Z')),
          _createReminder(id: 2, startOfRange: DateTime.parse('2025-01-10T10:00:00Z')),
        ];

        Sort.byStartOfRange(reminders, timeZone);

        expect(reminders.length, 2);
      });

      test('works with different time zones', () {
        final utcZone = tz.getLocation('UTC');
        final reminders = [
          _createReminder(id: 1, startOfRange: DateTime.parse('2025-01-01T00:00:00Z')),
          _createReminder(id: 2, startOfRange: DateTime.parse('2025-01-02T00:00:00Z')),
        ];

        Sort.byStartOfRange(reminders, utcZone);

        expect(reminders[0].id, 2); // Jan 2 first
        expect(reminders[1].id, 1); // Jan 1 second
      });
    });

    group('byStartDate', () {
      test('sorts course groups by start date ascending', () {
        final groups = [
          _createCourseGroup(id: 1, startDate: DateTime.parse('2025-09-01')),
          _createCourseGroup(id: 2, startDate: DateTime.parse('2025-01-15')),
          _createCourseGroup(id: 3, startDate: DateTime.parse('2025-06-01')),
        ];

        Sort.byStartDate(groups);

        expect(groups[0].id, 2); // Jan 15
        expect(groups[1].id, 3); // Jun 1
        expect(groups[2].id, 1); // Sep 1
      });
    });

    group('getTimedEventStartTimeAdjustmentSeconds', () {
      // The adjustment is subtracted from an item's start time so that SfCalendar
      // positions higher-priority items earlier. The values must stay small enough
      // that the visual position on the calendar grid is not perceptibly shifted.
      // The previous bug used (3 - priority) * 1000 seconds, which pushed homework
      // ~51 minutes early and class schedules ~35 minutes early on the calendar.

      const maxAllowedSeconds = 300; // 5 minutes — well below "visibly wrong" territory

      test('max adjustment across all types and positions is under 5 minutes', () {
        for (final priority in Sort.typeSortPriority.values) {
          for (int position = 0; position < 100; position++) {
            final adjustment = Sort.getTimedEventStartTimeAdjustmentSeconds(
              priority,
              position,
            );
            expect(
              adjustment,
              lessThan(maxAllowedSeconds),
              reason:
                  'priority=$priority, position=$position produced $adjustment seconds '
                  '(${adjustment ~/ 60}m ${adjustment % 60}s), which would visibly '
                  'shift items on the calendar grid',
            );
          }
        }
      });

      test('higher priority types get larger adjustments so they sort earlier', () {
        final homework = Sort.getTimedEventStartTimeAdjustmentSeconds(
          Sort.typeSortPriority[PlannerItemType.homework]!,
          0,
        );
        final schedule = Sort.getTimedEventStartTimeAdjustmentSeconds(
          Sort.typeSortPriority[PlannerItemType.courseSchedule]!,
          0,
        );
        final event = Sort.getTimedEventStartTimeAdjustmentSeconds(
          Sort.typeSortPriority[PlannerItemType.event]!,
          0,
        );
        final external = Sort.getTimedEventStartTimeAdjustmentSeconds(
          Sort.typeSortPriority[PlannerItemType.external]!,
          0,
        );

        expect(homework, greaterThan(schedule));
        expect(schedule, greaterThan(event));
        expect(event, greaterThan(external));
      });

      test('earlier positions get larger adjustments so they sort before later positions', () {
        final priority = Sort.typeSortPriority[PlannerItemType.homework]!;
        final first = Sort.getTimedEventStartTimeAdjustmentSeconds(priority, 0);
        final second = Sort.getTimedEventStartTimeAdjustmentSeconds(priority, 1);
        final third = Sort.getTimedEventStartTimeAdjustmentSeconds(priority, 2);

        expect(first, greaterThan(second));
        expect(second, greaterThan(third));
      });
    });

    group('getTimedEventEndTimeAdjustment', () {
      const maxAllowedSeconds = 300; // 5 minutes

      test('max adjustment across all types and positions is under 5 minutes', () {
        for (final priority in Sort.typeSortPriority.values) {
          for (int position = 0; position < 100; position++) {
            final adjustment = Sort.getTimedEventEndTimeAdjustment(
              priority,
              position,
            );
            expect(
              adjustment.inSeconds,
              lessThan(maxAllowedSeconds),
              reason:
                  'priority=$priority, position=$position produced '
                  '${adjustment.inSeconds}s end-time adjustment, which would '
                  'visibly shorten events on the calendar grid',
            );
          }
        }
      });

      test('higher priority types get larger end time adjustments', () {
        final homework = Sort.getTimedEventEndTimeAdjustment(
          Sort.typeSortPriority[PlannerItemType.homework]!,
          0,
        );
        final schedule = Sort.getTimedEventEndTimeAdjustment(
          Sort.typeSortPriority[PlannerItemType.courseSchedule]!,
          0,
        );
        final event = Sort.getTimedEventEndTimeAdjustment(
          Sort.typeSortPriority[PlannerItemType.event]!,
          0,
        );
        final external = Sort.getTimedEventEndTimeAdjustment(
          Sort.typeSortPriority[PlannerItemType.external]!,
          0,
        );

        expect(homework, greaterThan(schedule));
        expect(schedule, greaterThan(event));
        expect(event, greaterThan(external));
      });
    });

    group('byStartThenTitle', () {
      test('sorts by date first', () {
        final items = [
          _createHomework(id: 1, start: DateTime.parse('2025-01-20T10:00:00Z')),
          _createHomework(id: 2, start: DateTime.parse('2025-01-10T10:00:00Z')),
          _createHomework(id: 3, start: DateTime.parse('2025-01-15T10:00:00Z')),
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
            start: DateTime.parse('2025-01-15T10:00:00Z'),
            end: DateTime.parse('2025-01-15T11:00:00Z'),
            allDay: false,
          ),
          _createHomework(
            id: 2,
            start: DateTime.parse('2025-01-15T00:00:00Z'),
            end: DateTime.parse('2025-01-15T00:00:00Z'), // Same end date as item 1
            allDay: true,
          ),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // All-day first
        expect(items[1].id, 1); // Timed second
      });

      test('sorts by start time when on same day', () {
        final items = [
          _createHomework(id: 1, start: DateTime.parse('2025-01-15T14:00:00Z')),
          _createHomework(id: 2, start: DateTime.parse('2025-01-15T09:00:00Z')),
          _createHomework(id: 3, start: DateTime.parse('2025-01-15T11:00:00Z')),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // 9am
        expect(items[1].id, 3); // 11am
        expect(items[2].id, 1); // 2pm
      });

      test('type priority: homework before event at same time', () {
        final items = [
          _createEvent(id: 1, start: DateTime.parse('2025-01-15T10:00:00Z')),
          _createHomework(id: 2, start: DateTime.parse('2025-01-15T10:00:00Z')),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Homework first (priority 0)
        expect(items[1].id, 1); // Event second (priority 2)
      });

      test('type priority: homework before course schedule at same time', () {
        final items = [
          _createCourseScheduleEvent(id: 1, start: DateTime.parse('2025-01-15T10:00:00Z')),
          _createHomework(id: 2, start: DateTime.parse('2025-01-15T10:00:00Z')),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Homework first (priority 0)
        expect(items[1].id, 1); // CourseSchedule second (priority 1)
      });

      test('type priority: course schedule before event at same time', () {
        final items = [
          _createEvent(id: 1, start: DateTime.parse('2025-01-15T10:00:00Z')),
          _createCourseScheduleEvent(id: 2, start: DateTime.parse('2025-01-15T10:00:00Z')),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // CourseSchedule first (priority 1)
        expect(items[1].id, 1); // Event second (priority 2)
      });

      test('type priority: event before external at same time', () {
        final items = [
          _createExternalEvent(id: 1, start: DateTime.parse('2025-01-15T10:00:00Z')),
          _createEvent(id: 2, start: DateTime.parse('2025-01-15T10:00:00Z')),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Event first (priority 2)
        expect(items[1].id, 1); // External second (priority 3)
      });

      test('full priority order: homework → schedule → event → external', () {
        final items = [
          _createExternalEvent(id: 1, start: DateTime.parse('2025-01-15T10:00:00Z')),
          _createEvent(id: 2, start: DateTime.parse('2025-01-15T10:00:00Z')),
          _createCourseScheduleEvent(id: 3, start: DateTime.parse('2025-01-15T10:00:00Z')),
          _createHomework(id: 4, start: DateTime.parse('2025-01-15T10:00:00Z')),
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
            start: DateTime.parse('2025-01-15T10:00:00Z'),
            end: DateTime.parse('2025-01-17T10:00:00Z'), // 2 days
          ),
          _createHomework(
            id: 2,
            start: DateTime.parse('2025-01-15T10:00:00Z'),
            end: DateTime.parse('2025-01-16T10:00:00Z'), // 1 day
          ),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].id, 2); // Shorter duration first
        expect(items[1].id, 1); // Longer duration second
      });

      test('homework items with same start time are grouped by course', () {
        final sameTime = DateTime.parse('2025-01-15T10:00:00Z');
        final items = [
          _createHomework(id: 1, start: sameTime, courseId: 3, title: 'Assignment'),
          _createHomework(id: 2, start: sameTime, courseId: 1, title: 'Lab'),
          _createHomework(id: 3, start: sameTime, courseId: 2, title: 'Essay'),
          _createHomework(id: 4, start: sameTime, courseId: 1, title: 'Quiz'),
        ];

        Sort.byStartThenTitle(items);

        // Should group by course: 1, 1, 2, 3
        expect(items[0].course.id, 1);
        expect(items[1].course.id, 1);
        expect(items[2].course.id, 2);
        expect(items[3].course.id, 3);
      });

      test('homework items with same start time and course are sorted by title', () {
        final sameTime = DateTime.parse('2025-01-15T10:00:00Z');
        final items = [
          _createHomework(id: 1, start: sameTime, courseId: 1, title: 'Zebra Assignment'),
          _createHomework(id: 2, start: sameTime, courseId: 1, title: 'Apple Quiz'),
          _createHomework(id: 3, start: sameTime, courseId: 1, title: 'Middle Lab'),
        ];

        Sort.byStartThenTitle(items);

        expect(items[0].title, 'Apple Quiz');
        expect(items[1].title, 'Middle Lab');
        expect(items[2].title, 'Zebra Assignment');
      });

      test('sort is stable: items maintain order when re-sorted with identical properties', () {
        final sameTime = DateTime.parse('2025-01-15T10:00:00Z');
        final items = [
          _createHomework(id: 1, start: sameTime, courseId: 1, title: 'Assignment A'),
          _createHomework(id: 2, start: sameTime, courseId: 1, title: 'Assignment B'),
          _createHomework(id: 3, start: sameTime, courseId: 1, title: 'Assignment C'),
        ];

        // Sort once
        Sort.byStartThenTitle(items);
        final firstSortIds = items.map((item) => item.id).toList();

        // Sort again - order should be identical (stable)
        Sort.byStartThenTitle(items);
        final secondSortIds = items.map((item) => item.id).toList();

        expect(secondSortIds, firstSortIds);
      });

      test('non-homework items with same start time and type are sorted by title', () {
        final sameTime = DateTime.parse('2025-01-15T10:00:00Z');
        final items = [
          _createEvent(id: 1, start: sameTime),
          _createEvent(id: 2, start: sameTime),
        ];
        // Manually set titles to test alphabetical sorting
        items[0] = EventModel(
          id: 1,
          title: 'Zebra Event',
          allDay: false,
          showEndTime: true,
          start: sameTime,
          end: sameTime.add(const Duration(hours: 1)),
          priority: 50,
          url: null,
          comments: '',
          attachments: [],
          reminders: [],
          color: const Color(0xFF4CAF50),
        );
        items[1] = EventModel(
          id: 2,
          title: 'Apple Event',
          allDay: false,
          showEndTime: true,
          start: sameTime,
          end: sameTime.add(const Duration(hours: 1)),
          priority: 50,
          url: null,
          comments: '',
          attachments: [],
          reminders: [],
          color: const Color(0xFF4CAF50),
        );

        Sort.byStartThenTitle(items);

        expect(items[0].title, 'Apple Event');
        expect(items[1].title, 'Zebra Event');
      });

      test('course grouping works across multiple courses with title sorting', () {
        final sameTime = DateTime.parse('2025-01-15T10:00:00Z');
        final items = [
          _createHomework(id: 1, start: sameTime, courseId: 2, title: 'Zebra'),
          _createHomework(id: 2, start: sameTime, courseId: 1, title: 'Zebra'),
          _createHomework(id: 3, start: sameTime, courseId: 2, title: 'Apple'),
          _createHomework(id: 4, start: sameTime, courseId: 1, title: 'Apple'),
        ];

        Sort.byStartThenTitle(items);

        // Course 1 items should come first (sorted by title), then course 2 items (sorted by title)
        expect(items[0].course.id, 1);
        expect(items[0].title, 'Apple');
        expect(items[1].course.id, 1);
        expect(items[1].title, 'Zebra');
        expect(items[2].course.id, 2);
        expect(items[2].title, 'Apple');
        expect(items[3].course.id, 2);
        expect(items[3].title, 'Zebra');
      });
    });
  });
}

ReminderModel _createReminder({
  required int id,
  required DateTime startOfRange,
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
  required DateTime startDate,
}) {
  return CourseGroupModel(
    id: id,
    title: 'Course Group $id',
    shownOnCalendar: true,
    startDate: startDate,
    endDate: DateTime.parse('2025-12-31'),
    averageGrade: null,
  );
}

HomeworkModel _createHomework({
  required int id,
  DateTime? start,
  DateTime? end,
  bool allDay = false,
  int courseId = 1,
  String? title,
}) {
  return HomeworkModel(
    id: id,
    title: title ?? 'Homework $id',
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    comments: '',
    attachments: [],
    reminders: [],
    completed: false,
    currentGrade: '-1/100',
    course: IdOrEntity<CourseModel>(id: courseId),
    category: IdOrEntity<CategoryModel>(id: 1),
    resources: [],
  );
}

EventModel _createEvent({
  required int id,
  DateTime? start,
  DateTime? end,
  bool allDay = false,
}) {
  return EventModel(
    id: id,
    title: 'Event $id',
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
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
  DateTime? start,
  DateTime? end,
}) {
  return CourseScheduleEventModel(
    id: id,
    title: 'Class $id',
    allDay: false,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
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
  DateTime? start,
  DateTime? end,
}) {
  return ExternalCalendarEventModel(
    id: id,
    title: 'External $id',
    allDay: false,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: end ?? DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    ownerId: '1',
    color: const Color(0xFF9C27B0),
  );
}
