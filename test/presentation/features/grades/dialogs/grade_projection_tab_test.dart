import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_gpa.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_projection_tab.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../../../mocks/mock_models.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  Future<void> pumpTab(
    WidgetTester tester,
    String timeZone,
    DateTime start, {
    double categoryAverage = 90,
    double categoryWeight = 100,
    double pointsEarned = 0,
    double pointsPossible = 0,
    GradeCalculatorMode mode = GradeCalculatorMode.classGrade,
    GradeCalculatorGpa? gpa,
  }) async {
    final category = GradeCategoryModel(
      id: 1,
      title: 'Project',
      overallGrade: categoryAverage,
      weight: categoryWeight,
      color: Colors.blue,
      gradeByWeight: categoryAverage,
      numHomework: 1,
      numHomeworkGraded: 0,
      pointsEarned: pointsEarned,
      pointsPossible: pointsPossible,
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
            pointsEarned: pointsEarned,
            pointsPossible: pointsPossible,
            courseColor: Colors.blue,
            userSettings: MockModels.createUserSettings(timeZone: timeZone),
            mode: mode,
            gpa: gpa,
          ),
        ),
      ),
    );
  }

  group('GradeProjectionTab', () {
    testWidgets('in GPA mode, projects the term GPA and its change', (tester) async {
      // GIVEN
      await pumpTab(
        tester,
        'America/New_York',
        DateTime.parse('2026-12-10T16:00:00Z'),
        categoryAverage: 100,
        categoryWeight: 0,
        pointsEarned: 80,
        pointsPossible: 100,
        mode: GradeCalculatorMode.termGpa,
        gpa: MockModels.createGradeCalculatorGpa(),
      );

      // THEN
      expect(
        find.text('Projected GPA: 3.35 (+0.50)'),
        findsOneWidget,
        reason: 'the final starts at its category average (100%): (80 + 100) / 200 = 90%, an A- (3.7); '
            '(3.7 + 3.0) / 2 = 3.35',
      );
      expect(
        find.textContaining('Projected grade'),
        findsNothing,
        reason: 'Term GPA mode projects only the GPA; the class grade belongs to Class grade mode',
      );
    });

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
