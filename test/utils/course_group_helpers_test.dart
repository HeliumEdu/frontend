import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/utils/course_group_helpers.dart';

import '../helpers/planner_helper.dart';

CourseGroupModel _givenCourseGroup(
  int id,
  String startDate, {
  bool exampleSchedule = false,
}) {
  return CourseGroupModel.fromJson(
    givenCourseGroupJson(
      id: id,
      startDate: startDate,
      exampleSchedule: exampleSchedule,
    ),
  );
}

void main() {
  group('CourseGroupHelpers', () {
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
