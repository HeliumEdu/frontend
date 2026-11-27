import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;

class GradeTrendChart {
  static const _overallSeriesName = 'Overall Grade';
  static const termGpaSeriesName = 'Term GPA';
  static const termGpaAxisName = 'termGpa';

  GradeTrendChart._();

  static charts.SplineSeries<GradeTrendPoint, DateTime> buildOverallSeries(
    BuildContext context,
    List<HomeworkSeriesItemModel> homeworkSeries, {
    required double chartAnimationDurationMs,
  }) {
    final dataSource = _parseHomeworkSeries(homeworkSeries);
    return _buildOverallLikeSeries(
      context,
      dataSource,
      chartAnimationDurationMs: chartAnimationDurationMs,
    );
  }

  static charts.SplineSeries<GradeTrendPoint, DateTime> buildCourseSeries(
    BuildContext context,
    GradeCourseModel course, {
    required double chartAnimationDurationMs,
  }) {
    final dataSource = _parseHomeworkSeries(course.homeworkSeries);
    return charts.SplineSeries<GradeTrendPoint, DateTime>(
      name: course.title,
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      color: course.color,
      width: 1.75,
      opacity: 0.88,
      splineType: charts.SplineType.monotonic,
      animationDuration: chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  static charts.SplineSeries<GradeTrendPoint, DateTime> buildCategorySeries(
    BuildContext context,
    GradeCategoryModel category, {
    required double chartAnimationDurationMs,
  }) {
    final dataSource = _parseHomeworkSeries(category.homeworkSeries);
    return charts.SplineSeries<GradeTrendPoint, DateTime>(
      name: category.title,
      legendItemText: category.displayTitle,
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      color: category.color,
      width: 1.75,
      opacity: 0.9,
      splineType: charts.SplineType.monotonic,
      animationDuration: chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  static charts.StepLineSeries<GradeTrendPoint, DateTime> buildTermGpaSeries(
    BuildContext context,
    List<HomeworkSeriesItemModel> homeworkSeries, {
    required double chartAnimationDurationMs,
  }) {
    final dataSource = homeworkSeries
        .where((item) => item.graded && item.gpa != null)
        .map(
          (item) => GradeTrendPoint(
            date: item.start,
            grade: item.gpa!,
            homeworkId: item.id,
            homeworkTitle: item.title,
            homeworkGrade: item.homeworkGrade,
            categoryId: item.categoryId,
          ),
        )
        .toList();
    return charts.StepLineSeries<GradeTrendPoint, DateTime>(
      name: termGpaSeriesName,
      legendItemText: AppLocalizations.of(context).gradeTrendTermGpaSeries,
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      yAxisName: termGpaAxisName,
      color: context.colorScheme.primary,
      width: 2,
      animationDuration: chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  static List<charts.LineSeries<GpaAcrossTermsPoint, String>>
  buildGpaAcrossTermsSeries(
    BuildContext context,
    List<GpaAcrossTermsPoint> points, {
    required double chartAnimationDurationMs,
  }) {
    return [
      charts.LineSeries<GpaAcrossTermsPoint, String>(
        name: termGpaSeriesName,
        legendItemText: AppLocalizations.of(context).gradeTrendTermGpaSeries,
        dataSource: points,
        xValueMapper: (point, _) => point.title,
        yValueMapper: (point, _) => point.termGpa,
        color: context.colorScheme.primary,
        width: 2,
        animationDuration: chartAnimationDurationMs,
        markerSettings: const charts.MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
        ),
      ),
      charts.LineSeries<GpaAcrossTermsPoint, String>(
        name: 'All',
        legendItemText: AppLocalizations.of(context).gradeTrendAllSeries,
        dataSource: points,
        xValueMapper: (point, _) => point.title,
        yValueMapper: (point, _) => point.cumulativeGpa,
        color: context.colorScheme.onSurface,
        width: 3,
        animationDuration: chartAnimationDurationMs,
        markerSettings: const charts.MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
        ),
      ),
    ];
  }

  static GradeTrendGradeRange gpaAxisRange(
    List<GradeScaleBandModel> gradeScale,
  ) {
    final gradePoints = gradeScale.map((band) => band.gradePoint);
    return GradeTrendGradeRange(min: gradePoints.min, max: gradePoints.max);
  }

  static GradeTrendGradeRange calculateYAxisRange(
    List<charts.CartesianSeries<GradeTrendPoint, DateTime>> visibleSeries,
  ) {
    if (visibleSeries.isEmpty) {
      return const GradeTrendGradeRange(min: 50.0, max: 100.0);
    }

    // Find the lowest and highest grade points across all visible series
    double lowestPoint = 100;
    double highestPoint = 0;

    for (final series in visibleSeries) {
      final dataSource = series.dataSource;
      if (dataSource != null) {
        for (final point in dataSource) {
          if (point.grade < lowestPoint) lowestPoint = point.grade;
          if (point.grade > highestPoint) highestPoint = point.grade;
        }
      }
    }

    // Apply formula: lowest_point - (100 - highest_point)
    final double calculatedMin = lowestPoint - (100 - highestPoint);

    // Ensure minimum doesn't go below 0 and add some padding
    double minimum = (calculatedMin - 5).clamp(0.0, 95.0).toDouble();

    // Round to nearest whole number for cleaner axis labels
    minimum = minimum.floorToDouble();

    // Maximum always stays at 100
    return GradeTrendGradeRange(min: minimum, max: 100.0);
  }

  static GradeTrendDateRange calculateXAxisRange(
    List<charts.CartesianSeries<GradeTrendPoint, DateTime>> visibleSeries,
    CourseGroupModel courseGroup, {
    required bool autoAdjustToGradedRange,
  }) {
    // If auto-adjust is disabled, use the full course group date range
    if (!autoAdjustToGradedRange || visibleSeries.isEmpty) {
      return GradeTrendDateRange(
        min: courseGroup.startDate,
        max: courseGroup.endDate,
      );
    }

    // Find the earliest and latest dates across all visible series
    DateTime? earliestDate;
    DateTime? latestDate;

    for (final series in visibleSeries) {
      final dataSource = series.dataSource;
      if (dataSource != null) {
        for (final point in dataSource) {
          if (earliestDate == null || point.date.isBefore(earliestDate)) {
            earliestDate = point.date;
          }
          if (latestDate == null || point.date.isAfter(latestDate)) {
            latestDate = point.date;
          }
        }
      }
    }

    if (earliestDate != null && latestDate != null) {
      return GradeTrendDateRange(min: earliestDate, max: latestDate);
    }

    return GradeTrendDateRange(
      min: courseGroup.startDate,
      max: courseGroup.endDate,
    );
  }

  static GradeCourseModel? getSelectedCourse({
    required List<GradeCourseGroupModel> grades,
    required int? selectedGroupId,
    required GradeTrendViewMode graphViewMode,
  }) {
    if (graphViewMode.isTerm || selectedGroupId == null) return null;

    final selectedGroup = grades.firstWhere(
      (g) => g.id == selectedGroupId,
      orElse: () => grades.first,
    );

    final selectedCourseId = graphViewMode.courseId;
    if (selectedCourseId == null) return null;
    return selectedGroup.courses.firstWhereOrNull(
      (c) => c.id == selectedCourseId,
    );
  }

  static IconData seriesIconForName(
    String? name, {
    required List<GradeCourseGroupModel> grades,
    required int? selectedGroupId,
    required GradeTrendViewMode graphViewMode,
  }) {
    if (name == null || name.isEmpty) return Icons.circle;

    final selectedGroup = grades.firstWhere(
      (g) => g.id == selectedGroupId,
      orElse: () => grades.first,
    );

    final isCourse = selectedGroup.courses.any(
      (course) => course.title == name,
    );
    if (isCourse) return Icons.school_outlined;

    final selectedCourse = getSelectedCourse(
      grades: grades,
      selectedGroupId: selectedGroupId,
      graphViewMode: graphViewMode,
    );
    final isCategory =
        selectedCourse?.categories.any((category) => category.title == name) ??
        false;
    if (isCategory) return Icons.category_outlined;

    return Icons.circle;
  }

  static charts.SplineSeries<GradeTrendPoint, DateTime> _buildOverallLikeSeries(
    BuildContext context,
    List<GradeTrendPoint> dataSource, {
    required double chartAnimationDurationMs,
  }) {
    return charts.SplineSeries<GradeTrendPoint, DateTime>(
      name: _overallSeriesName,
      legendItemText: AppLocalizations.of(context).gradeTrendOverallSeries,
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      color: context.colorScheme.onSurface,
      width: 3,
      opacity: 1,
      splineType: charts.SplineType.monotonic,
      animationDuration: chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  static List<GradeTrendPoint> _parseHomeworkSeries(
    List<HomeworkSeriesItemModel> homeworkSeries,
  ) {
    return homeworkSeries
        .where((item) => item.graded)
        .map(
          (item) => GradeTrendPoint(
            date: item.start,
            grade: item.cumulativeGrade ?? 0.0,
            homeworkId: item.id,
            homeworkTitle: item.title,
            homeworkGrade: item.homeworkGrade,
            categoryId: item.categoryId,
          ),
        )
        .toList();
  }

  static GradeCategoryModel? _categoryForId(
    int? categoryId, {
    required List<GradeCourseGroupModel> grades,
    required int? selectedGroupId,
  }) {
    if (categoryId == null || selectedGroupId == null || grades.isEmpty) {
      return null;
    }

    final selectedGroup = grades.firstWhere(
      (g) => g.id == selectedGroupId,
      orElse: () => grades.first,
    );

    for (final course in selectedGroup.courses) {
      for (final category in course.categories) {
        if (category.id == categoryId) {
          return category;
        }
      }
    }

    return null;
  }

  static void _handlePointTap(
    BuildContext context,
    List<GradeTrendPoint> dataSource,
    charts.ChartPointDetails pointDetails,
  ) {
    final pointIndex = pointDetails.pointIndex;

    if (pointIndex == null || pointIndex >= dataSource.length) return;

    final chartDataPoint = dataSource[pointIndex];
    final homeworkId = chartDataPoint.homeworkId;

    if (homeworkId == null) {
      return; // No homework associated with this grade point
    }

    // Open the calendar item (assignment)
    showPlannerItemAdd(
      context,
      homeworkId: homeworkId,
      isEdit: true,
      isNew: false,
    );
  }

  static Color _seriesColorForName(
    BuildContext context,
    String? name, {
    required List<GradeCourseGroupModel> grades,
    required int? selectedGroupId,
    required GradeTrendViewMode graphViewMode,
  }) {
    if (name == null || name.isEmpty) return context.colorScheme.onSurface;
    if (name == _overallSeriesName) return context.colorScheme.onSurface;

    final selectedGroup = grades.firstWhere(
      (g) => g.id == selectedGroupId,
      orElse: () => grades.first,
    );

    final matchedCourse = selectedGroup.courses.firstWhereOrNull(
      (course) => course.title == name,
    );
    if (matchedCourse != null) return matchedCourse.color;

    final selectedCourse = getSelectedCourse(
      grades: grades,
      selectedGroupId: selectedGroupId,
      graphViewMode: graphViewMode,
    );
    final matchedCategory = selectedCourse?.categories.firstWhereOrNull(
      (category) => category.title == name,
    );
    if (matchedCategory != null) return matchedCategory.color;

    return context.colorScheme.onSurface;
  }
}

class GradeTrendTooltip extends StatelessWidget {
  final GradeTrendPoint chartPoint;
  final String seriesName;
  final bool isTermView;
  final List<GradeCourseGroupModel> grades;
  final int? selectedGroupId;
  final GradeTrendViewMode graphViewMode;

  const GradeTrendTooltip({
    super.key,
    required this.chartPoint,
    required this.seriesName,
    required this.isTermView,
    required this.grades,
    required this.selectedGroupId,
    required this.graphViewMode,
  });

  @override
  Widget build(BuildContext context) {
    final homeworkTitle = chartPoint.homeworkTitle?.trim().isNotEmpty == true
        ? chartPoint.homeworkTitle!
        : AppLocalizations.of(context).gradeTrendNoTitleFallback;
    final homeworkGradeText = GradeHelper.gradeForDisplay(
      chartPoint.homeworkGrade,
    );
    final category = GradeTrendChart._categoryForId(
      chartPoint.categoryId,
      grades: grades,
      selectedGroupId: selectedGroupId,
    );
    final categoryTitle = category?.displayTitle;
    final categoryColor =
        category?.color ?? context.colorScheme.onSurface.withValues(alpha: 0.6);
    final seriesColor = GradeTrendChart._seriesColorForName(
      context,
      seriesName,
      grades: grades,
      selectedGroupId: selectedGroupId,
      graphViewMode: graphViewMode,
    );
    final isOverallSeries = seriesName == GradeTrendChart._overallSeriesName;
    final isTermGpaSeries = seriesName == GradeTrendChart.termGpaSeriesName;
    final isCourseSeries = isTermView && !isOverallSeries && !isTermGpaSeries;
    final isNonOverallSeries = !isOverallSeries;
    final classGradeAtPoint = HeliumNumber.formatPercent(
      chartPoint.grade,
      fractionDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOverallSeries)
            if (isTermView)
              Text(
                AppLocalizations.of(context).gradeTrendOverallPoint(classGradeAtPoint),
                style: AppStyles.standardBodyTextEmphasis(context),
                overflow: TextOverflow.ellipsis,
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 14, color: categoryColor),
                  const SizedBox(width: 4),
                  Text(
                    '• $classGradeAtPoint',
                    style: AppStyles.standardBodyTextEmphasis(context),
                  ),
                ],
              ),
          if (isOverallSeries && isTermView && categoryTitle != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined, size: 13, color: categoryColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    categoryTitle,
                    style: AppStyles.smallSecondaryText(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (isTermGpaSeries)
            Text(
              AppLocalizations.of(context).gradeTrendTermGpaPoint(GradeHelper.gradePointForDisplay(chartPoint.grade)),
              style: AppStyles.standardBodyTextEmphasis(context),
              overflow: TextOverflow.ellipsis,
            ),
          if (isCourseSeries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 14, color: seriesColor),
                const SizedBox(width: 4),
                Text(
                  '• $classGradeAtPoint',
                  style: AppStyles.standardBodyTextEmphasis(context),
                ),
              ],
            ),
          if (isNonOverallSeries && !isTermGpaSeries) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppConstants.assignmentIcon,
                  size: 13,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$homeworkTitle • $homeworkGradeText',
                    style: AppStyles.smallSecondaryText(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class GradeTrendViewMode {
  final int? courseId;
  final bool isGpaAcrossTerms;

  const GradeTrendViewMode.term() : courseId = null, isGpaAcrossTerms = false;

  const GradeTrendViewMode.course(this.courseId) : isGpaAcrossTerms = false;

  const GradeTrendViewMode.gpaAcrossTerms()
    : courseId = null,
      isGpaAcrossTerms = true;

  bool get isTerm => courseId == null && !isGpaAcrossTerms;

  String get radioValue => isGpaAcrossTerms
      ? 'gpa'
      : isTerm
      ? 'term'
      : courseId.toString();

  static GradeTrendViewMode fromRadioValue(String value) {
    if (value == 'gpa') {
      return const GradeTrendViewMode.gpaAcrossTerms();
    }
    if (value == 'term') {
      return const GradeTrendViewMode.term();
    }
    return GradeTrendViewMode.course(int.parse(value));
  }
}

class GradeTrendGradeRange {
  final double min;
  final double max;

  const GradeTrendGradeRange({required this.min, required this.max});
}

class GradeTrendDateRange {
  final DateTime min;
  final DateTime max;

  const GradeTrendDateRange({required this.min, required this.max});
}

class GradeTrendPoint {
  final DateTime date;
  final double grade;
  final int? homeworkId;
  final String? homeworkTitle;
  final dynamic homeworkGrade;
  final int? categoryId;

  GradeTrendPoint({
    required this.date,
    required this.grade,
    this.homeworkId,
    this.homeworkTitle,
    this.homeworkGrade,
    this.categoryId,
  });
}
