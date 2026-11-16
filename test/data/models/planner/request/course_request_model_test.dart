import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';

CourseRequestModel _givenCourseRequestModel({int? gradeScaleTemplate}) {
  return CourseRequestModel(
    title: 'Biology',
    room: '',
    credits: '3',
    gradeScaleTemplate: gradeScaleTemplate,
    color: '#4CAF50',
    website: '',
    isOnline: false,
    teacherName: '',
    teacherEmail: '',
    startDate: '2026-08-24',
    endDate: '2026-12-18',
    courseGroup: 1,
  );
}

void main() {
  group('CourseRequestModel', () {
    test('sends the class grade scale', () {
      // GIVEN
      final request = _givenCourseRequestModel(gradeScaleTemplate: 1);

      // WHEN
      final json = request.toJson();

      // THEN
      expect(json['grade_scale_template'], 1);
    });

    test('sends no class grade scale as null, using the group\'s', () {
      // GIVEN
      final request = _givenCourseRequestModel();

      // WHEN
      final json = request.toJson();

      // THEN
      expect(json.containsKey('grade_scale_template'), isTrue);
      expect(json['grade_scale_template'], isNull);
    });
  });
}
