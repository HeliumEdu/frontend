// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

void main() {
  group('GradeHelper', () {
    group('parseGrade', () {
      test('parses numeric grades', () {
        expect(GradeHelper.parseGrade(85.5), 85.5);
        expect(GradeHelper.parseGrade(90), 90.0);
      });

      test('parses fraction strings to percentage', () {
        expect(GradeHelper.parseGrade('85/100'), 85.0);
        expect(GradeHelper.parseGrade('17/20'), 85.0);
        expect(GradeHelper.parseGrade('8.5/10'), 85.0);
      });

      test('returns null for ungraded markers', () {
        expect(GradeHelper.parseGrade(null), null);
        expect(GradeHelper.parseGrade(''), null);
        expect(GradeHelper.parseGrade('-1/100'), null);
        expect(GradeHelper.parseGrade(0), null);
        expect(GradeHelper.parseGrade(-1.0), null);
      });

      test('returns null for invalid input', () {
        expect(GradeHelper.parseGrade('invalid'), null);
        expect(GradeHelper.parseGrade('85/'), null);
      });
    });

    group('gradeForDisplay', () {
      test('formats grades as percentage with 2 decimals', () {
        expect(GradeHelper.gradeForDisplay(85.5), '85.50%');
        expect(GradeHelper.gradeForDisplay(90), '90.00%');
        expect(GradeHelper.gradeForDisplay('17/20'), '85.00%');
        expect(GradeHelper.gradeForDisplay(100.0), '100.00%');
      });

      test('returns N/A for invalid/ungraded values', () {
        expect(GradeHelper.gradeForDisplay(null), 'N/A');
        expect(GradeHelper.gradeForDisplay(0), 'N/A');
        expect(GradeHelper.gradeForDisplay(-1.0), 'N/A');
      });

      test('returns blank when showNaAsBlank is true', () {
        expect(GradeHelper.gradeForDisplay(null, true), '');
        expect(GradeHelper.gradeForDisplay('-1/100', true), '');
      });
    });

    group('percentForDisplay', () {
      test('formats percentages removing trailing zeros', () {
        expect(GradeHelper.percentForDisplay('85', null), '85%');
        expect(GradeHelper.percentForDisplay('85.5', null), '85.5%');
        expect(GradeHelper.percentForDisplay('85.50', null), '85.5%');
        expect(GradeHelper.percentForDisplay('85.00', null), '85%');
        expect(GradeHelper.percentForDisplay('0.01', null), '0.01%');
      });

      test('handles zero with zeroAsNa flag', () {
        expect(GradeHelper.percentForDisplay('0', true), 'N/A');
        expect(GradeHelper.percentForDisplay('0', false), '0%');
      });

      test('returns N/A for invalid input', () {
        expect(GradeHelper.percentForDisplay('invalid', null), 'N/A');
        expect(GradeHelper.percentForDisplay('', null), 'N/A');
      });
    });

    group('calculateNeededGrade', () {
      test('calculates basic needed grade', () {
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 30, grade: 80),
          _createCategory(id: 2, title: 'Homework', weight: 40, grade: 90),
          _createCategory(id: 3, title: 'Final', weight: 30, grade: -1),
        ];

        final result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 3,
          desiredOverallGrade: 85,
        );

        expect(result.isAchievable, true);
        expect(result.neededGrade, closeTo(83.33, 0.01));
      });

      test('detects already above target (negative needed grade)', () {
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 70, grade: 95),
          _createCategory(id: 2, title: 'Final', weight: 30, grade: -1),
        ];

        final result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 2,
          desiredOverallGrade: 60,
        );

        expect(result.isAchievable, true);
        expect(result.neededGrade, lessThan(0));
        expect(result.message, contains('already above'));
      });

      test('detects unachievable grade (over 100%)', () {
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 60, grade: 70),
          _createCategory(id: 2, title: 'Final', weight: 40, grade: -1),
        ];

        final result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 2,
          desiredOverallGrade: 95,
        );

        expect(result.isAchievable, false);
        expect(result.neededGrade, greaterThan(100));
      });

      test('handles boundary conditions (0% and 100%)', () {
        // Exactly 100% needed
        var categories = [
          _createCategory(id: 1, title: 'Tests', weight: 50, grade: 80),
          _createCategory(id: 2, title: 'Final', weight: 50, grade: -1),
        ];

        var result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 2,
          desiredOverallGrade: 90,
        );

        expect(result.isAchievable, true);
        expect(result.neededGrade, closeTo(100, 0.01));

        // Exactly 0% needed
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 70, grade: 100),
          _createCategory(id: 2, title: 'Final', weight: 30, grade: -1),
        ];

        result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 2,
          desiredOverallGrade: 70,
        );

        expect(result.isAchievable, true);
        expect(result.neededGrade, closeTo(0, 0.01));
      });

      test('assumes 0% for other ungraded categories (pessimistic)', () {
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 30, grade: 80),
          _createCategory(id: 2, title: 'Homework', weight: 40, grade: -1),
          _createCategory(id: 3, title: 'Final', weight: 30, grade: -1),
        ];

        final result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 3,
          desiredOverallGrade: 85,
        );

        // Only Tests contributes, making target unachievable
        expect(result.isAchievable, false);
      });

      test('ignores current target grade (useful for retakes)', () {
        final categories = [
          _createCategory(id: 1, title: 'Tests', weight: 40, grade: 85),
          _createCategory(id: 2, title: 'Homework', weight: 30, grade: 90),
          _createCategory(id: 3, title: 'Final', weight: 30, grade: 88),
        ];

        final result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 3,
          desiredOverallGrade: 90,
        );

        expect(result.isAchievable, true);
        expect(result.neededGrade, closeTo(96.67, 0.01));
      });

      test('validates input constraints', () {
        // Invalid category ID
        var categories = [
          _createCategory(id: 1, title: 'Tests', weight: 50, grade: 80),
        ];

        expect(
          () => GradeHelper.calculateNeededGrade(
            categories: categories,
            targetCategoryId: 999,
            desiredOverallGrade: 85,
          ),
          throwsArgumentError,
        );

        // Zero weight category
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 100, grade: 80),
          _createCategory(id: 2, title: 'Extra', weight: 0, grade: -1),
        ];

        var result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 2,
          desiredOverallGrade: 85,
        );

        expect(result.isAchievable, false);
        expect(result.message, contains('no weight'));

        // Weights don't sum to 100%
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 40, grade: 80),
          _createCategory(id: 2, title: 'Final', weight: 40, grade: -1),
        ];

        result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 2,
          desiredOverallGrade: 85,
        );

        expect(result.isAchievable, false);
        expect(result.message, contains('do not add up to 100%'));

        // Floating point tolerance (should succeed)
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 33.33, grade: 80),
          _createCategory(id: 2, title: 'Homework', weight: 33.34, grade: 90),
          _createCategory(id: 3, title: 'Final', weight: 33.33, grade: -1),
        ];

        result = GradeHelper.calculateNeededGrade(
          categories: categories,
          targetCategoryId: 3,
          desiredOverallGrade: 85,
        );

        expect(result.isAchievable, true);
      });
    });

    group('calculateMaxPossibleGrade', () {
      test('assumes 100% for ungraded, uses actual for graded', () {
        // All graded
        var categories = [
          _createCategory(id: 1, title: 'Tests', weight: 40, grade: 85),
          _createCategory(id: 2, title: 'Homework', weight: 30, grade: 90),
          _createCategory(id: 3, title: 'Final', weight: 30, grade: 88),
        ];

        expect(GradeHelper.calculateMaxPossibleGrade(categories), closeTo(87.4, 0.01));

        // Mixed graded/ungraded
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 50, grade: 80),
          _createCategory(id: 2, title: 'Final', weight: 50, grade: -1),
        ];

        expect(GradeHelper.calculateMaxPossibleGrade(categories), closeTo(90, 0.01));

        // All ungraded
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 50, grade: -1),
          _createCategory(id: 2, title: 'Final', weight: 50, grade: -1),
        ];

        expect(GradeHelper.calculateMaxPossibleGrade(categories), closeTo(100, 0.01));
      });
    });

    group('calculateMinPossibleGrade', () {
      test('assumes 0% for ungraded, uses actual for graded', () {
        // All graded
        var categories = [
          _createCategory(id: 1, title: 'Tests', weight: 40, grade: 85),
          _createCategory(id: 2, title: 'Homework', weight: 30, grade: 90),
          _createCategory(id: 3, title: 'Final', weight: 30, grade: 88),
        ];

        expect(GradeHelper.calculateMinPossibleGrade(categories), closeTo(87.4, 0.01));

        // Mixed graded/ungraded
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 50, grade: 80),
          _createCategory(id: 2, title: 'Final', weight: 50, grade: -1),
        ];

        expect(GradeHelper.calculateMinPossibleGrade(categories), closeTo(40, 0.01));

        // All ungraded
        categories = [
          _createCategory(id: 1, title: 'Tests', weight: 50, grade: -1),
          _createCategory(id: 2, title: 'Final', weight: 50, grade: -1),
        ];

        expect(GradeHelper.calculateMinPossibleGrade(categories), closeTo(0, 0.01));
      });
    });
  });
}

/// Helper to create a test category with minimal required fields
GradeCategoryModel _createCategory({
  required int id,
  required String title,
  required double weight,
  required double grade,
}) {
  return GradeCategoryModel(
    id: id,
    title: title,
    overallGrade: grade,
    weight: weight,
    color: const Color(0xFF000000),
    gradeByWeight: grade >= 0 ? (weight * grade / 100) : null,
    trend: null,
    numHomework: 0,
    numHomeworkGraded: 0,
    gradePoints: [],
  );
}
