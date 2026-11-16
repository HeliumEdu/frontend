import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/grade_point_label.dart';

void main() {
  Future<void> pumpLabel(
    WidgetTester tester,
    GradePointLabel label, {
    double width = 1200,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: label),
      ),
    );
  }

  group('GradePointLabel', () {
    testWidgets('shows the letter grade beside the grade point', (tester) async {
      // GIVEN
      await pumpLabel(
        tester,
        const GradePointLabel(gradePoint: 3.3, credits: 3, letterGrade: 'B+'),
      );

      // THEN
      expect(find.text('B+ • 3.30 GP'), findsOneWidget);
    });

    testWidgets('shows only the letter grade for a class without credits', (tester) async {
      // GIVEN
      await pumpLabel(
        tester,
        const GradePointLabel(gradePoint: 3.3, credits: 0, letterGrade: 'B+'),
      );

      // THEN
      expect(find.text('B+'), findsOneWidget);
    });

    testWidgets('shows only the letter grade on a narrow phone', (tester) async {
      // GIVEN
      await pumpLabel(
        tester,
        const GradePointLabel(gradePoint: 3.3, credits: 3, letterGrade: 'B+'),
        width: 375,
      );

      // THEN
      expect(find.text('B+'), findsOneWidget);
    });

    testWidgets('shows nothing on a narrow phone when the scale has no letters', (tester) async {
      // GIVEN
      await pumpLabel(
        tester,
        const GradePointLabel(gradePoint: 2.5, credits: 3, letterGrade: ''),
        width: 375,
      );

      // THEN
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows only the grade point when the scale has no letters', (tester) async {
      // GIVEN
      await pumpLabel(
        tester,
        const GradePointLabel(gradePoint: 2.5, credits: 3, letterGrade: ''),
      );

      // THEN
      expect(find.text('2.50 GP'), findsOneWidget);
    });
  });
}
