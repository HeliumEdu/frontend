import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/planner_helper.dart';

void main() {
  group('CourseScheduleRequestModel', () {
    group('toJson', () {
      test('marks a weekly schedule as not week-based', () {
        // GIVEN
        final request = givenCourseScheduleRequestModel();

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['template'], isNull);
        expect(json['is_week_based'], isFalse,
            reason: 'an existing Week A/B schedule must be able to switch back to weekly');
      });

      test('marks a custom day cycle as not week-based', () {
        // GIVEN
        final request = givenCourseScheduleRequestModel(cycleLength: 6);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['cycle_length'], 6);
        expect(json['is_week_based'], isFalse);
      });

      test('leaves rotation fields to the server for a preset template', () {
        // GIVEN
        final request = givenCourseScheduleRequestModel(template: 1);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['template'], 1);
        expect(json.containsKey('is_week_based'), isFalse);
        expect(json.containsKey('cycle_length'), isFalse);
      });
    });
  });
}
