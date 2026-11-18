import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

import '../mocks/mock_models.dart';

GradeCourseModel _gradedCourse({
  required double overallGrade,
  required int numHomeworkGraded,
}) {
  return GradeCourseModel(
    id: 1,
    title: 'Biology',
    overallGrade: overallGrade,
    credits: 3,
    gradePoint: null,
    gradeScale: const [],
    color: Colors.blue,
    numHomework: 10,
    numHomeworkCompleted: numHomeworkGraded,
    numHomeworkGraded: numHomeworkGraded,
    pointsEarned: 0,
    pointsPossible: 0,
    categories: const [],
    homeworkSeries: const [],
  );
}

void main() {
  group('GradeHelper', () {
    group('isAtRisk', () {
      test('a graded class below the threshold is at risk', () {
        // GIVEN
        final course = _gradedCourse(overallGrade: 69.9, numHomeworkGraded: 3);

        // WHEN
        final atRisk = GradeHelper.isAtRisk(course, 70);

        // THEN
        expect(atRisk, isTrue);
      });

      test('a class exactly at the threshold is not at risk', () {
        // GIVEN
        final course = _gradedCourse(overallGrade: 70, numHomeworkGraded: 3);

        // WHEN
        final atRisk = GradeHelper.isAtRisk(course, 70);

        // THEN
        expect(atRisk, isFalse);
      });

      test('a low grade with no graded assignments is not at risk', () {
        // GIVEN
        final course = _gradedCourse(overallGrade: 20, numHomeworkGraded: 0);

        // WHEN
        final atRisk = GradeHelper.isAtRisk(course, 70);

        // THEN
        expect(atRisk, isFalse);
      });

      test(
        'an ungraded class is not at risk even with graded assignments counted',
        () {
          // GIVEN
          final course = _gradedCourse(overallGrade: -1, numHomeworkGraded: 3);

          // WHEN
          final atRisk = GradeHelper.isAtRisk(course, 70);

          // THEN
          expect(
            atRisk,
            isFalse,
            reason: '-1 is the API sentinel for no grade',
          );
        },
      );
    });

    group('gpaHint', () {
      test(
        'there is no hint when every class has credits and the group counts toward GPA',
        () {
          // GIVEN
          final group = MockModels.createGradeCourseGroup(
            inCumulativeGpa: true,
            courses: [
              MockModels.createGradeCourse(credits: 3, gradePoint: 3.0),
            ],
          );

          // WHEN
          final hint = GradeHelper.gpaHint(
            group,
            [group],
            priorCredits: 0,
            priorGpa: 0,
          );

          // THEN
          expect(hint, isNull);
        },
      );

      test('a graded class without credits is called out as not counted', () {
        // GIVEN
        final group = MockModels.createGradeCourseGroup(
          inCumulativeGpa: true,
          courses: [
            MockModels.createGradeCourse(credits: 0, gradePoint: 3.0),
            MockModels.createGradeCourse(id: 2, credits: 0, gradePoint: null),
          ],
        );

        // WHEN
        final hint = GradeHelper.gpaHint(
          group,
          [group],
          priorCredits: 0,
          priorGpa: 0,
        );

        // THEN
        expect(
          hint,
          "1 class without credits isn't counted.",
          reason:
              'a class with no grade point has nothing to count, so only one is named',
        );
      });

      test('a group left out of the cumulative GPA explains why', () {
        // GIVEN
        final current = MockModels.createGradeCourseGroup(
          id: 1,
          inCumulativeGpa: true,
        );
        final older = MockModels.createGradeCourseGroup(
          id: 2,
          inCumulativeGpa: false,
        );

        // WHEN
        final hint = GradeHelper.gpaHint(
          older,
          [current, older],
          priorCredits: 0,
          priorGpa: 0,
        );

        // THEN
        expect(
          hint,
          "This group's grade scale differs from your most recent one, so it isn't counted in your GPA across "
          'all terms.',
        );
      });

      test('the example schedule never gets the cumulative GPA hint', () {
        // GIVEN
        final current = MockModels.createGradeCourseGroup(
          id: 1,
          inCumulativeGpa: true,
        );
        final example = MockModels.createGradeCourseGroup(
          id: 2,
          inCumulativeGpa: false,
          exampleSchedule: true,
        );

        // WHEN
        final hint = GradeHelper.gpaHint(
          example,
          [current, example],
          priorCredits: 0,
          priorGpa: 0,
        );

        // THEN
        expect(hint, isNull);
      });
    });
  });
}
