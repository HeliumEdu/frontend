import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_gpa.dart';
import 'package:heliumapp/presentation/ui/components/category_title_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/success_container.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

/// "What Could I Get?" projection tab content.
///
/// Lets students set hypothetical scores for each ungraded assignment and see
/// the resulting projected overall grade live, or, in GPA [mode], the
/// projected term GPA. Lives inside [GradeCalculatorContainer] as tab 0.
class GradeProjectionTab extends StatefulWidget {
  final List<GradeCategoryModel> categories;
  final List<HomeworkSeriesItemModel> ungradedAssignments;
  final double pointsEarned;
  final double pointsPossible;
  final double currentOverallGrade;
  final Color courseColor;
  final UserSettingsModel userSettings;
  final GradeCalculatorMode mode;
  final GradeCalculatorGpa? gpa;
  final bool hasAssignments;
  final String? termWeek;

  const GradeProjectionTab({
    super.key,
    required this.categories,
    required this.ungradedAssignments,
    required this.pointsEarned,
    required this.pointsPossible,
    required this.currentOverallGrade,
    required this.courseColor,
    required this.userSettings,
    this.mode = GradeCalculatorMode.classGrade,
    this.gpa,
    this.hasAssignments = true,
    this.termWeek,
  });

  @override
  State<GradeProjectionTab> createState() => _GradeProjectionTabState();
}

class _GradeProjectionTabState extends State<GradeProjectionTab> {
  /// Hypothetical score as a percentage (0-100) per assignment ID.
  late Map<int, double> _projections;
  bool _useLogged = false;

  bool get _hasWeightedGrading => widget.categories.any((c) => c.weight > 0);

  @override
  void initState() {
    super.initState();
    _projections = _defaultProjections();
  }

  Map<int, double> _defaultProjections() {
    final result = <int, double>{};
    for (final item in widget.ungradedAssignments) {
      final pp = item.pointsPossible ?? 0;
      if (pp <= 0) continue;
      final categoryAverage = _hasWeightedGrading
          ? _categoryFor(item.categoryId)?.overallGrade ?? -1.0
          : -1.0;
      final grade = categoryAverage >= 0 ? categoryAverage : widget.currentOverallGrade;
      result[item.id] = grade >= 0 ? grade.clamp(0, 100) : 100.0;
    }
    return result;
  }

  GradeCategoryModel? _categoryFor(int categoryId) {
    try {
      return widget.categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  double get _projectedGrade {
    return GradeHelper.calculateProjectedGrade(
      categories: widget.categories,
      ungradedAssignments: widget.ungradedAssignments,
      projections: _projections,
      pointsEarned: widget.pointsEarned,
      pointsPossible: widget.pointsPossible,
    );
  }

  /// Category IDs to display, sorted alphabetically by title.
  /// Excludes zero-weight categories for weighted courses.
  List<int> get _displayCategoryIds {
    final validIds = widget.ungradedAssignments
        .where((a) {
          if (!_hasWeightedGrading) return true;
          final cat = _categoryFor(a.categoryId);
          return cat != null && cat.weight > 0;
        })
        .map((a) => a.categoryId)
        .toSet();

    final orderedCategories = widget.categories
        .where((c) => validIds.contains(c.id))
        .toList();
    Sort.byTitle(orderedCategories);
    return orderedCategories.map((c) => c.id).toList();
  }

  void _onSliderChanged(int assignmentId, double rawScore, double pointsPossible) {
    if (!_useLogged) {
      _useLogged = true;
      unawaited(
        AnalyticsService().logEvent(
          name: AnalyticsEvent.gradeCalculatorUse,
          parameters: {
            'category': AnalyticsCategory.featureInteraction.value,
            'tab': GradeCalculatorTab.whatCouldIGet.name,
            'mode': widget.mode.name,
            'term_week': ?widget.termWeek,
          },
        ),
      );
    }
    setState(() {
      _projections[assignmentId] = pointsPossible > 0 ? rawScore / pointsPossible * 100 : 0;
    });
  }

  void _onReset() {
    setState(() {
      _projections = _defaultProjections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryIds = _displayCategoryIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.hasAssignments)
          const EmptyCard(
            icon: Icons.hourglass_empty,
            title: 'Come back later',
            message: 'Check back when this class has assignments.',
          )
        else if (widget.ungradedAssignments.isEmpty)
          const EmptyCard(
            icon: Icons.check_circle_outline,
            title: 'All caught up',
            message: 'Check back again when you have ungraded work to use this feature.',
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final categoryId in categoryIds)
                    _buildCategorySection(context, categoryId),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),
        if (_projectedGrade >= 0) ...[
          _buildProjectedGradeStatus(context),
          const SizedBox(height: 12),
        ],

        HeliumElevatedButton(
          buttonText: 'Reset',
          backgroundColor: context.colorScheme.onSurfaceVariant,
          onPressed: _onReset,
          enabled: widget.ungradedAssignments.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, int categoryId) {
    final category = _categoryFor(categoryId);
    final assignments = widget.ungradedAssignments
        .where((a) => a.categoryId == categoryId)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: category != null
              ? CategoryTitleLabel(
                  title: category.title,
                  color: category.color,
                  compact: true,
                )
              : Text('Category', style: AppStyles.formLabel(context)),
        ),
        const SizedBox(height: 4),
        for (final item in assignments)
          if ((item.pointsPossible ?? 0) > 0) _buildAssignmentRow(context, item),
      ],
    );
  }

