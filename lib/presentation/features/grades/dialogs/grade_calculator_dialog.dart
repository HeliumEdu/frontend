import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/data/models/planner/homework_series_item_model.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_bloc.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_event.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_state.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_gpa.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_container.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/presentation/ui/feedback/success_container.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/presentation/ui/layout/reveal_on_mount.dart';
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
/// desired overall grade, or, in GPA [mode], a desired term GPA. Lives inside
/// [GradeCalculatorContainer] as tab 1.
class GradeCalculatorDialog extends StatefulWidget {
  final int courseId;
  final List<GradeCategoryModel> categories;
  final double currentOverallGrade;
  final Color courseColor;
  final double defaultDesiredGradeBoost;
  final List<HomeworkSeriesItemModel> ungradedAssignments;
  final GradeCalculatorMode mode;
  final GradeCalculatorGpa? gpa;
  final String? termWeek;

  const GradeCalculatorDialog({
    super.key,
    required this.courseId,
    required this.categories,
    required this.ungradedAssignments,
    required this.currentOverallGrade,
    required this.courseColor,
    this.defaultDesiredGradeBoost = 5.0,
    this.mode = GradeCalculatorMode.classGrade,
    this.gpa,
    this.termWeek,
  });

  @override
  State<GradeCalculatorDialog> createState() => _GradeCalculatorDialogState();
}

class _GradeCalculatorDialogState extends State<GradeCalculatorDialog> {
  static const _gpaStep = 0.1;

  int? _selectedTargetId;
  bool _useLogged = false;
  final TextEditingController _desiredGradeController = TextEditingController();
  NeededGradeModel? _result;
  String? _validationErrorMessage;
  bool _isCalculating = false;

  bool get _hasExplicitWeights => widget.categories.any((cat) => cat.weight > 0);

  List<GradeCategoryModel> get _eligibleTargetCategories {
    final eligible = widget.categories.where((cat) {
      final remainingItems = cat.numHomework - cat.numHomeworkGraded;
      return cat.weight > 0 && remainingItems == 1;
    }).toList();
    Sort.byGradeCategoryTitle(eligible);
    return eligible;
  }

  List<HomeworkSeriesItemModel> get _eligibleTargetAssignments => widget.ungradedAssignments;

  List<int> get _eligibleTargetIds => _hasExplicitWeights
      ? _eligibleTargetCategories.map((category) => category.id).toList()
      : _eligibleTargetAssignments.map((item) => item.id).toList();

  bool get _isGpaMode => widget.mode == GradeCalculatorMode.termGpa;

  double get _minGpa => widget.gpa!.gradeScale.map((band) => band.gradePoint).reduce(math.min);

  double get _maxGpa => widget.gpa!.gradeScale.map((band) => band.gradePoint).reduce(math.max);

  @override
  void initState() {
    super.initState();
    _desiredGradeController.text = _defaultDesired();
    if (_eligibleTargetIds.isNotEmpty) {
      _selectedTargetId = _eligibleTargetIds.first;
    }
  }

