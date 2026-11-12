import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';

import '../../../helpers/planner_helper.dart';
import '../../../mocks/mock_models.dart';

void main() {
  group('EventModel', () {
    test('fromJson reads the recurrence rule and exception dates as instants', () {
      // GIVEN
      final json = givenEventJson(
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=TU,TH',
        exceptionDates: ['2026-11-19T11:00:00Z'],
      );

      // WHEN
      final event = EventModel.fromJson(json);

      // THEN
      expect(event.recurrenceRule, 'FREQ=WEEKLY;BYDAY=TU,TH');
      expect(event.exceptionDates, [DateTime.utc(2026, 11, 19, 11)]);
    });
  });

  group('HomeworkModel', () {
    test('fromJson reads the recurrence rule and exception dates, or none for a standalone assignment', () {
      // WHEN
      final series = HomeworkModel.fromJson({
        ...givenHomeworkJson(recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO'),
        'exception_dates': ['2026-11-16T11:00:00Z'],
      });
      final standalone = HomeworkModel.fromJson(givenHomeworkJson());

      // THEN
      expect(series.recurrenceRule, 'FREQ=WEEKLY;BYDAY=MO');
      expect(series.exceptionDates, [DateTime.utc(2026, 11, 16, 11)]);
      expect(standalone.recurrenceRule, isNull);
      expect(standalone.exceptionDates, isEmpty);
    });

    test('copyWith of an occurrence moves only the times, keeping the series it belongs to', () {
      // GIVEN
      final homework = MockModels.createHomework(
        id: 4,
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
        exceptionDates: [DateTime.utc(2026, 11, 16, 11)],
      );
      final start = DateTime.utc(2026, 11, 23, 11);
      final end = DateTime.utc(2026, 11, 23, 12);

      // WHEN
      final occurrence = homework.copyWith(start: start, end: end);

      // THEN
      expect(occurrence.id, 4);
      expect((occurrence.start, occurrence.end), (start, end));
      expect(occurrence.recurrenceRule, 'FREQ=WEEKLY;BYDAY=MO');
      expect(occurrence.exceptionDates, [DateTime.utc(2026, 11, 16, 11)]);
      expect(occurrence.completed, isFalse);
    });
  });
}
