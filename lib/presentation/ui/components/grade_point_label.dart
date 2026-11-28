import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

class GradePointLabel extends StatelessWidget {
  final double? gradePoint;
  final double credits;
  final String? letterGrade;

  const GradePointLabel({
    super.key,
    required this.gradePoint,
    required this.credits,
    this.letterGrade,
  });

  @override
  Widget build(BuildContext context) {
    final showsGradePoint = gradePoint != null && credits > 0;
    final showsLetterGrade = letterGrade?.isNotEmpty ?? false;
    if (!showsGradePoint && !showsLetterGrade) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: showsGradePoint
            ? (showsLetterGrade
                ? AppLocalizations.of(context).gradePointLetterAndPointTooltip
                : AppLocalizations.of(context).gradePointPointTooltip)
            : AppLocalizations.of(context).gradePointLetterTooltip,
        child: Text(
          [
            if (showsLetterGrade) letterGrade!,
            if (showsGradePoint)
              AppLocalizations.of(context).gradePointValueLabel(
                GradeHelper.gradePointForDisplay(gradePoint!),
              ),
          ].join(' • '),
          style: AppStyles.standardBodyText(context).copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
          ),
        ),
      ),
    );
  }
}
