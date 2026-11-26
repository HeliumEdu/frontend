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

import 'dart:math' as math;

import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

typedef GpaAcrossTermsPoint = ({
  String title,
  double? termGpa,
  double? cumulativeGpa,
});

class GradeHelper {
  /// Projects an overall grade given hypothetical scores for ungraded assignments.
  /// [projections] maps assignment ID to a hypothetical score as a percentage (0-100).
  ///
  /// Returns the projected grade as a percentage (0-100), or -1 when there is
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
          final totalPossible = category.pointsPossible + totalUngradedPossible;
          categoryGrade = totalPossible > 0
              ? (category.pointsEarned + earnedFromUngraded) / totalPossible * 100
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

  /// The presets a class in a group graded on [groupScale] can use: those whose
  /// every grade (grade point and label) [groupScale] also awards. Mirrors
  /// `gradeutils.compatible_presets` on the platform.
  static List<int> compatiblePresets(List<GradeScaleBandModel> groupScale) {
    if (groupScale.isEmpty) return const [];
    final awarded = _gradesAwarded(groupScale);
    return [
      for (final MapEntry(key: template, value: scale)
          in GradeScaleTemplate.scales.entries)
        if (template != GradeScaleTemplate.none &&
            awarded.containsAll(_gradesAwarded(scale)))
          template,
    ];
  }

  /// The name of the grade scale [course] is graded on: its own preset, else
  /// [group]'s (Custom when that matches no preset), or null when the group
  /// has none.
  static String? gradeScaleLabelFor(CourseModel course, CourseGroupModel? group) {
    if (group == null || group.gradeScale.isEmpty) return null;
    return GradeScaleTemplate.labelFor(
      course.gradeScaleTemplate ??
          group.gradeScaleTemplate ??
          GradeScaleTemplate.custom,
    );
  }

  static Set<(double, String)> _gradesAwarded(
    List<GradeScaleBandModel> scale,
  ) => {
    for (final band in scale)
      ((band.gradePoint * 100).round() / 100, band.label),
  };

  /// The band [grade] falls in on [gradeScale]: the last band whose
  /// `minGrade` the grade reaches as displayed (two places), so a grade above
  /// 100 falls in the top band. Null when [grade] is ungraded (null or
  /// negative) or there is no scale.
  static GradeScaleBandModel? gradeBandFor(
    double? grade,
    List<GradeScaleBandModel> gradeScale,
  ) {
    if (grade == null || grade < 0 || gradeScale.isEmpty) return null;

    final displayedGrade = _roundHalfUp(_roundHalfUp(grade, 4), 2);
    var gradeBand = gradeScale.first;
    for (final band in gradeScale) {
      if (displayedGrade < band.minGrade) break;
      gradeBand = band;
    }
    return gradeBand;
  }

  /// Mirrors `gradingservice.grade_point_for` on the platform.
  static double? gradePointFor(
    double? grade,
    List<GradeScaleBandModel> gradeScale,
  ) => gradeBandFor(grade, gradeScale)?.gradePoint;

  /// The credit-weighted mean grade point of [classes] that have a grade point
  /// and credits, or null when none do. Mirrors `gradingservice.gpa_for` on
  /// the platform.
  static double? gpaFor(Iterable<({double credits, double? gradePoint})> classes) {
    final credited = classes.where(
      (c) => c.gradePoint != null && c.credits > 0,
    );
    if (credited.isEmpty) return null;

    final points = credited.fold<double>(
      0,
      (sum, c) => sum + c.credits * c.gradePoint!,
    );
    final credits = credited.fold<double>(0, (sum, c) => sum + c.credits);
    return double.parse((points / credits).toStringAsFixed(4));
  }

  /// A Prior point when there are prior credits, then one point per term that
  /// counts toward the cumulative GPA, in [courseGroups]' order, with the
  /// cumulative GPA through it. A term with no GPA yet is an empty slot, or is
  /// left out with [onlyTermsWithGpa].
  static List<GpaAcrossTermsPoint> gpaAcrossTerms(
    List<GradeCourseGroupModel> courseGroups, {
    required double priorCredits,
    required double priorGpa,
    required bool onlyTermsWithGpa,
  }) {
    final pooledGroups = courseGroups.where((group) => group.inCumulativeGpa);

    final classes = <({double credits, double? gradePoint})>[
      (credits: priorCredits, gradePoint: priorGpa),
    ];
    final points = <GpaAcrossTermsPoint>[
      if (priorCredits > 0)
        (title: LocaleNotifier().localizations.gradesPriorCreditsPoint, termGpa: null, cumulativeGpa: gpaFor(classes)),
    ];
    for (final group in pooledGroups) {
      classes.addAll([
        for (final course in group.courses)
          (credits: course.credits, gradePoint: course.gradePoint),
      ]);
      if (group.gpa != null) {
        points.add(
          (title: group.title, termGpa: group.gpa, cumulativeGpa: gpaFor(classes)),
        );
      } else if (!onlyTermsWithGpa) {
        points.add((title: group.title, termGpa: null, cumulativeGpa: null));
      }
    }
    return points;
  }

