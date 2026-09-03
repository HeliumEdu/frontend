import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();

  group('PlannerHelper', () {
    group('mapHeliumViewToSfCalendarView', () {
      test('maps view types correctly', () {
        expect(
          PlannerHelper.mapHeliumViewToSfCalendarView(PlannerView.month),
          CalendarView.month,
        );
        expect(
          PlannerHelper.mapHeliumViewToSfCalendarView(PlannerView.week),
          CalendarView.week,
        );
        expect(
          PlannerHelper.mapHeliumViewToSfCalendarView(PlannerView.day),
          CalendarView.day,
        );
        expect(
          PlannerHelper.mapHeliumViewToSfCalendarView(PlannerView.agenda),
          CalendarView.schedule,
        );
        expect(
          PlannerHelper.mapHeliumViewToSfCalendarView(PlannerView.todos),
          CalendarView.day,
        );
      });
    });

    group('mapSfCalendarViewToHeliumView', () {
      test('maps view types correctly', () {
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(CalendarView.month),
          PlannerView.month,
        );
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(CalendarView.week),
          PlannerView.week,
        );
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(CalendarView.day),
          PlannerView.day,
        );
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(CalendarView.schedule),
          PlannerView.agenda,
        );
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(CalendarView.timelineDay),
          PlannerView.day,
        );
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(
            CalendarView.timelineWeek,
          ),
          PlannerView.day,
        );
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(
            CalendarView.timelineWorkWeek,
          ),
          PlannerView.day,
        );
        expect(
          PlannerHelper.mapSfCalendarViewToHeliumView(
            CalendarView.timelineMonth,
          ),
          PlannerView.day,
        );
      });
    });

    group('mapApiViewToHeliumView', () {
      test('maps API integers to HeliumView', () {
        expect(PlannerHelper.mapApiViewToHeliumView(0), PlannerView.month);
        expect(PlannerHelper.mapApiViewToHeliumView(1), PlannerView.week);
        expect(PlannerHelper.mapApiViewToHeliumView(2), PlannerView.day);
        expect(PlannerHelper.mapApiViewToHeliumView(3), PlannerView.todos);
        expect(PlannerHelper.mapApiViewToHeliumView(4), PlannerView.agenda);
      });

      test('throws HeliumException for invalid view', () {
        expect(
          () => PlannerHelper.mapApiViewToHeliumView(5),
          throwsA(isA<HeliumException>()),
        );
        expect(
          () => PlannerHelper.mapApiViewToHeliumView(-1),
          throwsA(isA<HeliumException>()),
        );
      });
    });

    group('mapHeliumViewToApiView', () {
      test('maps HeliumView to API integers', () {
        expect(PlannerHelper.mapHeliumViewToApiView(PlannerView.month), 0);
        expect(PlannerHelper.mapHeliumViewToApiView(PlannerView.week), 1);
        expect(PlannerHelper.mapHeliumViewToApiView(PlannerView.day), 2);
        expect(PlannerHelper.mapHeliumViewToApiView(PlannerView.todos), 3);
        expect(PlannerHelper.mapHeliumViewToApiView(PlannerView.agenda), 4);
      });
    });

    group('getAlignmentForView', () {
      testWidgets('returns topLeft on mobile regardless of view', (
        tester,
      ) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(
                  PlannerHelper.getAlignmentForView(
                    context,
                    false,
                    PlannerView.month,
                  ),
                  Alignment.topLeft,
                );
                expect(
                  PlannerHelper.getAlignmentForView(
                    context,
                    true,
                    PlannerView.week,
                  ),
                  Alignment.topLeft,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns topLeft for month view in agenda on non-mobile', (
        tester,
      ) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Builder(
              builder: (context) {
                expect(
                  PlannerHelper.getAlignmentForView(
                    context,
                    true,
                    PlannerView.month,
                  ),
                  Alignment.topLeft,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets(
        'returns centerLeft for month view not in agenda on non-mobile',
        (tester) async {
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(1024, 768)),
              child: Builder(
                builder: (context) {
                  expect(
                    PlannerHelper.getAlignmentForView(
                      context,
                      false,
                      PlannerView.month,
                    ),
                    Alignment.centerLeft,
                  );
                  return const SizedBox();
                },
              ),
            ),
          );
        },
      );

      testWidgets('returns topLeft for non-month views on non-mobile', (
        tester,
      ) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Builder(
              builder: (context) {
                expect(
                  PlannerHelper.getAlignmentForView(
                    context,
                    false,
                    PlannerView.week,
                  ),
                  Alignment.topLeft,
                );
                expect(
                  PlannerHelper.getAlignmentForView(
                    context,
                    false,
                    PlannerView.day,
                  ),
                  Alignment.topLeft,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('roundMinute', () {
      test('rounds minutes 0-14 down to 0', () {
        expect(PlannerHelper.roundMinute(0), 0);
        expect(PlannerHelper.roundMinute(7), 0);
        expect(PlannerHelper.roundMinute(14), 0);
      });

      test('rounds minutes 15-44 to 30', () {
        expect(PlannerHelper.roundMinute(15), 30);
        expect(PlannerHelper.roundMinute(29), 30);
        expect(PlannerHelper.roundMinute(30), 30);
        expect(PlannerHelper.roundMinute(44), 30);
      });

      test('rounds minutes 45-59 up to 60 (overflows to next hour)', () {
        expect(PlannerHelper.roundMinute(45), 60);
        expect(PlannerHelper.roundMinute(52), 60);
        expect(PlannerHelper.roundMinute(59), 60);
      });

      test('is idempotent on already-rounded values', () {
        expect(PlannerHelper.roundMinute(0), 0);
        expect(PlannerHelper.roundMinute(30), 30);
      });
    });

    group('shouldShowCheckbox', () {
      test('returns false for non-HomeworkModel regardless of width', () {
        final eventItem = _createEventModel();

        expect(PlannerHelper.shouldShowCheckbox(eventItem, 1000), isFalse);
      });

      test(
        'returns true for HomeworkModel when appointment width is at least '
        '2x the checkbox width',
        () {
          final homeworkItem = _createHomeworkModel();

          expect(
            PlannerHelper.shouldShowCheckbox(
              homeworkItem,
              PlannerHelper.checkboxWidth * 2,
            ),
            isTrue,
          );
        },
      );

      test(
        'returns false for HomeworkModel when appointment width is under '
        '2x the checkbox width',
        () {
          final homeworkItem = _createHomeworkModel();

          expect(
            PlannerHelper.shouldShowCheckbox(
              homeworkItem,
              PlannerHelper.checkboxWidth * 2 - 0.1,
            ),
            isFalse,
          );
        },
      );

      test('returns true for HomeworkModel on wide appointments', () {
        final homeworkItem = _createHomeworkModel();

        expect(PlannerHelper.shouldShowCheckbox(homeworkItem, 1000), isTrue);
      });
    });
  });

  group('initialDateForNewItem', () {
    final amsterdam = tz.getLocation('Europe/Amsterdam');

    test('todos prefills the account-timezone hour, not the device one', () {
      // GIVEN
      final now = tz.TZDateTime(amsterdam, 2025, 9, 4, 14, 30);

      // WHEN
      final result = PlannerHelper.initialDateForNewItem(
        view: PlannerView.todos,
        selectedDate: null,
        now: now,
        timeZone: amsterdam,
      );

      // THEN
      expect(tz.TZDateTime.from(result!, amsterdam),
          tz.TZDateTime(amsterdam, 2025, 9, 4, 14));
    });

    test('a grid tap keeps the account-timezone wall clock it was made in', () {
      // GIVEN
      final tapped = DateTime(2025, 9, 4, 14, 0);

      // WHEN
      final result = PlannerHelper.initialDateForNewItem(
        view: PlannerView.week,
        selectedDate: tapped,
        now: tz.TZDateTime(amsterdam, 2025, 9, 4, 9),
        timeZone: amsterdam,
      );

      // THEN
      expect(tz.TZDateTime.from(result!, amsterdam),
          tz.TZDateTime(amsterdam, 2025, 9, 4, 14),
          reason: 'the tapped 14:00 slot must survive as 14:00 in the account zone');
    });

    test('no selection on a calendar view yields null', () {
      // GIVEN / WHEN
      final result = PlannerHelper.initialDateForNewItem(
        view: PlannerView.week,
        selectedDate: null,
        now: tz.TZDateTime(amsterdam, 2025, 9, 4, 9),
        timeZone: amsterdam,
      );

      // THEN
      expect(result, isNull);
    });
  });

  group('firstIndexDueOnOrAfter', () {
    final amsterdam = tz.getLocation('Europe/Amsterdam');
    final nowInAmsterdam = tz.TZDateTime(amsterdam, 2025, 9, 4, 10, 0);

    test('finds an all-day task due today at a positive UTC offset', () {
      final sorted = [
        _createHomeworkModel(
            id: 1, allDay: true, start: DateTime.parse('2025-09-03T22:00:00Z')),
        _createHomeworkModel(
            id: 2, allDay: true, start: DateTime.parse('2025-09-04T22:00:00Z')),
      ];

      expect(
        PlannerHelper.firstIndexDueOnOrAfter(sorted, nowInAmsterdam, amsterdam),
        0,
        reason: "the task due today must win, not tomorrow's",
      );
    });

    test('skips a task that is genuinely in the past', () {
      final sorted = [
        _createHomeworkModel(
            id: 1, allDay: true, start: DateTime.parse('2025-09-02T22:00:00Z')),
        _createHomeworkModel(
            id: 2, allDay: true, start: DateTime.parse('2025-09-03T22:00:00Z')),
      ];

      expect(
        PlannerHelper.firstIndexDueOnOrAfter(sorted, nowInAmsterdam, amsterdam),
        1,
      );
    });

    test('returns -1 when every task is in the past', () {
      final sorted = [
        _createHomeworkModel(
            id: 1, allDay: true, start: DateTime.parse('2025-09-01T22:00:00Z')),
      ];

      expect(
        PlannerHelper.firstIndexDueOnOrAfter(sorted, nowInAmsterdam, amsterdam),
        -1,
      );
    });

    test('a timed task due later today is still selected', () {
      final sorted = [
        _createHomeworkModel(
            id: 1, start: DateTime.parse('2025-09-04T14:00:00Z')),
      ];

      expect(
        PlannerHelper.firstIndexDueOnOrAfter(sorted, nowInAmsterdam, amsterdam),
        0,
      );
    });

    test('a negative UTC offset is unaffected', () {
      final losAngeles = tz.getLocation('America/Los_Angeles');
      final now = tz.TZDateTime(losAngeles, 2025, 1, 15, 10, 0);
      final sorted = [
        _createHomeworkModel(
            id: 1, allDay: true, start: DateTime.parse('2025-01-14T08:00:00Z')),
        _createHomeworkModel(
            id: 2, allDay: true, start: DateTime.parse('2025-01-15T08:00:00Z')),
      ];

      expect(PlannerHelper.firstIndexDueOnOrAfter(sorted, now, losAngeles), 1);
    });
  });
}

EventModel _createEventModel({bool allDay = false}) {
  return EventModel(
    id: 1,
    title: 'Test Event',
    allDay: allDay,
    showEndTime: true,
    start: DateTime.parse('2025-01-15T10:00:00Z'),
    end: DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    url: null,
    comments: '',
    attachments: [],
    reminders: [],
    notes: [],
    color: const Color(0xFF4CAF50),
  );
}

HomeworkModel _createHomeworkModel({
  bool allDay = false,
  int id = 1,
  DateTime? start,
}) {
  return HomeworkModel(
    id: id,
    title: 'Test Homework',
    allDay: allDay,
    showEndTime: true,
    start: start ?? DateTime.parse('2025-01-15T10:00:00Z'),
    end: DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    comments: '',
    attachments: [],
    reminders: [],
    notes: [],
    completed: false,
    currentGrade: '-1/100',
    course: IdOrEntity<CourseModel>(id: 1),
    category: IdOrEntity<CategoryModel>(id: 1),
    resources: [],
  );
}
