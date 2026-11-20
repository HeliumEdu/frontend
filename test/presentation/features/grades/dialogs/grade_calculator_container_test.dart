import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_bloc.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_container.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

import '../../../../mocks/mock_models.dart';
import '../../../../mocks/mock_repositories.dart';

void main() {
  final plusMinus = GradeScaleTemplate.scales[2]!;

  GradeCourseModel givenCourse({double credits = 3, bool withScale = true}) =>
      MockModels.createGradeCourse(
        overallGrade: 80,
        credits: credits,
        gradePoint: withScale ? 2.7 : null,
        gradeScale: withScale ? plusMinus : const [],
        homeworkSeries: [
          HomeworkSeriesItemModel(
            id: 9,
            title: 'Final',
            start: DateTime.parse('2026-12-10T16:00:00Z'),
            categoryId: 2,
            courseId: 1,
            pointsPossible: 100,
            graded: false,
          ),
        ],
      );

  Future<void> pumpContainer(WidgetTester tester, GradeCourseModel course) async {
    final gradeBloc = GradeBloc(
      gradeRepository: MockGradeRepository(),
      courseRepository: MockCourseRepository(),
    );
    addTearDown(gradeBloc.close);
    final other = MockModels.createGradeCourse(id: 5, credits: 3, gradePoint: 3.0, gradeScale: plusMinus);
    final group = MockModels.createGradeCourseGroup(gpa: 2.85, courses: [course, other]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BlocProvider<GradeBloc>.value(
            value: gradeBloc,
            child: GradeCalculatorContainer(
              course: course,
              courseGroups: [group],
              userSettings: MockModels.createUserSettings(),
            ),
          ),
        ),
      ),
    );
  }

  group('GradeCalculatorContainer', () {
    testWidgets('shows the class grade point beside its grade', (tester) async {
      // GIVEN
      await pumpContainer(tester, givenCourse());

      // THEN
      expect(find.text('2.70 GP'), findsOneWidget);
    });

    testWidgets('switches to Term GPA', (tester) async {
      // GIVEN
      await pumpContainer(tester, givenCourse());

      // WHEN
      await tester.tap(find.text('Class grade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Term GPA').last);
      await tester.pumpAndSettle();

      // THEN
      expect(find.textContaining('Projected GPA:'), findsOneWidget);
    });

    testWidgets('disables Term GPA and says why when the class has no credits', (tester) async {
      // GIVEN
      await pumpContainer(tester, givenCourse(credits: 0));

      // WHEN
      await tester.tap(find.text('Class grade'));
      await tester.pumpAndSettle();

      // THEN
      expect(find.text('Add credits to this class to use GPA.'), findsOneWidget);
      expect(find.text('Term GPA'), findsNothing, reason: 'the disabled drop-down does not open');
    });

    testWidgets('hides the Calculate for drop-down when the group has no grade scale', (tester) async {
      // GIVEN
      await pumpContainer(tester, givenCourse(withScale: false));

      // THEN
      expect(find.text('Calculate for'), findsNothing,
          reason: 'with no grade scale there is no GPA to calculate, as on the Grades page');
      expect(find.text('Class grade'), findsNothing);
    });
  });
}
