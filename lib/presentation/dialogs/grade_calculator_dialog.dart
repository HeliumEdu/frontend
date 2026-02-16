// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class GradeCalculatorDialog extends StatefulWidget {
  final List<GradeCategoryModel> categories;
  final double currentOverallGrade;
  final String courseTitle;
  final double defaultDesiredGradeBoost;

  const GradeCalculatorDialog({
    super.key,
    required this.categories,
    required this.currentOverallGrade,
    required this.courseTitle,
    this.defaultDesiredGradeBoost = 5.0,
  });

  @override
  State<GradeCalculatorDialog> createState() => _GradeCalculatorDialogState();
}

class _GradeCalculatorDialogState extends State<GradeCalculatorDialog> {
  int? _selectedCategoryId;
  final TextEditingController _desiredGradeController = TextEditingController();
  NeededGradeResult? _result;

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

  @override
  void initState() {
    super.initState();
    // Pre-fill with current grade + boost as a reasonable default
    _desiredGradeController.text =
        (widget.currentOverallGrade + widget.defaultDesiredGradeBoost)
            .clamp(0, 100)
            .toStringAsFixed(1);
  }

  @override
  void dispose() {
    _desiredGradeController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_selectedCategoryId == null) {
      setState(() {
        _result = NeededGradeResult(
          neededGrade: 0,
          isAchievable: false,
          message: 'Please select a category',
        );
      });
      return;
    }

    final desiredGrade = double.tryParse(_desiredGradeController.text);
    if (desiredGrade == null || desiredGrade < 0 || desiredGrade > 100) {
      setState(() {
        _result = NeededGradeResult(
          neededGrade: 0,
          isAchievable: false,
          message: 'Please enter a valid grade between 0 and 100',
        );
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colorScheme.surface,
      title: Text(
        'What Grade Do I Need?',
        style: AppStyles.headingText(context),
      ),
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course info
              Text(
                widget.courseTitle,
                style: AppStyles.standardBodyText(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Grade: ${GradeHelper.gradeForDisplay(widget.currentOverallGrade)}',
                style: AppStyles.smallSecondaryText(context),
              ),
              const SizedBox(height: 24),

              // Category selection
              Text(
                'Select Category',
                style: AppStyles.standardBodyText(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    hint: Text(
                      'Choose a category...',
                      style: AppStyles.standardBodyText(context),
                    ),
                    items: _normalizedCategories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${category.title} (${category.weight.toStringAsFixed(0)}%)',
                                style: AppStyles.standardBodyText(context),
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
                        _result = null; // Clear previous result
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Desired grade input
              Text(
                'Desired Overall Grade',
                style: AppStyles.standardBodyText(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _desiredGradeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g., 90',
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: context.colorScheme.surfaceContainerHighest,
                ),
                style: AppStyles.standardBodyText(context),
                onChanged: (_) {
                  setState(() {
                    _result = null; // Clear result when input changes
                  });
                },
              ),
              const SizedBox(height: 24),

              // Calculate button
              SizedBox(
                width: double.infinity,
                child: HeliumElevatedButton(
                  buttonText: 'Calculate',
                  onPressed: _calculate,
                ),
              ),

              // Result display
              if (_result != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _result!.isAchievable
                        ? context.semanticColors.success.withValues(alpha: 0.1)
                        : context.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _result!.isAchievable
                          ? context.semanticColors.success
                          : context.colorScheme.error,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_result!.isAchievable &&
                          _result!.neededGrade >= 0) ...[
                        Text(
                          _result!.neededGrade.toStringAsFixed(1),
                          style: AppStyles.headingText(context).copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _result!.isAchievable
                                ? context.semanticColors.success
                                : context.colorScheme.error,
                          ),
                        ),
                        Text(
                          'needed',
                          style: AppStyles.smallSecondaryText(context).copyWith(
                            color: _result!.isAchievable
                                ? context.semanticColors.success
                                : context.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Icon(
                        _result!.isAchievable
                            ? Icons.check_circle_outline
                            : Icons.warning_outlined,
                        size: 32,
                        color: _result!.isAchievable
                            ? context.semanticColors.success
                            : context.colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!.message,
                        style: AppStyles.standardBodyText(context),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(context),
          child: HeliumElevatedButton(
            buttonText: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
