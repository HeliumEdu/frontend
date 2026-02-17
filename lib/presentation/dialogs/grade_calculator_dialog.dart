// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/error_container.dart';
import 'package:heliumapp/presentation/widgets/grade_label.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/success_container.dart';
import 'package:heliumapp/presentation/widgets/warning_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class GradeCalculatorDialog extends StatefulWidget {
  final List<GradeCategoryModel> categories;
  final double currentOverallGrade;
  final String courseTitle;
  final Color courseColor;
  final UserSettingsModel userSettings;
  final double defaultDesiredGradeBoost;

  const GradeCalculatorDialog({
    super.key,
    required this.categories,
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
  int? _selectedCategoryId;
  final TextEditingController _desiredGradeController = TextEditingController();
  NeededGradeResult? _result;
  String? _validationErrorMessage;

  // Check if course has explicit weights
  bool get _hasExplicitWeights {
    return widget.categories.any((cat) => cat.weight > 0);
  }

  // Get normalized categories with weights (calculate equal weights if none exist)
  List<GradeCategoryModel> get _normalizedCategories {
    if (_hasExplicitWeights) {
      return widget.categories;
    }

    // Calculate equal weights for all categories
    if (widget.categories.isEmpty) return [];
    final equalWeight = 100.0 / widget.categories.length;

    return widget.categories.map((cat) {
      return GradeCategoryModel(
        id: cat.id,
        title: cat.title,
        overallGrade: cat.overallGrade,
        weight: equalWeight,
        color: cat.color,
        gradeByWeight: cat.gradeByWeight,
        trend: cat.trend,
        numHomework: cat.numHomework,
        numHomeworkGraded: cat.numHomeworkGraded,
        gradePoints: cat.gradePoints,
      );
    }).toList();
  }

  List<GradeCategoryModel> get _eligibleTargetCategories {
    return _normalizedCategories.where((cat) {
      final remainingItems = cat.numHomework - cat.numHomeworkGraded;
      return cat.weight > 0 && remainingItems == 1;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with current grade + boost as a reasonable default
    _desiredGradeController.text =
        (widget.currentOverallGrade + widget.defaultDesiredGradeBoost)
            .clamp(0, 100)
            .toStringAsFixed(1);
    if (_eligibleTargetCategories.isNotEmpty) {
      _selectedCategoryId = _eligibleTargetCategories.first.id;
    }
  }

  @override
  void dispose() {
    _desiredGradeController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_eligibleTargetCategories.isEmpty) {
      setState(() {
        _result = null;
        _validationErrorMessage =
            'No categories with exactly one remaining graded item are available';
      });
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _result = null;
        _validationErrorMessage = 'Please select a category';
      });
      return;
    }

    final desiredGrade = double.tryParse(_desiredGradeController.text);
    if (desiredGrade == null || desiredGrade < 0 || desiredGrade > 100) {
      setState(() {
        _result = null;
        _validationErrorMessage =
            'Please enter a valid grade between 0 and 100';
      });
      return;
    }

    final result = GradeHelper.calculateNeededGrade(
      categories: _normalizedCategories,
      targetCategoryId: _selectedCategoryId!,
      desiredOverallGrade: desiredGrade,
    );

    setState(() {
      _result = result;
      _validationErrorMessage = null;
    });
  }

  String _buildResultMessage(NeededGradeResult result) {
    final desiredGrade = double.tryParse(_desiredGradeController.text) ?? 0;
    String targetCategoryTitle = 'this category';
    for (final category in _normalizedCategories) {
      if (category.id == _selectedCategoryId) {
        targetCategoryTitle = category.title;
        break;
      }
    }

    switch (result.state) {
      case NeededGradeState.targetCategoryHasNoWeight:
        // It should be impossible to reach this state
        return "Selected category has no weight, so we can't help make accurate predictions";
      case NeededGradeState.invalidTotalWeight:
        return "Category weights do not add up to 100%, so we can't help make accurate predictions";
      case NeededGradeState.aboveTarget:
        return 'You\'re already above your target based on current category performance.';
      case NeededGradeState.unachievable:
        return 'You would need to score ${result.neededGrade.toStringAsFixed(1)}% to reach your target.';
      case NeededGradeState.achievable:
        return 'You need to score ${result.neededGrade.toStringAsFixed(1)}% or higher on "$targetCategoryTitle" to achieve ${desiredGrade.toStringAsFixed(1)}% in this class.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colorScheme.surface,
      title: Center(
        child: Text(
          'What Grade Do I Need?',
          style: AppStyles.featureText(context),
        ),
      ),
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              CourseTitleLabel(
                title: widget.courseTitle,
                color: widget.courseColor,
              ),
              const SizedBox(height: 8),
              GradeLabel(
                grade: GradeHelper.gradeForDisplay(widget.currentOverallGrade),
                userSettings: widget.userSettings,
              ),
              const SizedBox(height: 24),

              Text('Category', style: AppStyles.formLabel(context)),
              const SizedBox(height: 9),
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
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
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: context.colorScheme.primary,
                ),
                dropdownColor: context.colorScheme.surface,
                style: AppStyles.formText(context),
                isExpanded: true,
                items: _eligibleTargetCategories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 14,
                          color: category.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${category.title} (${category.weight.toStringAsFixed(0)}%)',
                            style: AppStyles.formText(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _result = null;
                    _validationErrorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              Text('Desired Class Grade', style: AppStyles.formLabel(context)),
              const SizedBox(height: 9),
              TextFormField(
                controller: _desiredGradeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g., 90',
                  hintStyle: AppStyles.formHint(context),
                  suffixText: '%',
                  suffixStyle: AppStyles.formText(context),
                  filled: true,
                  fillColor: context.colorScheme.surface,
                  contentPadding: const EdgeInsets.only(left: 12),
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
                style: AppStyles.formText(context),
                onChanged: (_) {
                  setState(() {
                    _result = null;
                    _validationErrorMessage = null;
                  });
                },
                onFieldSubmitted: (_) => _calculate(),
              ),

              const SizedBox(height: 12),

              if (_validationErrorMessage != null) ...[
                ErrorContainer(
                  text: _validationErrorMessage!,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
              if (_result != null) ...[
                if (!_result!.isAchievable)
                  _result!.state == NeededGradeState.unachievable
                      ? WarningContainer(text: _buildResultMessage(_result!))
                      : ErrorContainer(
                          text: _buildResultMessage(_result!),
                          icon: Icons.warning_amber_rounded,
                        )
                else
                  SuccessContainer(text: _buildResultMessage(_result!)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(context),
          child: Row(
            children: [
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Close',
                  backgroundColor: context.colorScheme.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Calculate',
                  onPressed: _calculate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
