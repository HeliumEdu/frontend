import 'package:flutter/material.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_container.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/presentation/ui/feedback/success_container.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// "What Do I Need?" calculator tab content.
///
/// Calculates the score needed in one remaining category assignment (weighted
/// classes) or on one remaining assignment (points-based classes) to hit a
/// desired overall grade. Lives inside [GradeCalculatorContainer] as tab 1.
class GradeCalculatorDialog extends StatefulWidget {
  final List<GradeCategoryModel> categories;
  final double currentOverallGrade;
  final String courseTitle;
  final Color courseColor;
  final UserSettingsModel userSettings;
  final double defaultDesiredGradeBoost;
  final List<HomeworkSeriesItemModel> ungradedAssignments;
  final double pointsEarned;
  final double pointsPossible;

  const GradeCalculatorDialog({
    super.key,
    required this.categories,
    required this.ungradedAssignments,
    required this.pointsEarned,
    required this.pointsPossible,
    required this.currentOverallGrade,
    required this.courseTitle,
    required this.courseColor,
    required this.userSettings,
    this.defaultDesiredGradeBoost = 5.0,
  });

  @override
  State<GradeCalculatorDialog> createState() => _GradeCalculatorDialogState();
}

class _GradeCalculatorDialogState extends State<GradeCalculatorDialog> {
  int? _selectedTargetId;
  final TextEditingController _desiredGradeController = TextEditingController();
  NeededGradeResult? _result;
  HomeworkSeriesItemModel? _resultAssignment;
  String? _validationErrorMessage;

  bool get _hasExplicitWeights => widget.categories.any((cat) => cat.weight > 0);

  List<GradeCategoryModel> get _eligibleTargetCategories {
    final eligible = widget.categories.where((cat) {
      final remainingItems = cat.numHomework - cat.numHomeworkGraded;
      return cat.weight > 0 && remainingItems == 1;
    }).toList();
    Sort.byTitle(eligible);
    return eligible;
  }

  List<HomeworkSeriesItemModel> get _eligibleTargetAssignments => widget.ungradedAssignments;

  List<int> get _eligibleTargetIds => _hasExplicitWeights
      ? _eligibleTargetCategories.map((category) => category.id).toList()
      : _eligibleTargetAssignments.map((item) => item.id).toList();

  @override
  void initState() {
    super.initState();
    _desiredGradeController.text = HeliumNumber.format(
      (widget.currentOverallGrade + widget.defaultDesiredGradeBoost).clamp(0, 100).toDouble(),
      fractionDigits: 1,
    );
    if (_eligibleTargetIds.isNotEmpty) {
      _selectedTargetId = _eligibleTargetIds.first;
    }
  }

  @override
  void dispose() {
    _desiredGradeController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_selectedTargetId == null) {
      setState(() {
        _result = null;
        _resultAssignment = null;
        _validationErrorMessage = _hasExplicitWeights ? 'Select a category' : 'Select an assignment';
      });
      return;
    }

    final desiredGrade = HeliumNumber.parse(_desiredGradeController.text);
    if (desiredGrade == null || desiredGrade < 0 || desiredGrade > 100) {
      setState(() {
        _result = null;
        _resultAssignment = null;
        _validationErrorMessage = 'Enter a valid grade between 0 and 100';
      });
      return;
    }

    final NeededGradeResult result;
    final HomeworkSeriesItemModel? resultAssignment;
    if (_hasExplicitWeights) {
      final categoryNeed = GradeHelper.calculateNeededGrade(
        categories: widget.categories,
        targetCategoryId: _selectedTargetId!,
        desiredOverallGrade: desiredGrade,
      );
      final category = widget.categories.firstWhere((cat) => cat.id == _selectedTargetId);
      resultAssignment = _remainingAssignmentIn(category.id);
      result = resultAssignment == null
          ? categoryNeed
          : GradeHelper.toAssignmentScore(
              categoryNeed,
              categoryGradedPointsEarned: category.pointsEarned,
              categoryGradedPointsPossible: category.pointsPossible,
              assignmentPointsPossible: resultAssignment.pointsPossible!,
            );
    } else {
      resultAssignment = _selectedAssignment;
      result = GradeHelper.calculateNeededAssignmentScore(
        gradedPointsEarned: widget.pointsEarned,
        gradedPointsPossible: widget.pointsPossible,
        assignmentPointsPossible: resultAssignment.pointsPossible!,
        desiredOverallGrade: desiredGrade,
      );
    }