  @override
  void didUpdateWidget(GradeCalculatorDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _desiredGradeController.text = _defaultDesired();
      _clearResult();
    }
  }

  String _defaultDesired() {
    if (_isGpaMode) {
      final gpa = widget.gpa!;
      final termGpa = gpa.termGpa;
      final oneStepBetter = termGpa == null
          ? (gpa.isHigherBetter ? _maxGpa : _minGpa)
          : (gpa.isHigherBetter ? termGpa + _gpaStep : termGpa - _gpaStep);
      return HeliumNumber.format(
        oneStepBetter.clamp(_minGpa, _maxGpa).toDouble(),
        fractionDigits: 2,
      );
    }
    return HeliumNumber.format(
      (widget.currentOverallGrade + widget.defaultDesiredGradeBoost).clamp(0, 100).toDouble(),
      fractionDigits: 1,
    );
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
        _validationErrorMessage = _hasExplicitWeights ? AppLocalizations.of(context).gradeCalculatorSelectCategoryError : AppLocalizations.of(context).gradeCalculatorSelectAssignmentError;
      });
      return;
    }

    final desired = HeliumNumber.parse(_desiredGradeController.text);
    if (_isGpaMode) {
      if (desired == null || desired < _minGpa || desired > _maxGpa) {
        setState(() {
          _result = null;
          _validationErrorMessage = AppLocalizations.of(context).gradeCalculatorInvalidGpaError(GradeHelper.gradePointForDisplay(_minGpa), GradeHelper.gradePointForDisplay(_maxGpa));
        });
        return;
      }
    } else if (desired == null || desired < 0 || desired > 100) {
      setState(() {
        _result = null;
        _validationErrorMessage = AppLocalizations.of(context).gradeCalculatorInvalidGradeError;
      });
      return;
    }

    if (!_useLogged) {
      _useLogged = true;
      unawaited(
        AnalyticsService().logEvent(
          name: AnalyticsEvent.gradeCalculatorUse,
          parameters: {
            'category': AnalyticsCategory.featureInteraction.value,
            'tab': GradeCalculatorTab.whatDoINeed.name,
            'mode': widget.mode.name,
            'term_week': ?widget.termWeek,
          },
        ),
      );
    }
    setState(() => _isCalculating = true);
    context.read<GradeBloc>().add(
      CalculateNeededGradeEvent(
        courseId: widget.courseId,
        targetId: _selectedTargetId!,
        desiredGrade: _isGpaMode ? null : desired,
        desiredGpa: _isGpaMode ? desired : null,
      ),
    );
  }

  void _onGradeState(BuildContext context, GradeState state) {
    if (state is NeededGradeCalculated &&
        _isCurrentCalculation(
          state.courseId,
          state.targetId,
          state.desiredGrade,
          state.desiredGpa,
        )) {
      setState(() {
        _result = state.result;
        _validationErrorMessage = null;
        _isCalculating = false;
      });
    } else if (state is NeededGradeError &&
        _isCurrentCalculation(
          state.courseId,
          state.targetId,
          state.desiredGrade,
          state.desiredGpa,
        )) {
      setState(() {
        _result = null;
        _validationErrorMessage = state.message;
        _isCalculating = false;
      });
    }
  }

  bool _isCurrentCalculation(
    int courseId,
    int targetId,
    double? desiredGrade,
    double? desiredGpa,
  ) =>
      _isCalculating &&
      courseId == widget.courseId &&
      targetId == _selectedTargetId &&
      (desiredGpa != null) == _isGpaMode &&
      (desiredGpa ?? desiredGrade) == HeliumNumber.parse(_desiredGradeController.text);

  void _clearResult() {
    _result = null;
    _validationErrorMessage = null;
    _isCalculating = false;
  }

  bool _isWeightError(NeededGradeModel result) =>
      result.state == NeededGradeState.targetCategoryHasNoWeight ||
      result.state == NeededGradeState.invalidTotalWeight;

  String _resultMessage(NeededGradeModel result) {
    if (result.gradeBand != null && !_isWeightError(result)) {
      return _gpaResultMessage(result, result.gradeBand!);
    }
    if (result.assignment != null && !_isWeightError(result)) {
      return _assignmentResultMessage(result, result.assignment!);
    }

    final desiredGrade = HeliumNumber.parse(_desiredGradeController.text) ?? 0;
    final targetCategoryTitle = _selectedCategoryTitle;

    switch (result.state) {
      case NeededGradeState.targetCategoryHasNoWeight:
        // It should be impossible to reach this state
        AnalyticsService().logEvent(
            name: AnalyticsEvent.debugGradeCalcNoWeight,
            parameters: {'category': AnalyticsCategory.edgeCase.value});
        Sentry.captureMessage(
            'Grade calculator reached impossible no-weight state for category: $targetCategoryTitle',
            level: SentryLevel.error);
        return AppLocalizations.of(context).gradeCalculatorNoWeightMessage;
      case NeededGradeState.invalidTotalWeight:
        return AppLocalizations.of(context).gradeCalculatorInvalidWeightsMessage;
      case NeededGradeState.aboveTarget:
        return AppLocalizations.of(context).gradeCalculatorCategoryAboveTargetMessage;
      case NeededGradeState.unachievable:
        return AppLocalizations.of(context).gradeCalculatorCategoryUnachievableMessage(HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1));
      case NeededGradeState.achievable:
        return AppLocalizations.of(context).gradeCalculatorCategoryAchievableMessage(HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1), targetCategoryTitle, HeliumNumber.formatPercent(desiredGrade, fractionDigits: 1));
      case NeededGradeState.gpaUnreachable:
        throw StateError('A grade result reached the GPA-only state ${result.state}');
    }
  }

  String _assignmentResultMessage(
    NeededGradeModel result,
    NeededGradeAssignmentModel assignment,
  ) {
    final desiredGrade = HeliumNumber.parse(_desiredGradeController.text) ?? 0;
    final points = _pointsLabel(assignment);

    switch (result.state) {
      case NeededGradeState.aboveTarget:
        return AppLocalizations.of(context).gradeCalculatorAssignmentAboveTargetMessage;
      case NeededGradeState.unachievable:
        return AppLocalizations.of(context).gradeCalculatorAssignmentUnachievableMessage(HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1), points);
      case NeededGradeState.achievable:
        return AppLocalizations.of(context).gradeCalculatorAssignmentAchievableMessage(HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1), points, assignment.title, HeliumNumber.formatPercent(desiredGrade, fractionDigits: 1));
      case NeededGradeState.targetCategoryHasNoWeight:
      case NeededGradeState.invalidTotalWeight:
      case NeededGradeState.gpaUnreachable:
        throw StateError('Assignment result reached state ${result.state}');
    }
  }

  String _gpaResultMessage(NeededGradeModel result, GradeScaleBandModel band) {
    final gpa = GradeHelper.gradePointForDisplay(HeliumNumber.parse(_desiredGradeController.text) ?? 0);
    final from = GradeHelper.minGradeForDisplay(band.minGrade);
    final bandText = band.label.isEmpty
        ? AppLocalizations.of(context).gradeCalculatorBandWithPoint(from, GradeHelper.gradePointForDisplay(band.gradePoint))
        : AppLocalizations.of(context).gradeCalculatorBandWithLetter(band.label, from);
    final assignment = result.assignment;
    final score = HeliumNumber.formatPercent(result.neededGrade, fractionDigits: 1);
    final scoreWithPoints = assignment == null ? score : AppLocalizations.of(context).gradeCalculatorScoreWithPoints(score, _pointsLabel(assignment));
    final target = assignment?.title ?? _selectedCategoryTitle;
    final direction = widget.gpa!.isHigherBetter ? 'atLeast' : 'atMost';

    switch (result.state) {
      case NeededGradeState.achievable:
        return AppLocalizations.of(context).gradeCalculatorGpaAchievableMessage(scoreWithPoints, target, bandText, direction, gpa);
      case NeededGradeState.aboveTarget:
        return AppLocalizations.of(context).gradeCalculatorGpaAboveTargetMessage(bandText, direction, gpa);
      case NeededGradeState.unachievable:
        return AppLocalizations.of(context).gradeCalculatorGpaUnachievableMessage(scoreWithPoints, bandText, direction, gpa);
      case NeededGradeState.gpaUnreachable:
        return AppLocalizations.of(context).gradeCalculatorGpaUnreachableMessage(bandText, gpa);
      case NeededGradeState.targetCategoryHasNoWeight:
      case NeededGradeState.invalidTotalWeight:
        throw StateError('A GPA result reached weight error state ${result.state}');
    }
  }

  String _pointsLabel(NeededGradeAssignmentModel assignment) =>
      AppLocalizations.of(context).gradeCalculatorPointsOfLabel(HeliumNumber.format(assignment.neededPoints, fractionDigits: 1, trimZeros: true), HeliumNumber.format(assignment.pointsPossible, fractionDigits: 1, trimZeros: true));

  String get _selectedCategoryTitle =>
      widget.categories.where((category) => category.id == _selectedTargetId).firstOrNull?.displayTitle ??
      AppLocalizations.of(context).gradeCalculatorThisCategoryFallback;

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
                  AppLocalizations.of(context).gradeCalculatorAssignmentOption(item.title, HeliumNumber.format(item.pointsPossible!, fractionDigits: 1, trimZeros: true)),
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
                '${category.displayTitle} (${HeliumNumber.formatPercent(category.weight, fractionDigits: 0)})',
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
    return BlocListener<GradeBloc, GradeState>(
      listener: _onGradeState,
      child: _buildCalculator(context),
    );
  }

  Widget _buildCalculator(BuildContext context) {
    if (_eligibleTargetIds.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmptyCard(
            icon: Icons.hourglass_empty,
            title: AppLocalizations.of(context).gradeCalculatorComeBackLaterTitle,
            message: _hasExplicitWeights
                ? AppLocalizations.of(context).gradeCalculatorNeedsLastUngradedMessage
                : AppLocalizations.of(context).gradeCalculatorNeedsUngradedMessage,
          ),
          const SizedBox(height: 12),
          HeliumElevatedButton(
            buttonText: AppLocalizations.of(context).gradeCalculatorCalculateButton,
            onPressed: _calculate,
            enabled: false,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_hasExplicitWeights ? AppLocalizations.of(context).gradeCalculatorCategoryLabel : AppLocalizations.of(context).gradeCalculatorAssignmentLabel, style: AppStyles.formLabel(context)),
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
                  onChanged: _onTargetChanged,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SpinnerField(
                    key: ValueKey(widget.mode),
                    label: _isGpaMode ? AppLocalizations.of(context).gradeCalculatorDesiredGpaLabel : AppLocalizations.of(context).gradeCalculatorDesiredGradeLabel,
                    controller: _desiredGradeController,
                    minValue: _isGpaMode ? _minGpa : 0,
                    maxValue: _isGpaMode ? _maxGpa : 100,
                    step: _isGpaMode ? _gpaStep : 0.5,
                    allowDecimal: true,
                    maxSpinnerWidth: 120,
                    onChanged: _onDesiredChanged,
                  ),
                ),
                if (_validationErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  RevealOnMount(
                    key: ValueKey(_validationErrorMessage),
                    child: ErrorContainer(text: _validationErrorMessage!, icon: Icons.warning_amber),
                  ),
                ] else if (_result != null) ...[
                  const SizedBox(height: 12),
                  RevealOnMount(
                    key: ObjectKey(_result),
                    child: _buildResultContainer(_result!),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        HeliumElevatedButton(
          buttonText: AppLocalizations.of(context).gradeCalculatorCalculateButton,
          onPressed: _calculate,
          isLoading: _isCalculating,
        ),
      ],
    );
  }

  Widget _buildResultContainer(NeededGradeModel result) {
    if (result.isAchievable) return SuccessContainer(text: _resultMessage(result));
    return result.state == NeededGradeState.unachievable || result.state == NeededGradeState.gpaUnreachable
        ? WarningContainer(text: _resultMessage(result))
        : ErrorContainer(text: _resultMessage(result), icon: Icons.warning_amber);
  }

  void _onTargetChanged(int? value) {
    setState(() {
      _selectedTargetId = value;
      _clearResult();
    });
  }

  void _onDesiredChanged(String _) {
    setState(_clearResult);
  }
}
