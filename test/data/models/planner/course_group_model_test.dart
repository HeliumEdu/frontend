import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';

import '../../../helpers/planner_helper.dart';

void main() {
  group('CourseGroupModel', () {
    group('fromJson', () {
      test('parses the grade scale and its template', () {
        // GIVEN
        final json = givenCourseGroupJson(gradeScaleTemplate: 1);

        // WHEN
        final group = CourseGroupModel.fromJson(json);

        // THEN
        expect(group.gradeScaleTemplate, 1);
        expect(group.exampleSchedule, isFalse);
        expect(group.gradeScale.length, 5);
        expect(group.gradeScale.first.minGrade, 0.0);
        expect(group.gradeScale.last.label, 'A');
        expect(group.gradeScale.last.gradePoint, 4.0);
      });

      test('parses a custom scale without a template', () {
        // GIVEN
        final json = givenCourseGroupJson(gradeScaleTemplate: null);

        // WHEN
        final group = CourseGroupModel.fromJson(json);

        // THEN
        expect(group.gradeScaleTemplate, isNull);
        expect(group.gradeScale.length, 5);
      });
    });
  });
}
