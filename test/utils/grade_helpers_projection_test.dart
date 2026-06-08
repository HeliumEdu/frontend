// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

void main() {
  group('GradeHelper.calculateProjectedGrade', () {
    group('weighted course', () {
      test('all ungraded, no prior grades, all perfect → 100%', () {
        // GIVEN two categories with ungraded assignments and no prior graded work
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 60, grade: -1),
          _createCategory(id: 2, title: 'Homework', weight: 40, grade: -1),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 100),
          _createAssignment(id: 2, categoryId: 2, pointsPossible: 50),
        ];
        final projections = {1: 100.0, 2: 100.0};

        // WHEN projecting with all perfect scores
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN projected grade is 100%
        expect(result, closeTo(100.0, 0.01));
      });

      test('no prior grades, mixed scores → correct weighted average', () {
        // GIVEN two weighted categories with ungraded assignments and no graded history
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 60, grade: -1),
          _createCategory(id: 2, title: 'Homework', weight: 40, grade: -1),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 100),
          _createAssignment(id: 2, categoryId: 2, pointsPossible: 100),
        ];
        final projections = {1: 80.0, 2: 90.0};

        // WHEN projecting
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN 60%*80% + 40%*90% = 84%
        expect(result, closeTo(84.0, 0.01));
      });

      test('no graded work yet → uses projections only', () {
        // GIVEN category with no graded work and one ungraded assignment
        final categories = [
          _createCategory(
            id: 1,
            title: 'Tests',
            weight: 100,
            grade: -1,
            numHomework: 1,
            numHomeworkGraded: 0,
          ),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 100),
        ];
        final projections = {1: 75.0};

        // WHEN projecting with no prior grades
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN result equals the projected score
        expect(result, closeTo(75.0, 0.01));
      });

      test('mixed graded and ungraded → blends actual + hypothetical', () {
        // GIVEN category with 80% grade on 2 graded assignments and 1 ungraded
        final categories = [
          _createCategory(
            id: 1,
            title: 'Tests',
            weight: 100,
            grade: 80.0,
            numHomework: 3,
            numHomeworkGraded: 2,
          ),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 100),
        ];
        final projections = {1: 100.0};

        // WHEN computing projection
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN:
        // avgPP = 100, totalGradedPossible = 2 * 100 = 200
        // earnedFromGraded = 80/100 * 200 = 160
        // earnedFromUngraded = 100/100 * 100 = 100
        // total = (160 + 100) / (200 + 100) * 100 = 260/300 * 100 ≈ 86.67
        expect(result, closeTo(86.67, 0.01));
      });

      test('no ungraded assignments → returns actual grade', () {
        // GIVEN one fully graded category with no ungraded work
        final categories = [
          _createCategory(
            id: 1,
            title: 'Tests',
            weight: 100,
            grade: 88.0,
            numHomework: 3,
            numHomeworkGraded: 3,
          ),
        ];

        // WHEN projecting with no ungraded assignments
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: [],
          projections: {},
        );

        // THEN result is the actual grade unchanged
        expect(result, closeTo(88.0, 0.01));
      });

      test('multi-category, one fully-graded + one with ungraded → both contribute', () {
        // GIVEN one fully-graded category and one with a single ungraded assignment
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 60, grade: 90.0, numHomework: 3, numHomeworkGraded: 3),
          _createCategory(id: 2, title: 'Final', weight: 40, grade: -1),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 2, pointsPossible: 200),
        ];
        final projections = {1: 80.0};

        // WHEN projecting
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN both categories contribute:
        // Tests: grade = 90% (actual, no ungraded)
        // Final: grade = 80% (projected only)
        // weighted = (90*60 + 80*40) / 100 = 86%
        expect(result, closeTo(86.0, 0.01));
      });

      test('zero-weight category is excluded', () {
        // GIVEN one weighted and one unweighted category
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 100, grade: -1),
          _createCategory(id: 2, title: 'Extra Credit', weight: 0, grade: -1),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 100),
          _createAssignment(id: 2, categoryId: 2, pointsPossible: 100),
        ];
        final projections = {1: 70.0, 2: 100.0};

        // WHEN projecting
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN only the weighted category contributes
        expect(result, closeTo(70.0, 0.01));
      });
    });

    group('non-weighted course', () {
      test('all ungraded, no prior grades, all perfect → 100%', () {
        // GIVEN non-weighted categories (weight 0) with ungraded assignments
        final categories = [
          _createCategory(id: 1, title: 'Assignments', weight: 0, grade: -1),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 100),
          _createAssignment(id: 2, categoryId: 1, pointsPossible: 50),
        ];
        final projections = {1: 100.0, 2: 100.0};

        // WHEN projecting with all perfect scores
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        expect(result, closeTo(100.0, 0.01));
      });

      test('blends graded and projected points', () {
        // GIVEN category with 80% on 2 graded items (each assumed 100 pts), 1 ungraded 100 pts
        final categories = [
          _createCategory(
            id: 1,
            title: 'Work',
            weight: 0,
            grade: 80.0,
            numHomework: 3,
            numHomeworkGraded: 2,
          ),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 100),
        ];
        final projections = {1: 100.0};

        // WHEN computing projection
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN: avgPP=100, graded: 2*100=200, earned=0.80*200=160
        // ungraded: 1*100=100, earned=100
        // total: 260/300 ≈ 86.67
        expect(result, closeTo(86.67, 0.01));
      });
    });

    group('edge cases', () {
      test('zero pointsPossible assignment is skipped', () {
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 100, grade: -1),
        ];
        final ungraded = [
          _createAssignment(id: 1, categoryId: 1, pointsPossible: 0),
          _createAssignment(id: 2, categoryId: 1, pointsPossible: 100),
        ];
        final projections = {1: 100.0, 2: 80.0};

        // WHEN projecting with a zero-possible item
        final result = GradeHelper.calculateProjectedGrade(
          categories: categories,
          ungradedAssignments: ungraded,
          projections: projections,
        );

        // THEN zero-possible item contributes nothing
        expect(result, closeTo(80.0, 0.01));
      });

      test('no assignments at all → returns -1', () {
        final result = GradeHelper.calculateProjectedGrade(
          categories: [],
          ungradedAssignments: [],
          projections: {},
        );

        expect(result, -1);
      });
    });
  });
}

GradeCategoryModel _createCategory({
  required int id,
  required String title,
  required double weight,
  required double grade,
  int numHomework = 0,
  int numHomeworkGraded = 0,
}) {
  return GradeCategoryModel(
    id: id,
    title: title,
    overallGrade: grade,
    weight: weight,
    color: const Color(0xFF000000),
    gradeByWeight: grade >= 0 ? (weight * grade / 100) : null,
    trend: null,
    numHomework: numHomework,
    numHomeworkGraded: numHomeworkGraded,
    homeworkSeries: [],
  );
}

HomeworkSeriesItemModel _createAssignment({
  required int id,
  required int categoryId,
  required double pointsPossible,
}) {
  return HomeworkSeriesItemModel(
    id: id,
    title: 'Assignment $id',
    start: DateTime(2025, 5, id),
    categoryId: categoryId,
    courseId: 1,
    pointsPossible: pointsPossible,
    graded: false,
    homeworkGrade: null,
    cumulativeGrade: null,
    impactScore: null,
  );
}