  Widget _buildAssignmentRow(BuildContext context, HomeworkSeriesItemModel item) {
    final pp = item.pointsPossible ?? 0;
    final projectedPct = _projections[item.id] ?? 100.0;
    final rawScore = (projectedPct / 100.0 * pp).clamp(0.0, pp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppStyles.smallSecondaryText(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                HeliumDateTime.formatDateForTodos(
                  HeliumDateTime.toLocal(item.start, widget.userSettings.timeZone),
                ),
                style: AppStyles.smallSecondaryText(context).copyWith(
                  color: context.colorScheme.outline,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Semantics(
                    label: item.title,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: widget.courseColor,
                        thumbColor: widget.courseColor,
                        overlayColor: widget.courseColor.withValues(alpha: 0.2),
                        valueIndicatorTextStyle: AppStyles.buttonText(context),
                      ),
                      child: Slider(
                        value: rawScore,
                        min: 0,
                        max: pp,
                        divisions: pp.round().clamp(1, 1000),
                        onChanged: (v) => _onSliderChanged(item.id, v, pp),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  HeliumNumber.formatPercent(projectedPct, fractionDigits: 2),
                  style: AppStyles.formText(context),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectedGradeStatus(BuildContext context) {
    final grade = _projectedGrade;
    if (grade < 0) return const SizedBox.shrink();
    if (widget.mode == GradeCalculatorMode.termGpa) {
      return _buildProjectedGpaStatus(context, widget.gpa!, grade);
    }

    final threshold = widget.userSettings.atRiskThreshold.toDouble();
    final text = 'Projected grade: ${GradeHelper.gradeForDisplay(grade)}';

    return grade >= threshold
        ? SuccessContainer(text: text)
        : WarningContainer(text: text);
  }

  Widget _buildProjectedGpaStatus(
    BuildContext context,
    GradeCalculatorGpa gpa,
    double grade,
  ) {
    final gradePoint = GradeHelper.gradePointFor(grade, gpa.gradeScale)!;
    final termGpa = gpa.termGpaWith(gradePoint)!;
    final cumulativeGpa = Responsive.isNarrowMobile(context)
        ? null
        : gpa.cumulativeGpaWith(gradePoint);

    var text = 'Projected GPA: ${GradeHelper.gradePointForDisplay(termGpa)}'
        '${_gpaChange(gpa.termGpa, termGpa)}';
    if (cumulativeGpa != null) {
      text += ' • All ${GradeHelper.gradePointForDisplay(cumulativeGpa)}'
          '${_gpaChange(gpa.cumulativeGpa, cumulativeGpa)}';
    }

    final currentGpa = gpa.termGpa;
    final holdsOrImproves = currentGpa == null ||
        gpa.holdsOrImproves(
          GradeHelper.displayedGpa(currentGpa),
          GradeHelper.displayedGpa(termGpa),
        );
    return holdsOrImproves ? SuccessContainer(text: text) : WarningContainer(text: text);
  }

  String _gpaChange(double? current, double projected) {
    if (current == null) return '';
    final change = GradeHelper.displayedGpa(projected) - GradeHelper.displayedGpa(current);
    if (change == 0) return '';
    final amount = GradeHelper.gradePointForDisplay(change.abs());
    return change > 0 ? ' (+$amount)' : ' (-$amount)';
  }
}
