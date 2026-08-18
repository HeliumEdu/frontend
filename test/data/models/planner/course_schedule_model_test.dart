import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';

import '../../../helpers/planner_helper.dart';

void main() {
  group('CourseScheduleModel', () {
    group('isDayActive', () {
      test('returns true for active days', () {
        // GIVEN - MWF schedule (daysOfWeek: '0101010')
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0101010'),
        );

        // THEN
        expect(schedule.isDayActive(0), isFalse); // Sun
        expect(schedule.isDayActive(1), isTrue); // Mon
        expect(schedule.isDayActive(2), isFalse); // Tue
        expect(schedule.isDayActive(3), isTrue); // Wed
        expect(schedule.isDayActive(4), isFalse); // Thu
        expect(schedule.isDayActive(5), isTrue); // Fri
        expect(schedule.isDayActive(6), isFalse); // Sat
      });

      test('returns false for all days when no days active', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0000000'),
        );

        // THEN
        for (int i = 0; i < 7; i++) {
          expect(schedule.isDayActive(i), isFalse);
        }
      });

      test('returns true for all days when all days active', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '1111111'),
        );

        // THEN
        for (int i = 0; i < 7; i++) {
          expect(schedule.isDayActive(i), isTrue);
        }
      });

      test('returns false for out-of-bounds indices', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '1111111'),
        );

        // THEN
        expect(schedule.isDayActive(-1), isFalse);
        expect(schedule.isDayActive(7), isFalse);
        expect(schedule.isDayActive(100), isFalse);
      });
    });

    group('getActiveDayIndices', () {
      test('returns correct indices for MWF schedule', () {
        // GIVEN - MWF schedule (daysOfWeek: '0101010')
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0101010'),
        );

        // WHEN
        final indices = schedule.getActiveDayIndices();

        // THEN
        expect(indices, equals({1, 3, 5})); // Mon, Wed, Fri
      });

      test('returns correct indices for TTh schedule', () {
        // GIVEN - TTh schedule (daysOfWeek: '0010100')
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0010100'),
        );

        // WHEN
        final indices = schedule.getActiveDayIndices();

        // THEN
        expect(indices, equals({2, 4})); // Tue, Thu
      });

      test('returns empty set when no days active', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0000000'),
        );

        // WHEN
        final indices = schedule.getActiveDayIndices();

        // THEN
        expect(indices, isEmpty);
      });

      test('returns all indices when all days active', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '1111111'),
        );

        // WHEN
        final indices = schedule.getActiveDayIndices();

        // THEN
        expect(indices, equals({0, 1, 2, 3, 4, 5, 6}));
      });
    });

    group('getStartTimeForDayIndex', () {
      test('returns correct start time for each day index', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(
            sunStartTime: '08:00:00',
            monStartTime: '09:00:00',
            tueStartTime: '10:00:00',
            wedStartTime: '11:00:00',
            thuStartTime: '12:00:00',
            friStartTime: '13:00:00',
            satStartTime: '14:00:00',
          ),
        );

        // THEN
        expect(
          schedule.getStartTimeForDayIndex(0),
          equals(const TimeOfDay(hour: 8, minute: 0)),
        );
        expect(
          schedule.getStartTimeForDayIndex(1),
          equals(const TimeOfDay(hour: 9, minute: 0)),
        );
        expect(
          schedule.getStartTimeForDayIndex(2),
          equals(const TimeOfDay(hour: 10, minute: 0)),
        );
        expect(
          schedule.getStartTimeForDayIndex(3),
          equals(const TimeOfDay(hour: 11, minute: 0)),
        );
        expect(
          schedule.getStartTimeForDayIndex(4),
          equals(const TimeOfDay(hour: 12, minute: 0)),
        );
        expect(
          schedule.getStartTimeForDayIndex(5),
          equals(const TimeOfDay(hour: 13, minute: 0)),
        );
        expect(
          schedule.getStartTimeForDayIndex(6),
          equals(const TimeOfDay(hour: 14, minute: 0)),
        );
      });

      test('returns Sunday start time for invalid index', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(sunStartTime: '08:00:00'),
        );

        // THEN - Default is Sunday for invalid indices
        expect(
          schedule.getStartTimeForDayIndex(-1),
          equals(const TimeOfDay(hour: 8, minute: 0)),
        );
        expect(
          schedule.getStartTimeForDayIndex(7),
          equals(const TimeOfDay(hour: 8, minute: 0)),
        );
      });
    });

    group('getEndTimeForDayIndex', () {
      test('returns correct end time for each day index', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(
            sunEndTime: '09:00:00',
            monEndTime: '10:00:00',
            tueEndTime: '11:00:00',
            wedEndTime: '12:00:00',
            thuEndTime: '13:00:00',
            friEndTime: '14:00:00',
            satEndTime: '15:00:00',
          ),
        );

        // THEN
        expect(
          schedule.getEndTimeForDayIndex(0),
          equals(const TimeOfDay(hour: 9, minute: 0)),
        );
        expect(
          schedule.getEndTimeForDayIndex(1),
          equals(const TimeOfDay(hour: 10, minute: 0)),
        );
        expect(
          schedule.getEndTimeForDayIndex(2),
          equals(const TimeOfDay(hour: 11, minute: 0)),
        );
        expect(
          schedule.getEndTimeForDayIndex(3),
          equals(const TimeOfDay(hour: 12, minute: 0)),
        );
        expect(
          schedule.getEndTimeForDayIndex(4),
          equals(const TimeOfDay(hour: 13, minute: 0)),
        );
        expect(
          schedule.getEndTimeForDayIndex(5),
          equals(const TimeOfDay(hour: 14, minute: 0)),
        );
        expect(
          schedule.getEndTimeForDayIndex(6),
          equals(const TimeOfDay(hour: 15, minute: 0)),
        );
      });

      test('returns Sunday end time for invalid index', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(sunEndTime: '09:30:00'),
        );

        // THEN - Default is Sunday for invalid indices
        expect(
          schedule.getEndTimeForDayIndex(-1),
          equals(const TimeOfDay(hour: 9, minute: 30)),
        );
        expect(
          schedule.getEndTimeForDayIndex(7),
          equals(const TimeOfDay(hour: 9, minute: 30)),
        );
      });
    });

    group('allDaysSameTime', () {
      test('returns true for a uniform schedule with 00:00 off-days', () {
        // GIVEN - MWF at one shared time; Sun/Tue/Thu/Sat inactive at 00:00
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(
            daysOfWeek: '0101010',
            monStartTime: '09:00:00',
            monEndTime: '10:30:00',
            wedStartTime: '09:00:00',
            wedEndTime: '10:30:00',
            friStartTime: '09:00:00',
            friEndTime: '10:30:00',
          ),
        );

        // THEN - off-day 00:00 placeholders are ignored, not read as varying
        expect(schedule.allDaysSameTime(), isTrue);
      });

      test('returns false when active days meet at different times', () {
        // GIVEN - Mon/Wed at 09:00, Fri at 13:00
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(
            daysOfWeek: '0101010',
            monStartTime: '09:00:00',
            monEndTime: '10:30:00',
            wedStartTime: '09:00:00',
            wedEndTime: '10:30:00',
            friStartTime: '13:00:00',
            friEndTime: '14:30:00',
          ),
        );

        // THEN
        expect(schedule.allDaysSameTime(), isFalse);
      });

      test('returns true for a single active day', () {
        // GIVEN - Mon only
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0100000'),
        );

        // THEN
        expect(schedule.allDaysSameTime(), isTrue);
      });

      test('returns true when no days are active', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0000000'),
        );

        // THEN - vacuously uniform
        expect(schedule.allDaysSameTime(), isTrue);
      });
    });

    group('representativeStartTime / representativeEndTime', () {
      test('reads the earliest active day, not a fixed column', () {
        // GIVEN - MWF at 09:00-10:30; Sunday is inactive at 00:00
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(
            daysOfWeek: '0101010',
            sunStartTime: '00:00:00',
            sunEndTime: '00:00:00',
            monStartTime: '09:00:00',
            monEndTime: '10:30:00',
          ),
        );

        // THEN - Monday (first active), never Sunday's 00:00 placeholder
        expect(
          schedule.representativeStartTime,
          equals(const TimeOfDay(hour: 9, minute: 0)),
        );
        expect(
          schedule.representativeEndTime,
          equals(const TimeOfDay(hour: 10, minute: 30)),
        );
      });

      test('reads the first active day when Sunday is inactive on a TTh schedule', () {
        // GIVEN - Tue/Thu at 13:30-15:20
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(
            daysOfWeek: '0010100',
            tueStartTime: '13:30:00',
            tueEndTime: '15:20:00',
            thuStartTime: '13:30:00',
            thuEndTime: '15:20:00',
          ),
        );

        // THEN - Tuesday (first active)
        expect(
          schedule.representativeStartTime,
          equals(const TimeOfDay(hour: 13, minute: 30)),
        );
        expect(
          schedule.representativeEndTime,
          equals(const TimeOfDay(hour: 15, minute: 20)),
        );
      });

      test('returns null when no days are active', () {
        // GIVEN - a day-cycle-style row stores 0000000
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0000000'),
        );

        // THEN
        expect(schedule.representativeStartTime, isNull);
        expect(schedule.representativeEndTime, isNull);
      });
    });

    group('getActiveDays', () {
      test('returns abbreviated day names for active days', () {
        // GIVEN - MWF schedule
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0101010'),
        );

        // WHEN
        final days = schedule.getActiveDays();

        // THEN
        expect(days, equals(['Mon', 'Wed', 'Fri']));
      });

      test('returns empty list when no days active', () {
        // GIVEN
        final schedule = CourseScheduleModel.fromJson(
          givenCourseScheduleJson(daysOfWeek: '0000000'),
        );

        // WHEN
        final days = schedule.getActiveDays();

        // THEN
        expect(days, isEmpty);
      });
    });
  });
}
