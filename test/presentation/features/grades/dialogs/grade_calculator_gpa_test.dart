import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_gpa.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

import '../../../../mocks/mock_models.dart';

void main() {
  final scale = GradeScaleTemplate.scales[2]!;

  group('GradeCalculatorGpa.of', () {
    test('projects the cumulative GPA across every group that counts toward it', () {
      // GIVEN
      final course = MockModels.createGradeCourse(credits: 3, gradePoint: 2.7, gradeScale: scale);
      final earlier = MockModels.createGradeCourse(id: 7, credits: 3, gradePoint: 4.0, gradeScale: scale);
      final term = MockModels.createGradeCourseGroup(id: 1, gpa: 2.7, inCumulativeGpa: true, courses: [course]);
      final previous = MockModels.createGradeCourseGroup(id: 2, gpa: 4.0, inCumulativeGpa: true, courses: [earlier]);

      // WHEN
      final gpa = GradeCalculatorGpa.of(course, term, [term, previous], 3.35);

      // THEN
      expect(gpa.cumulativeGpaWith(3.0), 3.5);
      expect(gpa.termGpaWith(3.0), 3.0);
    });

    test('leaves out the cumulative GPA when only this group counts toward it', () {
      // GIVEN
      final course = MockModels.createGradeCourse(credits: 3, gradePoint: 2.7, gradeScale: scale);
      final term = MockModels.createGradeCourseGroup(gpa: 2.7, inCumulativeGpa: true, courses: [course]);

      // WHEN
      final gpa = GradeCalculatorGpa.of(course, term, [term], 2.7);

      // THEN
      expect(gpa.cumulativeGpaWith(3.0), isNull);
    });
  });
}
