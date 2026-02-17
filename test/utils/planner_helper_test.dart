// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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

void main() {
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

    group('shouldShowCheckbox', () {
      testWidgets('returns false for non-HomeworkModel', (tester) async {
        final eventItem = _createEventModel();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(
                  PlannerHelper.shouldShowCheckbox(
                    context,
                    eventItem,
                    PlannerView.month,
                  ),
                  isFalse,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns true for HomeworkModel on non-mobile', (
        tester,
      ) async {
        final homeworkItem = _createHomeworkModel();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Builder(
              builder: (context) {
                expect(
                  PlannerHelper.shouldShowCheckbox(
                    context,
                    homeworkItem,
                    PlannerView.week,
                  ),
                  isTrue,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns false for HomeworkModel on mobile week/day view', (
        tester,
      ) async {
        final homeworkItem = _createHomeworkModel();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(
                  PlannerHelper.shouldShowCheckbox(
                    context,
                    homeworkItem,
                    PlannerView.week,
                  ),
                  isFalse,
                );
                expect(
                  PlannerHelper.shouldShowCheckbox(
                    context,
                    homeworkItem,
                    PlannerView.day,
                  ),
                  isFalse,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns true for HomeworkModel on mobile month view', (
        tester,
      ) async {
        final homeworkItem = _createHomeworkModel();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(
                  PlannerHelper.shouldShowCheckbox(
                    context,
                    homeworkItem,
                    PlannerView.month,
                  ),
                  isTrue,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });
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
    color: const Color(0xFF4CAF50),
  );
}

HomeworkModel _createHomeworkModel({bool allDay = false}) {
  return HomeworkModel(
    id: 1,
    title: 'Test Homework',
    allDay: allDay,
    showEndTime: true,
    start: DateTime.parse('2025-01-15T10:00:00Z'),
    end: DateTime.parse('2025-01-15T11:00:00Z'),
    priority: 50,
    comments: '',
    attachments: [],
    reminders: [],
    completed: false,
    currentGrade: '-1/100',
    course: IdOrEntity<CourseModel>(id: 1),
    category: IdOrEntity<CategoryModel>(id: 1),
    resources: [],
  );
}
