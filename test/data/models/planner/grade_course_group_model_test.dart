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
    });
  });
}
