import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/presentation/features/grades/widgets/grade_course_card.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

import '../../../../mocks/mock_models.dart';

void main() {
  final gradeScale = GradeScaleTemplate.scales[2]!;
  final defaultLetterGrade = GradeHelper.gradeBandFor(100.22, gradeScale)!.label;
  final weightedCategory = GradeCategoryModel(
    id: 1,
    title: 'Exams',
    overallGrade: 88,
    weight: 40,
    color: Colors.blue,
    gradeByWeight: 35.2,
    numHomework: 12,
    numHomeworkGraded: 12,
    pointsEarned: 0,
    pointsPossible: 0,
    homeworkSeries: const [],
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required double width,
    required double textScale,
    double overallGrade = 100.22,
    int numHomeworkGraded = 99,
  }) async {
    tester.view.physicalSize = Size(width, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 400), textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: GradeCourseCard(
              cardKey: GlobalKey(),
              index: 0,
              course: MockModels.createGradeCourse(
                overallGrade: overallGrade,
                gradePoint: 3.3,
                gradeScale: gradeScale,
                categories: [weightedCategory],
                numHomeworkGraded: numHomeworkGraded,
                trend: 1.5,
              ),
              isExpanded: false,
              isAtRisk: false,
              userSettings: MockModels.createUserSettings(),
              onToggle: () {},
            ),
          ),
        ),
      ),
    );
  }

  bool isShown(Finder finder) => finder.hitTestable().evaluate().isNotEmpty;

  group('GradeCourseCard', () {
    for (final (overallGrade, numHomeworkGraded) in [(100.22, 99), (87.83, 12)]) {
      final letterGrade = GradeHelper.gradeBandFor(overallGrade, gradeScale)!.label;
      final gradedFinder = find.text('$numHomeworkGraded graded');
      final weightedFinder = find.byIcon(Icons.balance);
      final gradePointFinder = find.text('$letterGrade • 3.30 GP');
      final letterOnlyFinder = find.text(letterGrade);

      for (final textScale in [1.0, 1.3]) {
        testWidgets('keeps $overallGrade% and $numHomeworkGraded graded on one line, inside the card, '
            'at text scale $textScale', (tester) async {
          for (var width = 260.0; width <= 520; width += 4) {
            // GIVEN
            await pumpCard(
              tester,
              width: width,
              textScale: textScale,
              overallGrade: overallGrade,
              numHomeworkGraded: numHomeworkGraded,
            );

            // WHEN
            final shownItems = [
              find.byType(GradeLabel),
              find.byIcon(Icons.trending_up),
              gradePointFinder,
              letterOnlyFinder,
              weightedFinder,
              gradedFinder,
            ].where(isShown);
            final rowRight = shownItems.map((finder) => tester.getRect(finder).right).fold(0.0, math.max);
            final rowTops = shownItems.map((finder) => tester.getCenter(finder).dy.round()).toSet();

            // THEN
            expect(tester.takeException(), isNull, reason: 'nothing should overflow at $width px');
            expect(rowRight, lessThanOrEqualTo(tester.getRect(find.byType(GradeExpandButton)).left),
                reason: 'the grade row should end before the expand button at $width px');
            expect(rowTops, hasLength(1), reason: 'the grade row should stay on one line at $width px');
            expect(isShown(find.byType(GradeLabel)) && isShown(find.byIcon(Icons.trending_up)), isTrue,
                reason: 'the grade and trend always show');
            expect(isShown(gradePointFinder) || isShown(letterOnlyFinder), isTrue,
                reason: 'the letter grade always shows');
            if (isShown(weightedFinder)) {
              expect(isShown(gradedFinder), isTrue,
                  reason: 'the weighted icon drops before the graded count at $width px');
            }
            if (isShown(gradedFinder)) {
              expect(isShown(gradePointFinder), isTrue,
                  reason: 'the graded count drops before the grade point at $width px');
            }
          }
        });
      }
    }

    testWidgets('shows every item when the row has room', (tester) async {
      // GIVEN
      await pumpCard(tester, width: 1024, textScale: 1);

      // THEN
      expect(isShown(find.text('99 graded')), isTrue);
      expect(isShown(find.byIcon(Icons.balance)), isTrue);
      expect(isShown(find.text('$defaultLetterGrade • 3.30 GP')), isTrue);
    });

    testWidgets('keeps only the grade, trend and letter grade when the row is at its narrowest', (tester) async {
      // GIVEN
      await pumpCard(tester, width: 260, textScale: 1.3);

      // THEN
      expect(isShown(find.byIcon(Icons.balance)), isFalse);
      expect(isShown(find.text('99 graded')), isFalse);
      expect(isShown(find.text(defaultLetterGrade)), isTrue, reason: 'the letter grade stays once the grade point drops');
    });
  });
}
