// Grading math is also implemented in the backend at
// projects/platform/helium/planner/services/gradingservice.py (the source of
// truth for actual grades). This file operates on category aggregates the
// backend produces — it does NOT recompute course grades from raw homework.
// The "What Grade Do I Need?" inverse calculation lives in the backend
// (projects/platform/helium/planner/services/neededgradeservice.py, served at
// /planner/grades/needed/); only the "What Could I Get?" projection is here.
// If you change the weighted-grade math here, audit gradingservice.py for
// consistency. Both sides have their own test suites covering the math at
// their respective layers.

import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/utils/format_helpers.dart';

class GradeHelper {
  /// Projects an overall grade given hypothetical scores for ungraded assignments.
  /// [projections] maps assignment ID to a hypothetical score as a percentage (0–100).
  ///
  /// Returns the projected grade as a percentage (0–100), or -1 when there is
  /// insufficient data to compute a result (no assignments, no weight).
  static double calculateProjectedGrade({
    required List<GradeCategoryModel> categories,
    required List<HomeworkSeriesItemModel> ungradedAssignments,
    required Map<int, double> projections,
    required double pointsEarned,
    required double pointsPossible,
  }) {
    final hasWeightedGrading = categories.any((c) => c.weight > 0);
    return hasWeightedGrading
        ? _projectedWeighted(categories, ungradedAssignments, projections)
        : _projectedPoints(ungradedAssignments, projections, pointsEarned, pointsPossible);
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
    List<HomeworkSeriesItemModel> ungradedAssignments,
    Map<int, double> projections,
    double pointsEarned,
    double pointsPossible,
  ) {
    double totalEarned = pointsEarned;
    double totalPossible = pointsPossible;

    for (final item in ungradedAssignments) {
      final pp = item.pointsPossible ?? 0;
      if (pp <= 0) continue;
      totalEarned += (projections[item.id] ?? 0) / 100.0 * pp;
      totalPossible += pp;
    }

    return totalPossible > 0 ? totalEarned / totalPossible * 100 : -1;
  }

  /// Normalizes each side of the `/` on its own, so both read as decimals.
  static String normalizeFraction(String text) =>
      text.split('/').map(HeliumNumber.normalize).join('/');

  /// Parses a grade value from various formats (strings like "X/Y", numbers, etc.)
  /// Returns the grade as a percentage (0-100) or null if invalid/not graded
  static double? parseGrade(dynamic grade) {
    if (grade == null ||
        grade == '' ||
        grade == '-1/100' ||
        grade == -1.0) {
      return null;
    }

    if (grade is String) {
      try {
        final split = grade.split('/');
        if (split.length == 2) {
          return (HeliumNumber.parse(split[0])! / HeliumNumber.parse(split[1])!) * 100;
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

    return HeliumNumber.formatPercent(gradeValue, fractionDigits: 2);
  }

  /// Formats a percentage value for display (e.g., category weights)
  /// Optionally shows 'N/A' for zero values
  static String percentForDisplay(String value, bool? zeroAsNa) {
    try {
      final percentage = double.parse(value);
      if (percentage == 0 && zeroAsNa != null && zeroAsNa) {
        return 'N/A';
      }
      return HeliumNumber.formatPercent(percentage, fractionDigits: 2, trimZeros: true);
    } catch (e) {
      return 'N/A';
    }
  }
}
