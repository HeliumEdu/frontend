import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';

void main() {
  group('HomeworkRequestModel', () {
    group('toJson', () {
      test('sends a recurrence rule when set', () {
        // GIVEN
        final request = HomeworkRequestModel(title: 'Reading', recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO;COUNT=5');

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json, {'title': 'Reading', 'recurrence_rule': 'FREQ=WEEKLY;BYDAY=MO;COUNT=5'});
      });

      test('clearing the rule sends explicit nulls for the rule and its exception dates', () {
        // GIVEN
        final request = HomeworkRequestModel(recurrenceRule: 'FREQ=DAILY', clearRecurrenceRule: true);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json, {'recurrence_rule': null, 'exception_dates': null});
      });

      test('omits the recurrence rule when unset, so a PATCH never touches the series', () {
        // GIVEN
        final request = HomeworkRequestModel(completed: true);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json, {'completed': true});
      });
    });
  });
}
