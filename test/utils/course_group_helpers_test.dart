import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/utils/course_group_helpers.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

import '../helpers/planner_helper.dart';

CourseGroupModel _givenCourseGroup(
  int id,
  String startDate, {
  String endDate = '2025-12-15',
  bool exampleSchedule = false,
}) {
  return CourseGroupModel.fromJson(
    givenCourseGroupJson(
      id: id,
      startDate: startDate,
      endDate: endDate,
      exampleSchedule: exampleSchedule,
    ),
  );
}

String _dateFromToday(tz.Location timeZone, int days) {
  final now = tz.TZDateTime.now(timeZone);
  return tz.TZDateTime(timeZone, now.year, now.month, now.day + days)
      .toIso8601String()
      .substring(0, 10);
}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('CourseGroupHelpers', () {
    group('termWeekOf', () {
      late tz.Location losAngeles;

      setUp(() {
        losAngeles = tz.getLocation('America/Los_Angeles');
      });

      test('a term holding today reports the week it is in', () {
        // GIVEN
        final group = _givenCourseGroup(
          1,
          _dateFromToday(losAngeles, -15),
          endDate: _dateFromToday(losAngeles, 60),
        );

        // WHEN
        final termWeek = CourseGroupHelpers.termWeekOf(group, losAngeles);

        // THEN
        expect(termWeek, '2');
      });

      test('a term that has ended reports nothing', () {
        // GIVEN
        final group = _givenCourseGroup(
          1,
          _dateFromToday(losAngeles, -120),
          endDate: _dateFromToday(losAngeles, -1),
        );

        // WHEN
        final termWeek = CourseGroupHelpers.termWeekOf(group, losAngeles);

        // THEN
        expect(termWeek, isNull);
      });

      test('a term that has not started reports nothing', () {
        // GIVEN
        final group = _givenCourseGroup(
          1,
          _dateFromToday(losAngeles, 1),
          endDate: _dateFromToday(losAngeles, 90),
        );

        // WHEN
        final termWeek = CourseGroupHelpers.termWeekOf(group, losAngeles);

        // THEN
        expect(termWeek, isNull);
      });

      test('the example schedule reports nothing even while it holds today', () {
        // GIVEN
        final group = _givenCourseGroup(
          1,
          _dateFromToday(losAngeles, -15),
          endDate: _dateFromToday(losAngeles, 60),
          exampleSchedule: true,
        );

        // WHEN
        final termWeek = CourseGroupHelpers.termWeekOf(group, losAngeles);

        // THEN
        expect(termWeek, isNull);
      });
    });

    group('currentTermWeek', () {
      test('reports the week of the term holding today, skipping the others', () {
        // GIVEN
        final losAngeles = tz.getLocation('America/Los_Angeles');
        final groups = [
          _givenCourseGroup(
            1,
            _dateFromToday(losAngeles, -200),
            endDate: _dateFromToday(losAngeles, -100),
          ),
          _givenCourseGroup(
            2,
            _dateFromToday(losAngeles, -22),
            endDate: _dateFromToday(losAngeles, 60),
          ),
        ];

        // WHEN
        final termWeek = CourseGroupHelpers.currentTermWeek(groups, losAngeles);

        // THEN
        expect(termWeek, '3');
      });
    });

    group('latestGroup', () {
      test('is the group that starts last', () {
        // GIVEN
        final groups = [
          _givenCourseGroup(1, '2025-08-25'),
          _givenCourseGroup(2, '2026-01-12'),
          _givenCourseGroup(3, '2025-01-13'),
        ];

        // WHEN
        final latest = CourseGroupHelpers.latestGroup(groups);

        // THEN
        expect(latest?.id, 2);
      });

      test('breaks a start date tie by the highest id', () {
        // GIVEN
        final groups = [
          _givenCourseGroup(5, '2026-01-12'),
          _givenCourseGroup(4, '2026-01-12'),
        ];

        // WHEN
        final latest = CourseGroupHelpers.latestGroup(groups);

        // THEN
        expect(latest?.id, 5);
      });

      test('skips the example schedule', () {
        // GIVEN
        final groups = [
          _givenCourseGroup(1, '2025-08-25'),
          _givenCourseGroup(2, '2026-01-12', exampleSchedule: true),
        ];

        // WHEN
        final latest = CourseGroupHelpers.latestGroup(groups);

        // THEN
        expect(latest?.id, 1);
      });

      test('is null with only the example schedule', () {
        // GIVEN
        final groups = [
          _givenCourseGroup(1, '2026-01-12', exampleSchedule: true),
        ];

        // WHEN
        final latest = CourseGroupHelpers.latestGroup(groups);

        // THEN
        expect(latest, isNull);
      });

      test('is null without groups', () {
        // WHEN
        final latest = CourseGroupHelpers.latestGroup([]);

        // THEN
        expect(latest, isNull);
      });
    });
  });
}
