import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';

CourseGroupRequestModel _givenCourseGroupRequestModel({
  int? gradeScaleTemplate,
  List<DateTime> exceptions = const [],
}) {
  return CourseGroupRequestModel(
    title: 'Spring',
    startDate: '2026-01-12',
    endDate: '2026-05-08',
    shownOnCalendar: true,
    gradeScaleTemplate: gradeScaleTemplate,
    exceptions: exceptions,
  );
}

void main() {
  group('CourseGroupRequestModel', () {
    group('toJson', () {
      test('sends the template for a preset', () {
        // GIVEN
        final request = _givenCourseGroupRequestModel(gradeScaleTemplate: 3);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['grade_scale_template'], 3);
      });

      test('omits the template without a preset', () {
        // GIVEN
        final request = _givenCourseGroupRequestModel();

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json.containsKey('grade_scale_template'), isFalse);
      });

      test('sends holidays as sorted dates', () {
        // GIVEN
        final request = _givenCourseGroupRequestModel(
          exceptions: [DateTime(2026, 3, 16), DateTime(2026, 1, 19)],
        );

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['exceptions'], '20260119,20260316');
      });

      test('sends no holidays as an empty list, clearing them', () {
        // GIVEN
        final request = _givenCourseGroupRequestModel();

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['exceptions'], '');
      });
    });
  });
}
