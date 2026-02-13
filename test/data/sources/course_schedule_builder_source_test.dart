// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/sources/course_schedule_builder_source.dart';

import '../../helpers/planner_helper.dart';

void main() {
  late CourseScheduleBuilderSource builderSource;

  setUp(() {
    builderSource = CourseScheduleBuilderSource();
  });

  group('CourseScheduleBuilderSource', () {
    group('buildCourseScheduleEvents', () {
      test('returns empty list when courses is empty', () {
        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events, isEmpty);
      });

      test('returns empty list when course has no schedules', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(id: 1, title: 'CS 101', schedules: []),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events, isEmpty);
      });

      test('generates one recurring event for MWF schedule with same times', () {
        // GIVEN - MWF schedule (daysOfWeek: '0101010') with same times
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0101010',
                // Mon, Wed, Fri
                monStartTime: '09:00:00',
                monEndTime: '10:30:00',
                wedStartTime: '09:00:00',
                wedEndTime: '10:30:00',
                friStartTime: '09:00:00',
                friEndTime: '10:30:00',
              ),
            ],
          ),
        );

        // WHEN - Week of Aug 25-31, 2025 (Mon-Sun)
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25), // Monday
          to: DateTime(2025, 8, 31), // Sunday
        );

        // THEN - Should have 1 recurring event (all days have same time)
        expect(events.length, equals(1));

        // Verify the event starts on Monday (first occurrence)
        expect(events[0].start, equals(DateTime(2025, 8, 25, 9, 0)));
        expect(events[0].end, equals(DateTime(2025, 8, 25, 10, 30)));

        // Verify recurrence rule
        expect(events[0].recurrenceRule, isNotNull);
        expect(events[0].recurrenceRule, contains('FREQ=WEEKLY'));
        expect(events[0].recurrenceRule, contains('BYDAY=MO,WE,FR'));
        expect(events[0].recurrenceRule, contains('UNTIL='));
      });

      test('generates one recurring event for Tuesday/Thursday schedule', () {
        // GIVEN - TTh schedule (daysOfWeek: '0010100')
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Math 201',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0010100',
                // Tue, Thu
                tueStartTime: '14:00:00',
                tueEndTime: '15:30:00',
                thuStartTime: '14:00:00',
                thuEndTime: '15:30:00',
              ),
            ],
          ),
        );

        // WHEN - Week of Aug 25-31, 2025
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Should have 1 recurring event
        expect(events.length, equals(1));

        // Verify the event starts on Tuesday (first occurrence)
        expect(events[0].start, equals(DateTime(2025, 8, 26, 14, 0)));
        expect(events[0].end, equals(DateTime(2025, 8, 26, 15, 30)));

        // Verify recurrence rule
        expect(events[0].recurrenceRule, contains('BYDAY=TU,TH'));
      });

      test('recurring event starts on first occurrence based on course start date', () {
        // GIVEN - Course starts on Wednesday Aug 27
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-27',
            // Wednesday
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0101010', // Mon, Wed, Fri
              ),
            ],
          ),
        );

        // WHEN - Query from Monday Aug 25
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Should have 1 recurring event starting on Wednesday (first occurrence)
        expect(events.length, equals(1));
        expect(events[0].start.weekday, equals(DateTime.wednesday));
        // RRULE should extend to course end date, not query end date
        expect(events[0].recurrenceRule, contains('UNTIL=20251215'));
      });

      test('RRULE UNTIL uses course end date regardless of query range', () {
        // GIVEN - Course ends on Wednesday Aug 27
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-08-27',
            // Wednesday
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0101010', // Mon, Wed, Fri
              ),
            ],
          ),
        );

        // WHEN - Query extends beyond course end date
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - RRULE UNTIL should be course end date, not query end date
        expect(events.length, equals(1));
        expect(events[0].recurrenceRule, contains('UNTIL=20250827'));
      });

      test('returns same recurring event when querying different months', () {
        // GIVEN - Course spans multiple months
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0101010', // Mon, Wed, Fri
              ),
            ],
          ),
        );

        // WHEN - Query August
        final augustEvents = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 8, 31),
        );

        // WHEN - Query September
        final septemberEvents = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 9, 1),
          to: DateTime(2025, 9, 30),
        );

        // THEN - Both should return the SAME recurring event
        // (same ID, same start date, same RRULE)
        expect(augustEvents.length, equals(1));
        expect(septemberEvents.length, equals(1));
        expect(augustEvents[0].id, equals(septemberEvents[0].id));
        expect(augustEvents[0].start, equals(septemberEvents[0].start));
        expect(augustEvents[0].recurrenceRule, equals(septemberEvents[0].recurrenceRule));
        // Start should be first Monday of course, not September
        expect(augustEvents[0].start, equals(DateTime(2025, 8, 25, 9, 0)));
      });

      test('returns empty when query range is outside course dates', () {
        // GIVEN - Course is in Fall 2025
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0101010')],
          ),
        );

        // WHEN - Query Spring 2025
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 1, 1),
          to: DateTime(2025, 5, 31),
        );

        // THEN
        expect(events, isEmpty);
      });

      test('generates events with correct course title', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Introduction to Computer Science',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(id: 1, daysOfWeek: '0100000'), // Mon only
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events.length, equals(1));
        expect(events[0].title, equals('Introduction to Computer Science'));
      });

      test('generates events with correct ownerId', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 42,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0100000')],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - ownerId is now just the course ID
        expect(events[0].ownerId, equals('42'));
      });

      test('generates events with course color', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            color: '#FF5722',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0100000')],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events[0].color, isNotNull);
        // Color should be the parsed hex value
        expect(
          events[0].color!.toARGB32(),
          equals(const Color(0xFFFF5722).toARGB32()),
        );
      });

      test('handles multiple courses', () {
        // GIVEN
        final course1 = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(id: 1, daysOfWeek: '0100000'), // Mon
            ],
          ),
        );
        final course2 = CourseModel.fromJson(
          givenCourseJson(
            id: 2,
            title: 'Math 201',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(id: 2, daysOfWeek: '0010000'), // Tue
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course1, course2],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Should have 2 recurring events sorted by start time
        expect(events.length, equals(2));
        expect(events[0].title, equals('CS 101')); // Monday first
        expect(events[1].title, equals('Math 201')); // Tuesday second
      });

      test('handles course with multiple schedules', () {
        // GIVEN - A course with lecture and lab
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0100000', // Mon lecture
                monStartTime: '09:00:00',
                monEndTime: '10:30:00',
              ),
              givenCourseScheduleJson(
                id: 2,
                daysOfWeek: '0001000', // Wed lab
                wedStartTime: '14:00:00',
                wedEndTime: '16:00:00',
              ),
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Should have 2 recurring events
        expect(events.length, equals(2));
        expect(events[0].start, equals(DateTime(2025, 8, 25, 9, 0))); // Mon
        expect(events[1].start, equals(DateTime(2025, 8, 27, 14, 0))); // Wed
      });

      test('filters by search query (case insensitive)', () {
        // GIVEN
        final course1 = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Introduction to Computer Science',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0100000')],
          ),
        );
        final course2 = CourseModel.fromJson(
          givenCourseJson(
            id: 2,
            title: 'Calculus I',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 2, daysOfWeek: '0010000')],
          ),
        );

        // WHEN - Search for "computer"
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course1, course2],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
          search: 'computer',
        );

        // THEN - Should only return CS course
        expect(events.length, equals(1));
        expect(events[0].title, equals('Introduction to Computer Science'));
      });

      test('search with empty string returns all events', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0100000')],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
          search: '',
        );

        // THEN
        expect(events.length, equals(1));
      });

      test('generates multiple recurring events for different per-day times', () {
        // GIVEN - Different times for different days
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0110000',
                // Mon, Tue
                monStartTime: '09:00:00',
                monEndTime: '10:00:00',
                tueStartTime: '14:00:00',
                tueEndTime: '15:30:00',
              ),
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Should have 2 recurring events (different time slots)
        expect(events.length, equals(2));

        // Monday slot - 9:00-10:00
        expect(events[0].start.hour, equals(9));
        expect(events[0].end.hour, equals(10));
        expect(events[0].recurrenceRule, contains('BYDAY=MO'));

        // Tuesday slot - 14:00-15:30
        expect(events[1].start.hour, equals(14));
        expect(events[1].end.hour, equals(15));
        expect(events[1].end.minute, equals(30));
        expect(events[1].recurrenceRule, contains('BYDAY=TU'));
      });

      test('generates deterministic event IDs', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0100000')],
          ),
        );

        // WHEN - Generate events twice
        final events1 = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );
        final events2 = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Same IDs
        expect(events1[0].id, equals(events2[0].id));
      });

      test('handles Sunday schedule correctly', () {
        // GIVEN - Sunday schedule (daysOfWeek: '1000000')
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Sunday Class',
            startDate: '2025-08-24',
            // Sunday
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '1000000', // Sunday only
                sunStartTime: '10:00:00',
                sunEndTime: '12:00:00',
              ),
            ],
          ),
        );

        // WHEN - Week starting Sunday Aug 24
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 24), // Sunday
          to: DateTime(2025, 8, 30), // Saturday
        );

        // THEN
        expect(events.length, equals(1));
        expect(events[0].start, equals(DateTime(2025, 8, 24, 10, 0)));
        expect(events[0].start.weekday, equals(DateTime.sunday));
        expect(events[0].recurrenceRule, contains('BYDAY=SU'));
      });

      test('handles Saturday schedule correctly', () {
        // GIVEN - Saturday schedule (daysOfWeek: '0000001')
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Saturday Class',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0000001', // Saturday only
                satStartTime: '09:00:00',
                satEndTime: '12:00:00',
              ),
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events.length, equals(1));
        expect(events[0].start, equals(DateTime(2025, 8, 30, 9, 0)));
        expect(events[0].start.weekday, equals(DateTime.saturday));
        expect(events[0].recurrenceRule, contains('BYDAY=SA'));
      });

      test('events are sorted by start time', () {
        // GIVEN - Multiple courses on same day at different times
        final course1 = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Afternoon Class',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0100000',
                monStartTime: '14:00:00',
                monEndTime: '15:00:00',
              ),
            ],
          ),
        );
        final course2 = CourseModel.fromJson(
          givenCourseJson(
            id: 2,
            title: 'Morning Class',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 2,
                daysOfWeek: '0100000',
                monStartTime: '09:00:00',
                monEndTime: '10:00:00',
              ),
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course1, course2], // Afternoon course added first
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Morning class should be first
        expect(events.length, equals(2));
        expect(events[0].title, equals('Morning Class'));
        expect(events[1].title, equals('Afternoon Class'));
      });

      test('returns events with allDay=false and showEndTime=true', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0100000')],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events[0].allDay, isFalse);
        expect(events[0].showEndTime, isTrue);
      });

      test('returns events with empty comments and attachments', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, daysOfWeek: '0100000')],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events[0].comments, equals(''));
        expect(events[0].attachments, isEmpty);
        expect(events[0].reminders, isEmpty);
      });

      test('groups days with same time into single recurring event', () {
        // GIVEN - MWF with same time, then MF same time but W different
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                daysOfWeek: '0101010', // Mon, Wed, Fri
                monStartTime: '09:00:00',
                monEndTime: '10:30:00',
                wedStartTime: '14:00:00', // Different!
                wedEndTime: '15:30:00',
                friStartTime: '09:00:00', // Same as Mon
                friEndTime: '10:30:00',
              ),
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN - Should have 2 recurring events (MF at 9am, W at 2pm)
        expect(events.length, equals(2));

        // Find the MF event and W event
        final mfEvent = events.firstWhere(
          (e) => e.start.hour == 9,
        );
        final wEvent = events.firstWhere(
          (e) => e.start.hour == 14,
        );

        expect(mfEvent.recurrenceRule, contains('BYDAY=MO,FR'));
        expect(wEvent.recurrenceRule, contains('BYDAY=WE'));
      });
    });
  });
}
