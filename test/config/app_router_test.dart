import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_router.dart';

void main() {
  group('Platform deep links', () {
    test('test_assignment_link_matches_platform_deeplinkutils', () {
      // WHEN
      final route = reminderEntityRoute(homeworkId: 1);

      // THEN
      expect(route, '/planner/assignment/1/details');
    });

    test('test_event_link_matches_platform_deeplinkutils', () {
      // WHEN
      final route = reminderEntityRoute(eventId: 1);

      // THEN
      expect(route, '/planner/event/1/details');
    });

    test('test_attachments_steps_match_platform_deeplinkutils', () {
      // THEN
      expect(plannerItemDialogSteps, contains('attachments'));
    });

    test('test_class_link_matches_platform_deeplinkutils', () {
      // WHEN
      final route = reminderEntityRoute(courseId: 1);

      // THEN
      expect(route, '/classes/1/details');
    });

    test('test_class_schedule_link_matches_platform_deeplinkutils', () {
      // THEN
      expect(courseDialogSteps, contains('schedule'));
    });
  });
}
