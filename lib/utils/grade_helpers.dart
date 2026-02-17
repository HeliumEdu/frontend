// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/grade_category_model.dart';

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
    // Find target category
    final targetCategory = categories.firstWhere(
      (cat) => cat.id == targetCategoryId,
      orElse: () => throw ArgumentError('Category not found'),
    );

    // Validate target category has weight
    if (targetCategory.weight <= 0) {
      return NeededGradeResult(
        neededGrade: 0,
        state: NeededGradeState.targetCategoryHasNoWeight,
      );
    }

    // Calculate sum of weighted grades from other categories
    double sumOfOtherWeightedGrades = 0;
    double totalWeightAccountedFor = targetCategory.weight;

    for (final category in categories) {
      if (category.id == targetCategoryId) {
        continue; // Skip target category
      }

      // Only include categories with weight
      if (category.weight > 0) {
        totalWeightAccountedFor += category.weight;

        // If category has a grade, include it in calculation
        if (category.overallGrade >= 0) {
          sumOfOtherWeightedGrades +=
              category.weight * _normalizedCategoryGrade(category.overallGrade);
        }
        // If no grade yet, we assume 0 (worst case scenario)
      }
    }

    // Check if weights add up to 100%
    if ((totalWeightAccountedFor - 100).abs() > 0.01) {
      return NeededGradeResult(
        neededGrade: 0,
        state: NeededGradeState.invalidTotalWeight,
        totalWeightAccountedFor: totalWeightAccountedFor,
      );
    }

    // Calculate needed grade
    // Formula: neededGrade = (desiredOverallGrade * 100 - sumOfOtherWeightedGrades) / targetCategoryWeight
    final neededGrade =
        (desiredOverallGrade * 100 - sumOfOtherWeightedGrades) /
        targetCategory.weight;

    // Determine if achievable and create message
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

  /// Calculates the maximum possible overall grade if student scores 100%
  /// in all remaining categories
  static double calculateMaxPossibleGrade(List<GradeCategoryModel> categories) {
    double totalWeightedGrade = 0;

    for (final category in categories) {
      if (category.weight > 0) {
        if (category.overallGrade >= 0) {
          // Category has a grade, use it
          totalWeightedGrade +=
              category.weight * _normalizedCategoryGrade(category.overallGrade);
        } else {
          // No grade yet, assume perfect 100%
          totalWeightedGrade += category.weight * 100;
        }
      }
    }

    return totalWeightedGrade / 100;
  }

  /// Calculates the minimum possible overall grade if student scores 0%
  /// in all remaining categories
  static double calculateMinPossibleGrade(List<GradeCategoryModel> categories) {
    double totalWeightedGrade = 0;

    for (final category in categories) {
      if (category.weight > 0) {
        if (category.overallGrade >= 0) {
          // Category has a grade, use it
          totalWeightedGrade +=
              category.weight * _normalizedCategoryGrade(category.overallGrade);
        }
        // No grade yet, assume 0% (don't add anything)
      }
    }

    return totalWeightedGrade / 100;
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
      if (showNaAsBlank) {
        return '';
      } else {
        return 'N/A';
      }
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
      } else if (percentage == percentage.roundToDouble()) {
        return '${percentage.toInt()}%';
      } else {
        return '${percentage.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}%';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
