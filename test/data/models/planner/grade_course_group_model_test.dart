import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';

import '../../../helpers/planner_helper.dart';

void main() {
  group('GradeCourseGroupModel', () {
    group('fromJson', () {
      test('parses the term trend the API sends', () {
        // GIVEN
        final json = givenGradeCourseGroupJson(trend: 0.025);

        // WHEN
        final group = GradeCourseGroupModel.fromJson(json);

        // THEN
        expect(group.trend, 0.025);
      });

      test('leaves the trend null when the term has too few grades for one', () {
        // GIVEN
        final json = givenGradeCourseGroupJson();

        // WHEN
        final group = GradeCourseGroupModel.fromJson(json);

        // THEN
        expect(group.trend, isNull);
      });

      test('parses the term grade scale', () {
        // GIVEN
        final json = givenGradeCourseGroupJson();

        // WHEN
        final group = GradeCourseGroupModel.fromJson(json);

        // THEN
        expect(
          group.gradeScale.map((band) => band.gradePoint),
          [0.0, 1.0, 2.0, 3.0, 4.0],
        );
      });

      test('parses each series item GPA, with no GPA yet as null', () {
        // GIVEN
        final json = givenGradeCourseGroupJson(
          homeworkSeries: [
            givenHomeworkSeriesItemJson(id: 1, gpa: -1),
            givenHomeworkSeriesItemJson(id: 2, gpa: 3.5),
            givenHomeworkSeriesItemJson(id: 3, graded: false, gpa: null),
          ],
        );

        // WHEN
        final group = GradeCourseGroupModel.fromJson(json);

        // THEN
        expect(
          group.homeworkSeries.map((item) => item.gpa),
          [null, 3.5, null],
          reason: '-1 marks a point before any class with credits is graded',
        );
      });
    });
  });
}
