import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

void main() {
  group('GradeHelper', () {
    group('largestRemainderPercents', () {
      test('gives the leftover point to the largest fractional share', () {
        // GIVEN
        final categories = [
          _category(id: 1, gradeByWeight: 50.5),
          _category(id: 2, gradeByWeight: 30.3),
          _category(id: 3, gradeByWeight: 19.2),
        ];

        // WHEN
        final percents = GradeHelper.largestRemainderPercents(categories, 100);

        // THEN
        expect(percents, {1: 51, 2: 30, 3: 19});
      });

      test('rounded shares always sum to 100', () {
        // GIVEN
        final categories = [
          _category(id: 1, gradeByWeight: 1),
          _category(id: 2, gradeByWeight: 1),
          _category(id: 3, gradeByWeight: 1),
        ];

        // WHEN
        final percents = GradeHelper.largestRemainderPercents(categories, 3);

        // THEN
        expect(percents.values.reduce((a, b) => a + b), 100);
        expect(percents.values.toSet(), {33, 34});
      });

      test('leaves out categories with no weighted grade', () {
        // GIVEN
        final categories = [
          _category(id: 1, gradeByWeight: 40),
          _category(id: 2, gradeByWeight: null),
          _category(id: 3, gradeByWeight: 0),
          _category(id: 4, gradeByWeight: 60),
        ];

        // WHEN
        final percents = GradeHelper.largestRemainderPercents(categories, 100);

        // THEN
        expect(percents, {1: 40, 4: 60});
      });
    });
  });
}

GradeCategoryModel _category({required int id, required double? gradeByWeight}) {
  return GradeCategoryModel(
    id: id,
    title: 'Category $id',
    overallGrade: 90,
    weight: 25,
    color: const Color(0xFF2196F3),
    gradeByWeight: gradeByWeight,
    numHomework: 1,
    numHomeworkGraded: 1,
    pointsEarned: 9,
    pointsPossible: 10,
    homeworkSeries: const [],
  );
}
