import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_bloc.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_models.dart';
import '../../../../mocks/mock_repositories.dart';

void main() {
  late MockGradeRepository gradeRepository;

  setUp(() {
    gradeRepository = MockGradeRepository();
  });

  Future<void> pumpDialog(WidgetTester tester) async {
    final gradeBloc = GradeBloc(
      gradeRepository: gradeRepository,
      courseRepository: MockCourseRepository(),
    );
    addTearDown(gradeBloc.close);
    final exams = GradeCategoryModel(
      id: 2,
      title: 'Exams',
      overallGrade: 80,
      weight: 40,
      color: Colors.blue,
      gradeByWeight: 32,
      numHomework: 2,
      numHomeworkGraded: 1,
      pointsEarned: 40,
      pointsPossible: 50,
      homeworkSeries: const [],
    );
    final finalExam = HomeworkSeriesItemModel(
      id: 9,
      title: 'Final',
      start: DateTime.parse('2026-12-10T16:00:00Z'),
      categoryId: 2,
      courseId: 1,
      pointsPossible: 100,
      graded: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BlocProvider<GradeBloc>.value(
            value: gradeBloc,
            child: SizedBox(
              height: 600,
              child: GradeCalculatorDialog(
                courseId: 1,
                categories: [exams],
                ungradedAssignments: [finalExam],
                currentOverallGrade: 80,
                courseTitle: 'Fundamentals of Programming',
                courseColor: Colors.blue,
                userSettings: MockModels.createUserSettings(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NeededGradeModel givenAchievableResult() => NeededGradeModel(
    state: NeededGradeState.achievable,
    neededGrade: 77.5,
    weighted: true,
    assignment: NeededGradeAssignmentModel(
      id: 9,
      title: 'Final',
      pointsPossible: 100,
      neededPoints: 77.5,
    ),
  );

  group('GradeCalculatorDialog', () {
    testWidgets('asks the backend for the needed grade and shows it', (
      tester,
    ) async {
      // GIVEN
      when(
        () => gradeRepository.getNeededGrade(
          courseId: 1,
          targetId: 2,
          desiredGrade: 85,
        ),
      ).thenAnswer((_) async => givenAchievableResult());
      await pumpDialog(tester);

      // WHEN
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // THEN
      verify(
        () => gradeRepository.getNeededGrade(
          courseId: 1,
          targetId: 2,
          desiredGrade: 85,
        ),
      ).called(1);
      expect(
        find.textContaining('77.5 / 100 points) on "Final"'),
        findsOneWidget,
      );
    });

    testWidgets('shows the backend\'s error when the calculation fails', (
      tester,
    ) async {
      // GIVEN
      when(
        () => gradeRepository.getNeededGrade(
          courseId: any(named: 'courseId'),
          targetId: any(named: 'targetId'),
          desiredGrade: any(named: 'desiredGrade'),
        ),
      ).thenThrow(
        ServerException(message: 'Failed to calculate needed grade.'),
      );
      await pumpDialog(tester);

      // WHEN
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // THEN
      expect(
        find.textContaining('Failed to calculate needed grade.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'ignores a result for a grade changed while it was calculating',
      (tester) async {
        // GIVEN
        final pending = Completer<NeededGradeModel>();
        when(
          () => gradeRepository.getNeededGrade(
            courseId: 1,
            targetId: 2,
            desiredGrade: 85,
          ),
        ).thenAnswer((_) => pending.future);
        await pumpDialog(tester);
        await tester.tap(find.text('Calculate'));
        await tester.pump();

        // WHEN
        await tester.enterText(find.byType(TextField), '90');
        pending.complete(givenAchievableResult());
        await tester.pumpAndSettle();

        // THEN
        expect(
          find.textContaining('77.5 / 100 points'),
          findsNothing,
          reason: 'the result answers 85%, not the 90% now entered',
        );
      },
    );
  });
}
