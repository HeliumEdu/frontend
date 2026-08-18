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

      test('returns empty list when schedule has no recurrence groups', () {
        // GIVEN - a schedule the backend produced no groups for
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [givenCourseScheduleJson(id: 1, recurrenceGroups: [])],
          ),
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

      test('hydrates one event per recurrence group, passing fields through', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 42,
            title: 'CS 101',
            color: '#FF5722',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [
                  givenRecurrenceGroupJson(
                    start: '2025-08-25T09:00:00Z',
                    end: '2025-08-25T10:30:00Z',
                    recurrenceRule:
                        'FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20251215T235959Z',
                  ),
                ],
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
        final event = events[0];
        expect(event.title, equals('CS 101'));
        expect(event.ownerId, equals('42'));
        expect(event.color!.toARGB32(), equals(const Color(0xFFFF5722).toARGB32()));
        expect(event.start, equals(DateTime.utc(2025, 8, 25, 9, 0)));
        expect(event.end, equals(DateTime.utc(2025, 8, 25, 10, 30)));
        expect(
          event.recurrenceRule,
          equals('FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20251215T235959Z'),
        );
        expect(event.allDay, isFalse);
        expect(event.showEndTime, isTrue);
        expect(event.comments, equals(''));
        expect(event.attachments, isEmpty);
        expect(event.reminders, isEmpty);
      });

      test('emits one event per group when a schedule has multiple groups', () {
        // GIVEN - backend split a schedule into two time-slot groups
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [
                  givenRecurrenceGroupJson(
                    start: '2025-08-25T09:00:00Z',
                    end: '2025-08-25T10:00:00Z',
                    recurrenceRule:
                        'FREQ=WEEKLY;BYDAY=MO,FR;UNTIL=20251215T235959Z',
                  ),
                  givenRecurrenceGroupJson(
                    start: '2025-08-27T14:00:00Z',
                    end: '2025-08-27T15:30:00Z',
                    recurrenceRule:
                        'FREQ=WEEKLY;BYDAY=WE;UNTIL=20251215T235959Z',
                  ),
                ],
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
        expect(events.length, equals(2));
        expect(events[0].start, equals(DateTime.utc(2025, 8, 25, 9, 0)));
        expect(events[0].recurrenceRule, contains('BYDAY=MO,FR'));
        expect(events[1].start, equals(DateTime.utc(2025, 8, 27, 14, 0)));
        expect(events[1].recurrenceRule, contains('BYDAY=WE'));
      });

      test('emits events across multiple schedules on a course', () {
        // GIVEN - lecture + lab, each its own schedule/group
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [
                  givenRecurrenceGroupJson(start: '2025-08-25T09:00:00Z'),
                ],
              ),
              givenCourseScheduleJson(
                id: 2,
                recurrenceGroups: [
                  givenRecurrenceGroupJson(start: '2025-08-27T14:00:00Z'),
                ],
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
        expect(events.length, equals(2));
      });

      test('skips courses whose date range is outside the query window', () {
        // GIVEN - course is in Fall 2025
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [givenRecurrenceGroupJson()],
              ),
            ],
          ),
        );

        // WHEN - query Spring 2025
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course],
          from: DateTime(2025, 1, 1),
          to: DateTime(2025, 5, 31),
        );

        // THEN
        expect(events, isEmpty);
      });

      test('passes exception dates through from the group verbatim', () {
        // GIVEN - the backend already merged and resolved these
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [
                  givenRecurrenceGroupJson(
                    exceptionDates: const [
                      '2025-11-03T09:00:00Z',
                      '2025-11-10T09:00:00Z',
                    ],
                  ),
                ],
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
        expect(
          events[0].exceptionDates,
          equals([
            DateTime.utc(2025, 11, 3, 9, 0),
            DateTime.utc(2025, 11, 10, 9, 0),
          ]),
        );
      });

      test('event has empty exceptionDates when the group has none', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [givenRecurrenceGroupJson()],
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
        expect(events[0].exceptionDates, isEmpty);
      });

      test('filters by search query (case insensitive)', () {
        // GIVEN
        final course1 = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Introduction to Computer Science',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [givenRecurrenceGroupJson()],
              ),
            ],
          ),
        );
        final course2 = CourseModel.fromJson(
          givenCourseJson(
            id: 2,
            title: 'Calculus I',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 2,
                recurrenceGroups: [givenRecurrenceGroupJson()],
              ),
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course1, course2],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
          search: 'computer',
        );

        // THEN
        expect(events.length, equals(1));
        expect(events[0].title, equals('Introduction to Computer Science'));
      });

      test('empty search returns all events', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [givenRecurrenceGroupJson()],
              ),
            ],
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

      test('sorts events by start time', () {
        // GIVEN - afternoon course listed first
        final course1 = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'Afternoon Class',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 1,
                recurrenceGroups: [
                  givenRecurrenceGroupJson(start: '2025-08-25T14:00:00Z'),
                ],
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
                recurrenceGroups: [
                  givenRecurrenceGroupJson(start: '2025-08-25T09:00:00Z'),
                ],
              ),
            ],
          ),
        );

        // WHEN
        final events = builderSource.buildCourseScheduleEvents(
          courses: [course1, course2],
          from: DateTime(2025, 8, 25),
          to: DateTime(2025, 8, 31),
        );

        // THEN
        expect(events.length, equals(2));
        expect(events[0].title, equals('Morning Class'));
        expect(events[1].title, equals('Afternoon Class'));
      });

      test('generates stable event IDs across builds', () {
        // GIVEN
        final course = CourseModel.fromJson(
          givenCourseJson(
            id: 1,
            title: 'CS 101',
            startDate: '2025-08-25',
            endDate: '2025-12-15',
            schedules: [
              givenCourseScheduleJson(
                id: 7,
                recurrenceGroups: [
                  givenRecurrenceGroupJson(),
                  givenRecurrenceGroupJson(start: '2025-08-27T14:00:00Z'),
                ],
              ),
            ],
          ),
        );

        // WHEN
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

        // THEN - stable and distinct per group
        expect(events1[0].id, equals(events2[0].id));
        expect(events1[1].id, equals(events2[1].id));
        expect(events1[0].id, isNot(equals(events1[1].id)));
      });
    });
  });
}
