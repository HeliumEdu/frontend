// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

// Grading math is also implemented in the backend at
// projects/platform/helium/planner/services/gradingservice.py (the source of
// truth for actual grades). This file operates on category aggregates the
// backend produces — it does NOT recompute course grades from raw homework.
// The "What Grade Do I Need?" inverse calculation below is frontend-only.
// If you change the weighted-grade math here, audit gradingservice.py for
// consistency. Both sides have their own test suites covering the math at
// their respective layers.

import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';

/// Result of a "what grade do I need" calculation
enum NeededGradeState {
  achievable,
  aboveTarget,
  unachievable,
  targetCategoryHasNoWeight,
  invalidTotalWeight,
}

class NeededGradeResult {
  final double neededGrade;
  final NeededGradeState state;
  final double? totalWeightAccountedFor;

  bool get isAchievable =>
      state == NeededGradeState.achievable ||
      state == NeededGradeState.aboveTarget;

  NeededGradeResult({
    required this.neededGrade,
    required this.state,
    this.totalWeightAccountedFor,
  });
}

class GradeHelper {
  // Category grades may come in either 0-100 or 0-1 scale depending on source.
  // Normalize into percentage before weighted-grade math.
  static double _normalizedCategoryGrade(double overallGrade) {
    if (overallGrade < 0) {
      return overallGrade;
    }
    return overallGrade <= 1 ? overallGrade * 100 : overallGrade;
  }

  /// Calculates what grade is needed in a specific category to achieve
  /// a desired overall grade.
  ///
  /// Formula:
  /// neededGrade = (desiredOverallGrade * 100 - sumOfOtherWeightedGrades) / targetCategoryWeight
  ///
  /// Example:
  /// - Category A: weight 30%, grade 80%
  /// - Category B: weight 40%, grade 90%
  /// - Category C (Final): weight 30%, grade unknown
  /// - Desired overall: 85%
  ///
  /// Calculation:
  /// neededGrade = (85 * 100 - (30*80 + 40*90)) / 30
  ///             = (8500 - 6000) / 30
  ///             = 83.33%
  ///
  /// [categories] - All categories in the course
  /// [targetCategoryId] - The category ID to calculate the needed grade for
  /// [desiredOverallGrade] - The desired overall grade (0-100)
  ///
  /// Returns a [NeededGradeResult] with:
  /// - neededGrade: The grade needed in the target category
  /// - state: Outcome state used by the UI to construct messaging
  static NeededGradeResult calculateNeededGrade({
    required List<GradeCategoryModel> categories,
    required int targetCategoryId,
    required double desiredOverallGrade,
  }) {
    final targetCategory = categories.firstWhere(
      (cat) => cat.id == targetCategoryId,
      orElse: () => throw ArgumentError('Category not found'),
    );

    if (targetCategory.weight <= 0) {
      return NeededGradeResult(
        neededGrade: 0,
        state: NeededGradeState.targetCategoryHasNoWeight,
      );
    }

    double sumOfOtherWeightedGrades = 0;
    double totalWeightAccountedFor = targetCategory.weight;

    for (final category in categories) {
      if (category.id == targetCategoryId) continue;

      if (category.weight > 0) {
        totalWeightAccountedFor += category.weight;

        if (category.overallGrade >= 0) {
          sumOfOtherWeightedGrades +=
              category.weight * _normalizedCategoryGrade(category.overallGrade);
        }
        // Ungraded categories contribute 0 (pessimistic default).
      }
    }

    if ((totalWeightAccountedFor - 100).abs() > 0.01) {
      return NeededGradeResult(
        neededGrade: 0,
        state: NeededGradeState.invalidTotalWeight,
        totalWeightAccountedFor: totalWeightAccountedFor,
      );
    }

    // (desiredOverallGrade * 100 - Σ other weighted grades) / targetWeight
    final neededGrade =
        (desiredOverallGrade * 100 - sumOfOtherWeightedGrades) /
        targetCategory.weight;

    if (neededGrade < 0) {
      return NeededGradeResult(
        neededGrade: neededGrade,
        state: NeededGradeState.aboveTarget,
      );
    } else if (neededGrade > 100) {
      return NeededGradeResult(
        neededGrade: neededGrade,
        state: NeededGradeState.unachievable,
      );
    } else {
      return NeededGradeResult(
        neededGrade: neededGrade,
        state: NeededGradeState.achievable,
      );
    }
  }

  /// Projects an overall grade given hypothetical scores for ungraded assignments.
  /// [projections] maps assignment ID to a hypothetical score as a percentage (0–100).
  ///
  /// Returns the projected grade as a percentage (0–100), or -1 when there is
  /// insufficient data to compute a result (no assignments, no weight).
  static double calculateProjectedGrade({
    required List<GradeCategoryModel> categories,
    required List<HomeworkSeriesItemModel> ungradedAssignments,
    required Map<int, double> projections,
  }) {
    final hasWeightedGrading = categories.any((c) => c.weight > 0);
    return hasWeightedGrading
        ? _projectedWeighted(categories, ungradedAssignments, projections)
        : _projectedPoints(categories, ungradedAssignments, projections);
  }

