import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';

import '../../../helpers/planner_helper.dart';

void main() {
  group('CourseModel', () {
    test('reads the class grade scale', () {
      // WHEN
      final withPreset = CourseModel.fromJson(givenCourseJson(gradeScaleTemplate: 1));
      final withoutPreset = CourseModel.fromJson(givenCourseJson());

      // THEN
      expect(withPreset.gradeScaleTemplate, 1);
      expect(withoutPreset.gradeScaleTemplate, isNull);
    });
  });
}
