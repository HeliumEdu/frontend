import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

import '../mocks/mock_models.dart';

void main() {
  final plusMinus = GradeScaleTemplate.scales[2]!;

  group('GradeHelper.gradeScaleLabelFor', () {
    test('names the group scale a class follows', () {
      // GIVEN
      final group = MockModels.createCourseGroup(gradeScale: plusMinus, gradeScaleTemplate: 2);
      final course = MockModels.createCourse();

      // WHEN
      final label = GradeHelper.gradeScaleLabelFor(course, group);

      // THEN
      expect(label, '4.0 with +/-');
    });

    test('names the class\'s own scale over the group\'s', () {
      // GIVEN
      final group = MockModels.createCourseGroup(gradeScale: plusMinus, gradeScaleTemplate: 2);
      final course = MockModels.createCourse(gradeScaleTemplate: 1);

      // WHEN
      final label = GradeHelper.gradeScaleLabelFor(course, group);

      // THEN
      expect(label, '4.0');
    });

    test('calls a group scale that matches no preset Custom', () {
      // GIVEN
      final group = MockModels.createCourseGroup(
        gradeScale: const [
          GradeScaleBandModel(minGrade: 0, gradePoint: 0, label: 'F'),
          GradeScaleBandModel(minGrade: 65, gradePoint: 4, label: 'P'),
        ],
      );
      final course = MockModels.createCourse();

      // WHEN
      final label = GradeHelper.gradeScaleLabelFor(course, group);

      // THEN
      expect(label, 'Custom');
    });

    test('has no scale when the group has none', () {
      // GIVEN
      final group = MockModels.createCourseGroup(gradeScaleTemplate: GradeScaleTemplate.none);
      final course = MockModels.createCourse();

      // WHEN
      final label = GradeHelper.gradeScaleLabelFor(course, group);
      final withoutGroup = GradeHelper.gradeScaleLabelFor(course, null);

      // THEN
      expect(label, isNull);
      expect(withoutGroup, isNull);
    });
  });
}
