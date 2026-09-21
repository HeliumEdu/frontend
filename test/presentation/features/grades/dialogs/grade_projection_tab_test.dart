import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_projection_tab.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../../../mocks/mock_models.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  Future<void> pumpTab(WidgetTester tester, String timeZone, DateTime start) async {
    final category = GradeCategoryModel(
      id: 1,
      title: 'Project',
      overallGrade: 90,
      weight: 100,
      color: Colors.blue,
      gradeByWeight: 90,
      numHomework: 1,
      numHomeworkGraded: 0,
      homeworkSeries: const [],
    );
    final assignment = HomeworkSeriesItemModel(
      id: 10,
      title: 'Final Project',
      start: start,
      categoryId: 1,
      courseId: 1,
      pointsPossible: 100,
      graded: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: GradeProjectionTab(
            categories: [category],
            ungradedAssignments: [assignment],
            currentOverallGrade: 90,
            courseTitle: 'Fundamentals of Programming',
            courseColor: Colors.blue,
            userSettings: MockModels.createUserSettings(timeZone: timeZone),
          ),
        ),
      ),
    );
  }

  group('GradeProjectionTab', () {
    testWidgets('renders an all-day due date on the user\'s calendar day at a positive offset', (
      tester,
    ) async {
      // GIVEN
      final amsterdamMidnight = DateTime.parse('2026-09-24T22:00:00Z');

      // WHEN
      await pumpTab(tester, 'Europe/Amsterdam', amsterdamMidnight);

      // THEN
      expect(find.text('Fri, Sep 25'), findsOneWidget);
      expect(find.text('Thu, Sep 24'), findsNothing);
    });

    testWidgets('renders an all-day due date unchanged at a negative offset', (
      tester,
    ) async {
      // GIVEN
      final losAngelesMidnight = DateTime.parse('2026-09-25T07:00:00Z');

      // WHEN
      await pumpTab(tester, 'America/Los_Angeles', losAngelesMidnight);

      // THEN
      expect(find.text('Fri, Sep 25'), findsOneWidget);
    });
  });
}