  static double _projectedWeighted(
    List<GradeCategoryModel> categories,
    List<HomeworkSeriesItemModel> ungradedAssignments,
    Map<int, double> projections,
  ) {
    double totalContribution = 0.0;
    double totalWeight = 0.0;

    for (final category in categories) {
      if (category.weight <= 0) continue;

      final catUngraded =
          ungradedAssignments.where((item) => item.categoryId == category.id).toList();
      final totalUngradedPossible =
          catUngraded.fold(0.0, (sum, item) => sum + (item.pointsPossible ?? 0));

      final hasActualGrade = category.overallGrade >= 0 && category.numHomeworkGraded > 0;

      final double categoryGrade;

      if (catUngraded.isEmpty) {
        if (!hasActualGrade) continue;
        categoryGrade = category.overallGrade;
      } else {
        final earnedFromUngraded = catUngraded.fold(
          0.0,
          (sum, item) => sum + (projections[item.id] ?? 0) / 100.0 * (item.pointsPossible ?? 0),
        );

        if (hasActualGrade) {
          final avgPP = totalUngradedPossible / catUngraded.length;
          final totalGradedPossible = category.numHomeworkGraded * avgPP;
          final earnedFromGraded = category.overallGrade / 100.0 * totalGradedPossible;
          final totalPossible = totalGradedPossible + totalUngradedPossible;
          categoryGrade = totalPossible > 0
              ? (earnedFromGraded + earnedFromUngraded) / totalPossible * 100
              : 0;
        } else {
          categoryGrade = totalUngradedPossible > 0
              ? earnedFromUngraded / totalUngradedPossible * 100
              : 0;
        }
      }

      totalContribution += categoryGrade * category.weight / 100.0;
      totalWeight += category.weight;
    }

    return totalWeight > 0 ? totalContribution / totalWeight * 100 : -1;
  }

  static double _projectedPoints(
    List<GradeCategoryModel> categories,
    List<HomeworkSeriesItemModel> ungradedAssignments,
    Map<int, double> projections,
  ) {
    double totalEarned = 0.0;
    double totalPossible = 0.0;

    for (final category in categories) {
      if (category.overallGrade < 0 || category.numHomeworkGraded <= 0) continue;

      final catUngraded =
          ungradedAssignments.where((item) => item.categoryId == category.id).toList();
      // Approximate each graded assignment's worth using ungraded items as a reference.
      // Fall back to 100 pts when no ungraded reference exists in this category.
      final avgPP = catUngraded.isEmpty
          ? 100.0
          : catUngraded.fold(0.0, (s, i) => s + (i.pointsPossible ?? 0)) / catUngraded.length;

      final gradedPossible = category.numHomeworkGraded * avgPP;
      totalEarned += category.overallGrade / 100.0 * gradedPossible;
      totalPossible += gradedPossible;
    }

    for (final item in ungradedAssignments) {
      final pp = item.pointsPossible ?? 0;
      if (pp <= 0) continue;
      totalEarned += (projections[item.id] ?? 0) / 100.0 * pp;
      totalPossible += pp;
    }

    return totalPossible > 0 ? totalEarned / totalPossible * 100 : -1;
  }

  /// Parses a grade value from various formats (strings like "X/Y", numbers, etc.)
  /// Returns the grade as a percentage (0-100) or null if invalid/not graded
  static double? parseGrade(dynamic grade) {
    if (grade == null ||
        grade == '' ||
        grade == '-1/100' ||
        grade == 0 ||
        grade == -1.0) {
      return null;
    }

    if (grade is String) {
      try {
        final split = grade.split('/');
        if (split.length == 2) {
          return (double.parse(split[0]) / double.parse(split[1])) * 100;
        }
        return null;
      } catch (e) {
        return null;
      }
    } else if (grade is num) {
      return grade.toDouble();
    }

    return null;
  }

  /// Formats a grade value for display as a percentage
  /// Returns 'N/A' or blank if the grade is null/invalid
  static String gradeForDisplay(dynamic grade, [bool showNaAsBlank = false]) {
    final gradeValue = parseGrade(grade);

    if (gradeValue == null) {
      return showNaAsBlank ? '' : 'N/A';
    }

    return '${gradeValue.toStringAsFixed(2)}%';
  }

  /// Formats a percentage value for display (e.g., category weights)
  /// Optionally shows 'N/A' for zero values
  static String percentForDisplay(String value, bool? zeroAsNa) {
    try {
      final percentage = double.parse(value);
      if (percentage == 0 && zeroAsNa != null && zeroAsNa) {
        return 'N/A';
      }
      if (percentage == percentage.roundToDouble()) {
        return '${percentage.toInt()}%';
      }
      return '${percentage.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}%';
    } catch (e) {
      return 'N/A';
    }
  }
}
