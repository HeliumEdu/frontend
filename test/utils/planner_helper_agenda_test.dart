import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

import '../helpers/planner_helper.dart';

void main() {
  tz_data.initializeTimeZones();

  final amsterdam = tz.getLocation('Europe/Amsterdam');
  final losAngeles = tz.getLocation('America/Los_Angeles');

  HomeworkModel givenHomework(
    int id,
    String start, {
    String? end,
    bool allDay = false,
    bool completed = false,
    int course = 1,
    String? rule,
    List<String>? exceptions,
  }) {
    return HomeworkModel.fromJson(givenHomeworkJson(
      id: id,
      title: 'Homework $id',
      start: start,
      end: end ?? DateTime.parse(start).add(const Duration(hours: 1)).toUtc().toIso8601String(),
      allDay: allDay,
      completed: completed,
      course: course,
      recurrenceRule: rule,
      exceptionDates: exceptions,
    ));
  }

  ({List<dynamic> items, int olderOverdueCount}) agendaAt(
    DateTime now, {
    List<HomeworkModel> homeworks = const [],
    tz.Location? timeZone,
  }) {
    final agenda = PlannerHelper.agendaItems(
      homeworks: homeworks,
      timeZone: timeZone ?? amsterdam,
      now: now,
      daysBack: 14,
      daysAhead: 14,
    );
    return (items: agenda.items, olderOverdueCount: agenda.olderOverdueCount);
  }

  group('PlannerHelper.agendaItems', () {
    test('keeps assignments in the window and counts older incomplete ones', () {
      // GIVEN
      final now = DateTime.utc(2026, 11, 18, 12);
      final homeworks = [
        givenHomework(1, '2026-11-10T16:00:00Z'),
        givenHomework(2, '2026-11-10T16:00:00Z', completed: true),
        givenHomework(3, '2026-10-01T16:00:00Z'),
        givenHomework(4, '2026-11-25T16:00:00Z'),
        givenHomework(5, '2026-12-05T16:00:00Z'),
      ];

      // WHEN
      final agenda = agendaAt(now, homeworks: homeworks);

      // THEN
      expect(agenda.items.map((item) => item.id), [1, 4],
          reason: 'completed once due, older than 14 days and later than 14 days ahead are left out');
      expect(agenda.olderOverdueCount, 1);
    });

    test('keeps completed assignments only until they are due', () {
      // GIVEN
      final now = DateTime.utc(2026, 11, 18, 12);
      final homeworks = [
        givenHomework(1, '2026-11-18T08:00:00Z', completed: true),
        givenHomework(2, '2026-11-20T16:00:00Z', completed: true),
        givenHomework(3, '2026-11-17T16:00:00Z', completed: true),
        givenHomework(4, '2026-11-18T16:00:00Z', completed: true),
      ];

      // WHEN
      final agenda = agendaAt(now, homeworks: homeworks);

      // THEN
      expect(agenda.items.map((item) => item.id), [4, 2],
          reason: 'a completed assignment is dropped once its due time passes, even earlier today');
    });

    test('measures the window in the user zone', () {
      // GIVEN
      final now = DateTime.utc(2026, 11, 17, 23, 30);
      final homeworks = [givenHomework(1, '2026-11-03T22:30:00Z')];

      // WHEN
      final inAmsterdam = agendaAt(now, homeworks: homeworks);
      final inLosAngeles = agendaAt(now, homeworks: homeworks, timeZone: losAngeles);

      // THEN
      expect(inAmsterdam.items, isEmpty, reason: 'it is Nov 18 in Amsterdam, so the window starts Nov 4');
      expect(inAmsterdam.olderOverdueCount, 1);
      expect(inLosAngeles.items.map((item) => item.id), [1], reason: 'it is Nov 17 in Los Angeles');
    });

    test('expands a repeating assignment and skips its exceptions', () {
      // GIVEN
      final now = DateTime.utc(2026, 11, 18, 12);
      final series = givenHomework(1, '2026-11-02T15:00:00Z',
          rule: 'FREQ=WEEKLY;BYDAY=MO', exceptions: ['2026-11-16T15:00:00Z']);

      // WHEN
      final agenda = agendaAt(now, homeworks: [series]);

      // THEN
      expect(agenda.items.map((item) => tz.TZDateTime.from(item.start, amsterdam).toString()), [
        '2026-11-09 16:00:00.000+0100',
        '2026-11-23 16:00:00.000+0100',
        '2026-11-30 16:00:00.000+0100',
      ]);
      expect(agenda.olderOverdueCount, 0, reason: 'only one-time assignments count as older');
    });

    test('keeps a repeating assignment at the same wall clock across a DST change', () {
      // GIVEN
      final now = DateTime.utc(2026, 10, 20, 12);
      final series = givenHomework(1, '2026-10-19T14:00:00Z', rule: 'FREQ=WEEKLY;BYDAY=MO');

      // WHEN
      final agenda = agendaAt(now, homeworks: [series]);

      // THEN
      expect(agenda.items.map((item) => tz.TZDateTime.from(item.start, amsterdam).hour), everyElement(16));
      expect(agenda.items.length, 3);
    });

    test('ends each all-day occurrence at the next midnight across a DST change', () {
      // GIVEN
      final now = DateTime.utc(2026, 10, 20, 12);
      final inAmsterdam = givenHomework(1, '2026-10-17T22:00:00Z',
          end: '2026-10-18T22:00:00Z', allDay: true, rule: 'FREQ=WEEKLY;BYDAY=SU');
      final inLosAngeles = givenHomework(1, '2026-10-18T07:00:00Z',
          end: '2026-10-19T07:00:00Z', allDay: true, rule: 'FREQ=WEEKLY;BYDAY=SU');

      // WHEN
      final amsterdamAgenda = agendaAt(now, homeworks: [inAmsterdam]);
      final losAngelesAgenda = agendaAt(now, homeworks: [inLosAngeles], timeZone: losAngeles);

      // THEN
      final onDstDay = amsterdamAgenda.items.firstWhere((item) => tz.TZDateTime.from(item.start, amsterdam).day == 25);
      expect(tz.TZDateTime.from(onDstDay.end, amsterdam).toString(), '2026-10-26 00:00:00.000+0100',
          reason: 'Oct 25 is 25 hours long when the clocks go back, and its occurrence still ends at midnight');
      expect(losAngelesAgenda.items.map((item) => tz.TZDateTime.from(item.end, losAngeles).hour), everyElement(0));
    });

    test('orders days by date and each day as the Planner does', () {
      // GIVEN
      final now = DateTime.utc(2026, 11, 18, 12);

      // WHEN
      final agenda = agendaAt(now, homeworks: [
        givenHomework(1, '2026-11-20T16:00:00Z'),
        givenHomework(2, '2026-11-12T16:00:00Z'),
        givenHomework(5, '2026-11-19T23:00:00Z', end: '2026-11-20T23:00:00Z', allDay: true),
      ]);

      // THEN
      expect(agenda.items.map((item) => item.id), [2, 5, 1],
          reason: "Nov 20's all-day assignment (11 PM UTC on Nov 19) leads that day in Amsterdam");
    });
  });
}
