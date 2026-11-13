import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';

void main() {
  group('EventRequestModel', () {
    group('toJson', () {
      test('sends a recurrence rule when set', () {
        // GIVEN
        final request = EventRequestModel(recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO');

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json, {'recurrence_rule': 'FREQ=WEEKLY;BYDAY=MO'});
      });

      test('clearing the rule sends explicit nulls for the rule and its exception dates', () {
        // GIVEN
        final request = EventRequestModel(title: 'Study Group', clearRecurrenceRule: true);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json, {'title': 'Study Group', 'recurrence_rule': null, 'exception_dates': null});
        expect(json.containsKey('recurrence_rule'), isTrue,
            reason: 'an omitted key would leave the series repeating on a PATCH');
      });

      test('clearing the rule wins over a rule passed with it', () {
        // GIVEN
        final request = EventRequestModel(recurrenceRule: 'FREQ=DAILY', clearRecurrenceRule: true);

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json['recurrence_rule'], isNull);
      });

      test('omits recurrence keys when neither is set', () {
        // GIVEN
        final request = EventRequestModel(title: 'Study Group');

        // WHEN
        final json = request.toJson();

        // THEN
        expect(json.keys, ['title']);
      });
    });
  });
}
