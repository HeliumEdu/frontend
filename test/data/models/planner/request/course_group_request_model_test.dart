import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';

CourseGroupRequestModel _givenCourseGroupRequestModel({
  int? gradeScaleTemplate,
}) {
  return CourseGroupRequestModel(
    title: 'Spring',
    startDate: '2026-01-12',
    endDate: '2026-05-08',
    shownOnCalendar: true,
    gradeScaleTemplate: gradeScaleTemplate,
  );
}

void main() {
  group('CourseGroupRequestModel', () {
    group('toJson', () {
      test('sends only the template for a preset', () {
        // GIVEN
        final request = _givenCourseGroupRequestModel(gradeScaleTemplate: 3);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['grade_scale_template'], 3);
        expect(json.containsKey('grade_scale'), isFalse);
      });

      test('sends neither field without a preset', () {
        // GIVEN
        final request = _givenCourseGroupRequestModel();

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json.containsKey('grade_scale_template'), isFalse);
        expect(json.containsKey('grade_scale'), isFalse);
      });
    });
  });
}
