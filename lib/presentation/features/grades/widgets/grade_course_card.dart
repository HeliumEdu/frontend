import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/presentation/features/grades/widgets/grade_category_table.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_point_label.dart';
import 'package:heliumapp/presentation/ui/layout/collapsing_row.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class GradeCourseCard extends StatelessWidget {
  final GlobalKey cardKey;
  final int index;
  final GradeCourseModel course;
  final bool isExpanded;
  final bool isAtRisk;
  final UserSettingsModel userSettings;
  final VoidCallback onToggle;

  const GradeCourseCard({
    super.key,
    required this.cardKey,
    required this.index,
    required this.course,
    required this.isExpanded,
    required this.isAtRisk,
    required this.userSettings,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Card(
        key: cardKey,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.containerContentInset),
          child: Column(
            children: [
              _buildCourseSummaryArea(context),

              AnimatedSize(
                duration: MotionService().effectiveDuration(
                  AppConstants.uiAnimationDuration,
                ),
                curve: Curves.easeInOut,
                child: isExpanded && course.categories.isNotEmpty
                    ? GradeCategoryTable(
                        course: course,
                        userSettings: userSettings,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    } catch (e, st) {
      ErrorHelpers.logAndReport(
        'Failed to render grade course card at index $index',
        e,
        st,
      );
      return const SizedBox.shrink();
    }
  }

  Widget _buildGradeSummaryRow(BuildContext context) {
    final letterGrade = GradeHelper.gradeBandFor(
      course.overallGrade,
      course.gradeScale,
    )?.label;
    return CollapsingRow(
      steps: 4,
      children: [
        CollapsingRowItem(
          child: GradeLabel(
            grade: GradeHelper.gradeForDisplay(course.overallGrade),
            userSettings: userSettings,
            compact: Responsive.isMobile(context),
          ),
        ),
        if (course.trend != null)
          CollapsingRowItem(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                course.trend! > 0
                    ? Icons.trending_up
                    : course.trend! < 0
                    ? Icons.trending_down
                    : Icons.trending_flat,
                size: Responsive.getIconSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                color: course.trend! > 0
                    ? context.semanticColors.success
                    : course.trend! < 0
                    ? context.colorScheme.error
                    : context.colorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
              ),
            ),
          ),
        CollapsingRowItem(
          through: 2,
          child: GradePointLabel(
            gradePoint: course.gradePoint,
            credits: course.credits,
            letterGrade: letterGrade,
          ),
        ),
        CollapsingRowItem(
          from: 3,
          child: GradePointLabel(
            gradePoint: null,
            credits: course.credits,
            letterGrade: letterGrade,
          ),
        ),
        if (course.categories.any((c) => c.weight > 0))
          CollapsingRowItem(
            through: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.circle,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 6,
                    tablet: 7,
                    desktop: 8,
                  ),
                  color: context.colorScheme.onSurface.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Weighted grading',
                  child: Icon(
                    Icons.balance,
                    size: Responsive.getIconSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: context.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        CollapsingRowItem(
          through: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.circle,
                size: Responsive.getIconSize(
                  context,
                  mobile: 6,
                  tablet: 7,
                  desktop: 8,
                ),
                color: context.colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.numHomeworkGraded} graded',
                style: AppStyles.standardBodyText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSummaryArea(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Feedback.forTap(context);
          onToggle();
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CourseTitleLabel(
                            title: course.title,
                            color: course.color,
                          ),
                        ),
                      ),
                      if (isAtRisk) ...[
                        const SizedBox(width: 8),
                        const _AtRiskBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildGradeSummaryRow(context),
                ],
              ),
            ),
            const SizedBox(width: 4),
            PrintHidden(
              child: GradeExpandButton(
                isExpanded: isExpanded,
                onPressed: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradeExpandButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onPressed;

  const GradeExpandButton({
    super.key,
    required this.isExpanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.getIconSize(
      context,
      mobile: 20,
      tablet: 22,
      desktop: 24,
    );
    return IconButton(
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(4),
        minimumSize: Size.zero,
      ),
      constraints: const BoxConstraints(),
      icon: AnimatedRotation(
        turns: isExpanded ? 0.5 : 0,
        duration: MotionService().effectiveDuration(
          AppConstants.uiAnimationDuration,
        ),
        child: Icon(
          Icons.keyboard_arrow_down,
          color: context.colorScheme.primary,
          size: iconSize,
          semanticLabel: isExpanded ? 'Collapse' : 'Expand',
        ),
      ),
      onPressed: onPressed,
    );
  }
}

class _AtRiskBadge extends StatelessWidget {
  const _AtRiskBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber,
            size: Responsive.getIconSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
            color: context.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'At-Risk',
            style: AppStyles.smallSecondaryText(context).copyWith(
              color: context.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