  /// Whether a higher grade point is better on [gradeScale].
  static bool isHigherGradePointBetter(List<GradeScaleBandModel> gradeScale) =>
      gradeScale.isEmpty ||
      gradeScale.last.gradePoint >= gradeScale.first.gradePoint;

  static double _roundHalfUp(double value, int places) {
    var text = value.abs().toString();
    if (text.contains('e')) text = value.abs().toStringAsFixed(20);
    final parts = text.split('.');
    final fraction = (parts.length > 1 ? parts[1] : '').padRight(places + 1, '0');
    var digits = BigInt.parse('${parts[0]}${fraction.substring(0, places)}');
    if (fraction.codeUnitAt(places) >= 0x35) digits += BigInt.one;
    final rounded = digits.toDouble() / math.pow(10, places);
    return value < 0 ? -rounded : rounded;
  }

  static double displayedGpa(double gpa) => _roundHalfUp(gpa, 2);

  static String gradePointForDisplay(double gradePoint) =>
      HeliumNumber.format(gradePoint, fractionDigits: 2);

  static String minGradeForDisplay(double minGrade) =>
      '${HeliumNumber.formatPercent(minGrade, trimZeros: true)}+';

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

  static Map<int, int> largestRemainderPercents(
    List<GradeCategoryModel> categories,
    double total,
  ) {
    final gradedCats = categories
        .where((c) => c.gradeByWeight != null && c.gradeByWeight! > 0)
        .toList();
    final rawValues = gradedCats
        .map((c) => c.gradeByWeight! / total * 100)
        .toList();
    final floors = rawValues.map((v) => v.floor()).toList();
    final remainder = 100 - floors.reduce((a, b) => a + b);
    final indices = List.generate(gradedCats.length, (i) => i)
      ..sort(
            (a, b) =>
            (rawValues[b] - floors[b]).compareTo(rawValues[a] - floors[a]),
      );
    for (int i = 0; i < remainder; i++) {
      floors[indices[i]]++;
    }
    return {
      for (int i = 0; i < gradedCats.length; i++) gradedCats[i].id: floors[i],
    };
  }

  static bool hasGrade(GradeCourseModel course) => GradeHelper.parseGrade(course.overallGrade) != null;

  static bool isAtRisk(GradeCourseModel course, double atRiskThreshold) =>
      course.numHomeworkGraded > 0 && hasGrade(course) && course.overallGrade < atRiskThreshold;

  /// The letter range of a grade scale's bands (ordered lowest first), like
  /// "A+ to F", or null for a scale without letters.
  static String? gradeScaleSummary(List<GradeScaleBandModel> bands) {
    if (bands.isEmpty || bands.last.label.isEmpty) return null;
    return LocaleNotifier().localizations.gradeScaleLetterRange(bands.last.label, bands.first.label);
  }

  static String? gpaHint(
    GradeCourseGroupModel selectedGroup,
    List<GradeCourseGroupModel> grades, {
    required double priorCredits,
    required double priorGpa,
  }) {
    final withoutCredits = selectedGroup.courses
        .where((c) => c.gradePoint != null && c.credits <= 0)
        .length;
    final hints = <String>[];
    if (withoutCredits > 0) {
      hints.add(LocaleNotifier().localizations.gradesClassesWithoutCreditsHint(withoutCredits));
    }
    if (!selectedGroup.exampleSchedule &&
        !selectedGroup.inCumulativeGpa &&
        grades.any((g) => g.inCumulativeGpa)) {
      hints.add(
        LocaleNotifier().localizations.gradesScaleDiffersHint,
      );
    }
    if (priorCredits > 0) {
      hints.add(LocaleNotifier().localizations.gradesPriorCreditsHint(
        priorCredits,
        HeliumNumber.format(priorCredits, trimZeros: true),
        gradePointForDisplay(priorGpa),
      ));
    }
    return hints.isEmpty ? null : hints.join('\n\n');
  }
}