    setState(() {
      _result = result;
      _resultAssignment = resultAssignment;
      _validationErrorMessage = null;
    });
  }

  HomeworkSeriesItemModel get _selectedAssignment =>
      _eligibleTargetAssignments.firstWhere((item) => item.id == _selectedTargetId);

  HomeworkSeriesItemModel? _remainingAssignmentIn(int categoryId) {
    final remaining = widget.ungradedAssignments.where((item) => item.categoryId == categoryId).toList();
    return remaining.length == 1 ? remaining.single : null;
  }

  bool _isWeightError(NeededGradeResult result) =>
      result.state == NeededGradeState.targetCategoryHasNoWeight ||
      result.state == NeededGradeState.invalidTotalWeight;

  String _buildResultMessage(NeededGradeResult result) {
    if (_resultAssignment != null && !_isWeightError(result)) {
      return _buildAssignmentResultMessage(result, _resultAssignment!);
    }

    final desiredGrade = HeliumNumber.parse(_desiredGradeController.text) ?? 0;
    String targetCategoryTitle = 'this category';
    for (final category in widget.categories) {
      if (category.id == _selectedTargetId) {
        targetCategoryTitle = category.title;
        break;
      }
    }

    switch (result.state) {
      case NeededGradeState.targetCategoryHasNoWeight:
        // It should be impossible to reach this state
        AnalyticsService().logEvent(
            name: AnalyticsEvent.debugGradeCalcNoWeight,
            parameters: {'category': AnalyticsCategory.edgeCase.value});
        Sentry.captureMessage(
            'Grade calculator reached impossible no-weight state for category: $targetCategoryTitle',
            level: SentryLevel.error);
        return "Selected category has no weight, so we can't help make accurate predictions";
      case NeededGradeState.invalidTotalWeight:
        return "Category weights do not add up to 100%, so we can't help make accurate predictions";
      case NeededGradeState.aboveTarget:
        return 'You\'re already above your target based on current category performance.';
      case NeededGradeState.unachievable:
        return 'You would need to score ${HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1)} to reach your target.';
      case NeededGradeState.achievable:
        return 'You need to score ${HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1)} on "$targetCategoryTitle" to achieve ${HeliumNumber.formatPercent(desiredGrade, fractionDigits: 1)} in this class.';
    }
  }

  String _buildAssignmentResultMessage(NeededGradeResult result, HomeworkSeriesItemModel assignment) {
    final desiredGrade = HeliumNumber.parse(_desiredGradeController.text) ?? 0;
    final neededPoints = result.neededGrade / 100 * assignment.pointsPossible!;
    final points =
        '${HeliumNumber.format(neededPoints, fractionDigits: 1, trimZeros: true)} / '
        '${HeliumNumber.format(assignment.pointsPossible!, fractionDigits: 1, trimZeros: true)} points';

    switch (result.state) {
      case NeededGradeState.aboveTarget:
        return 'You\'re already above your target based on your current points.';
      case NeededGradeState.unachievable:
        return 'You would need to score ${HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1)} ($points) to reach your target.';
      case NeededGradeState.achievable:
        return 'You need to score ${HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1)} ($points) on "${assignment.title}" to achieve ${HeliumNumber.formatPercent(desiredGrade, fractionDigits: 1)} in this class.';
      case NeededGradeState.targetCategoryHasNoWeight:
      case NeededGradeState.invalidTotalWeight:
        throw StateError('Assignment result reached weight error state ${result.state}');
    }
  }

  List<DropdownMenuItem<int>> _buildTargetItems() {
    if (!_hasExplicitWeights) {
      return _eligibleTargetAssignments.map((item) {
        return DropdownMenuItem<int>(
          value: item.id,
          child: Row(
            children: [
              Icon(Icons.assignment_outlined, size: 14, color: widget.courseColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.title} (${HeliumNumber.format(item.pointsPossible!, fractionDigits: 1, trimZeros: true)} pts)',
                  style: AppStyles.formText(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList();
    }

    return _eligibleTargetCategories.map((category) {
      return DropdownMenuItem<int>(
        value: category.id,
        child: Row(
          children: [
            Icon(Icons.category_outlined, size: 14, color: category.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${category.title} (${HeliumNumber.formatPercent(category.weight, fractionDigits: 0)})',
                style: AppStyles.formText(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_eligibleTargetIds.isEmpty) {
      return EmptyCard(
        expanded: false,
        icon: Icons.hourglass_empty,
        title: 'Come back later',
        message: _hasExplicitWeights
            ? 'Check back when a category is down to its last ungraded assignment (e.g. the Final).'
            : 'Check back when this class has an ungraded assignment to plan for (e.g. the Final).',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourseTitleLabel(title: widget.courseTitle, color: widget.courseColor),
        const SizedBox(height: 4),
        GradeLabel(
          grade: GradeHelper.gradeForDisplay(widget.currentOverallGrade),
          userSettings: widget.userSettings,
        ),
        const SizedBox(height: 12),

        Text(_hasExplicitWeights ? 'Category' : 'Assignment', style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        DropdownButtonFormField<int>(
                  initialValue: _selectedTargetId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 12),
                    filled: true,
                    fillColor: context.colorScheme.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: context.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: context.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  icon: Icon(Icons.keyboard_arrow_down, color: context.colorScheme.primary),
                  dropdownColor: context.colorScheme.surface,
                  style: AppStyles.formText(context),
                  isExpanded: true,
                  items: _buildTargetItems(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTargetId = value;
                      _result = null;
                      _resultAssignment = null;
                      _validationErrorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerLeft,
          child: SpinnerField(
            label: 'Desired Class Grade (%)',
            controller: _desiredGradeController,
            minValue: 0,
            maxValue: 100,
            step: 0.5,
            allowDecimal: true,
            maxSpinnerWidth: 120,
            onChanged: (_) {
              setState(() {
                _result = null;
                _resultAssignment = null;
                _validationErrorMessage = null;
              });
            },
          ),
        ),

        if (_validationErrorMessage != null) ...[
          const SizedBox(height: 12),
          ErrorContainer(text: _validationErrorMessage!, icon: Icons.warning_amber_rounded),
        ] else if (_result != null) ...[
          const SizedBox(height: 12),
          if (!_result!.isAchievable)
            _result!.state == NeededGradeState.unachievable
                ? WarningContainer(text: _buildResultMessage(_result!))
                : ErrorContainer(text: _buildResultMessage(_result!), icon: Icons.warning_amber_rounded)
          else
            SuccessContainer(text: _buildResultMessage(_result!)),
        ],

        const Spacer(),
        const SizedBox(height: 12),

        HeliumElevatedButton(buttonText: 'Calculate', onPressed: _calculate),
      ],
    );
  }
}
