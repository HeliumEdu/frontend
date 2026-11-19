import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/presentation/ui/components/category_title_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

class GradeCategoryTable extends StatelessWidget {
  // Category table row element heights
  static const double _contributionBarHeight = 24;

  // Category table column widths
  static const double _gradedColTablet = 70;
  static const double _gradedColDesktop = 120;
  static const double _contributionColMobile = 90;
  static const double _contributionColTablet = 120;
  static const double _contributionColDesktop = 170;
  static const double _averageColMobile = 90;
  static const double _averageColDesktop = 110;

  final GradeCourseModel course;
  final UserSettingsModel userSettings;

  const GradeCategoryTable({
    super.key,
    required this.course,
    required this.userSettings,
  });

  @override
  Widget build(BuildContext context) {
    final hasWeightedGrading = course.categories.any((cat) => cat.weight > 0);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: course.color.withValues(alpha: 0.2)),
        ),
      ),
      child: _buildCategoryTable(context, course, hasWeightedGrading),
    );
  }

  Widget _buildCategoryTable(
    BuildContext context,
    GradeCourseModel course,
    bool hasWeightedGrading,
  ) {
    final sortedCategories = [...course.categories];
    Sort.byTitle(sortedCategories);
    final totalBreakdown = course.categories.fold<double>(
      0,
      (sum, cat) =>
          sum +
          (cat.gradeByWeight != null && cat.gradeByWeight! > 0
              ? cat.gradeByWeight!
              : 0),
    );
    final roundedPercentages = totalBreakdown > 0
        ? GradeHelper.largestRemainderPercents(course.categories, totalBreakdown)
        : <int, int>{};

    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: course.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Category',
                  style: AppStyles.standardBodyText(context),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasWeightedGrading)
                SizedBox(
                  width: Responsive.getResponsiveValue(
                    context,
                    mobile: _contributionColMobile,
                    tablet: _contributionColTablet,
                    desktop: _contributionColDesktop,
                  ),
                  child: Text(
                    'Contribution',
                    textAlign: TextAlign.center,
                    style: AppStyles.standardBodyText(context),
                  ),
                ),
              if (!hasWeightedGrading || !Responsive.isMobile(context))
                SizedBox(
                  width: Responsive.isTablet(context)
                      ? _gradedColTablet
                      : _gradedColDesktop,
                  child: Text(
                    'Graded',
                    textAlign: TextAlign.center,
                    style: AppStyles.standardBodyText(context),
                  ),
                ),
              SizedBox(
                width: Responsive.isMobile(context)
                    ? _averageColMobile
                    : _averageColDesktop,
                child: Text(
                  'Average',
                  textAlign: TextAlign.right,
                  style: AppStyles.standardBodyText(context),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 9),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCategories.length,
          itemBuilder: (context, catIndex) {
            final category = sortedCategories[catIndex];
            return _buildCategoryRow(
              context,
              category,
              hasWeightedGrading,
              totalBreakdown,
              roundedPercentages,
            );
          },
          separatorBuilder: (context, catIndex) {
            return const Divider(height: 1);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    GradeCategoryModel category,
    bool hasWeightedGrading,
    double totalBreakdown,
    Map<int, int> roundedPercentages,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Flexible(
                  child: SizedBox(
                    height: Responsive.isMobile(context) ? 26 : null,
                    child: CategoryTitleLabel(
                      title: category.title,
                      color: category.color,
                      compact: Responsive.isMobile(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasWeightedGrading)
            SizedBox(
              width: Responsive.getResponsiveValue(
                context,
                mobile: _contributionColMobile,
                tablet: _contributionColTablet,
                desktop: _contributionColDesktop,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child:
                    (category.gradeByWeight != null &&
                        category.gradeByWeight! > 0 &&
                        totalBreakdown > 0)
                    ? _buildBreakdownBar(
                        context,
                        category,
                        totalBreakdown,
                        roundedPercentages[category.id]!,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          if (!hasWeightedGrading || !Responsive.isMobile(context))
            SizedBox(
              width: Responsive.isTablet(context)
                  ? _gradedColTablet
                  : _gradedColDesktop,
              child: SelectableText(
                '${category.numHomeworkGraded} of ${category.numHomework}',
                textAlign: TextAlign.center,
                style: AppStyles.standardBodyText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          SizedBox(
            width: Responsive.isMobile(context)
                ? _averageColMobile
                : _averageColDesktop,
            child: Align(
              alignment: Alignment.centerRight,
              child: GradeLabel(
                grade: GradeHelper.gradeForDisplay(category.overallGrade),
                userSettings: userSettings,
                compact: Responsive.isMobile(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(
    BuildContext context,
    GradeCategoryModel category,
    double totalBreakdown,
    int roundedPercent,
  ) {
    final normalizedFraction = category.gradeByWeight! / totalBreakdown;
    final percentText = '$roundedPercent%';
    final textColor = normalizedFraction > 0.5
        ? HeliumColors.contrastingTextColor(category.color)
        : context.colorScheme.onSurface;

    return Stack(
      children: [
        Container(
          height: _contributionBarHeight,
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        FractionallySizedBox(
          widthFactor: normalizedFraction,
          child: Container(
            height: _contributionBarHeight,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        Container(
          height: _contributionBarHeight,
          alignment: Alignment.center,
          child: Text(
            percentText,
            style: AppStyles.smallSecondaryTextEmphasis(
              context,
            ).copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
