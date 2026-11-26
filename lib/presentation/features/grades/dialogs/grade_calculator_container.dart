import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_dialog.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_gpa.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_projection_tab.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_point_label.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/motion_service.dart';

/// Tabbed dialog container for the grade calculator feature.
///
/// Tab 0 — "What Could I Get?": projects the overall grade (or GPA) based on
/// hypothetical scores for each ungraded assignment.
///
/// Tab 1 — "What Do I Need?": calculates the score needed in a single
/// remaining category assignment to hit a desired overall grade (or GPA).
class GradeCalculatorContainer extends StatefulWidget {
  final GradeCourseModel course;
  final List<GradeCourseGroupModel> courseGroups;
  final double? cumulativeGpa;
  final UserSettingsModel userSettings;
  final double defaultDesiredGradeBoost;
  final String? termWeek;

  const GradeCalculatorContainer({
    super.key,
    required this.course,
    required this.courseGroups,
    this.cumulativeGpa,
    required this.userSettings,
    this.defaultDesiredGradeBoost = 5.0,
    this.termWeek,
  });

  @override
  State<GradeCalculatorContainer> createState() => _GradeCalculatorContainerState();
}

class _GradeCalculatorContainerState extends State<GradeCalculatorContainer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final GradeCalculatorGpa? _gpa;
  GradeCalculatorMode _mode = GradeCalculatorMode.classGrade;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: GradeCalculatorTab.values.length,
      vsync: this,
      animationDuration: MotionService().effectiveDuration(AppConstants.uiAnimationDuration),
    );
    _tabController.addListener(_onTabChanged);
    final courseGroup = widget.courseGroups
        .where((group) => group.courses.any((c) => c.id == widget.course.id))
        .firstOrNull;
    _gpa = courseGroup == null ||
            widget.course.gradeScale.isEmpty ||
            _hasNoCredits
        ? null
        : GradeCalculatorGpa.of(
            widget.course,
            courseGroup,
            widget.courseGroups,
            widget.cumulativeGpa,
            priorCredits: widget.userSettings.priorCredits,
            priorGpa: widget.userSettings.priorGpa,
          );
    _logScreenView();
  }

  bool get _hasNoCredits => widget.course.credits <= 0;

  String? get _missingCreditsHint =>
      _hasNoCredits ? AppLocalizations.of(context).gradeCalculatorGpaNeedsCreditsHint : null;

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _logScreenView();
  }

  void _logScreenView() {
    final tab = GradeCalculatorTab.values[_tabController.index];
    unawaited(AnalyticsService().logScreenView(
        screenName: 'grade_calculator_${tab.name}_${_mode.name}'));
  }

  void _onModeChanged(DropDownItem<GradeCalculatorMode>? item) {
    final mode = item?.value;
    if (mode == null || mode == _mode) return;
    setState(() => _mode = mode);
    _logScreenView();
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = Responsive.isMobile(context)
        ? MediaQuery.of(context).size.height * 0.8
        : 540.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.isMobile(context)
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: SizedBox(
        width: Responsive.getDialogWidth(context, fallback: 460),
        height: dialogHeight,
        child: Material(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.space_bar, color: Colors.transparent),
                    Text(
                      AppLocalizations.of(context).gradeCalculatorTitle,
                      style: AppStyles.pageTitle(context),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: context.colorScheme.secondary,
                        semanticLabel: AppLocalizations.of(context).commonCloseLabel,
                      ),
                    ),
                  ],
                ),

                TabBar(
                  controller: _tabController,
                  tabs: GradeCalculatorTab.values.map((tab) => Tab(text: tab.label)).toList(),
                  labelStyle: AppStyles.formLabel(context).copyWith(
                    fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 15),
                  ),
                  unselectedLabelStyle: AppStyles.formText(context).copyWith(
                    fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 15),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: Responsive.isNarrowMobile(context)
                      ? const EdgeInsets.symmetric(horizontal: 6)
                      : null,
                ),
                const SizedBox(height: 16),
                _buildCourseHeader(context),
                const SizedBox(height: 12),

                Expanded(
                  child: ListenableBuilder(
                    listenable: _tabController,
                    builder: (context, _) {
                      return IndexedStack(
                        index: _tabController.index,
                        sizing: StackFit.expand,
                        children: [
                          GradeProjectionTab(
                            categories: widget.course.categories,
                            ungradedAssignments: widget.course.ungradedAssignments,
                            pointsEarned: widget.course.pointsEarned,
                            pointsPossible: widget.course.pointsPossible,
                            currentOverallGrade: widget.course.overallGrade,
                            courseColor: widget.course.color,
                            userSettings: widget.userSettings,
                            mode: _mode,
                            gpa: _gpa,
                            hasAssignments: widget.course.numHomework > 0,
                            termWeek: widget.termWeek,
                          ),
                          GradeCalculatorDialog(
                            courseId: widget.course.id,
                            categories: widget.course.categories,
                            ungradedAssignments: widget.course.ungradedAssignments,
                            currentOverallGrade: widget.course.overallGrade,
                            courseColor: widget.course.color,
                            defaultDesiredGradeBoost: widget.defaultDesiredGradeBoost,
                            mode: _mode,
                            gpa: _gpa,
                            termWeek: widget.termWeek,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHeader(BuildContext context) {
    final course = widget.course;
    final modes = [
      DropDownItem(
        id: GradeCalculatorMode.classGrade.index,
        value: GradeCalculatorMode.classGrade,
        label: AppLocalizations.of(context).gradeCalculatorClassGradeOption,
      ),
      DropDownItem(
        id: GradeCalculatorMode.termGpa.index,
        value: GradeCalculatorMode.termGpa,
        label: AppLocalizations.of(context).gradeCalculatorTermGpaOption,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourseTitleLabel(title: course.title, color: course.color),
        const SizedBox(height: 4),
        Row(
          children: [
            GradeLabel(
              grade: GradeHelper.gradeForDisplay(course.overallGrade),
              userSettings: widget.userSettings,
            ),
            GradePointLabel(
              gradePoint: course.gradePoint,
              credits: course.credits,
            ),
          ],
        ),
        if (course.gradeScale.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropDown<GradeCalculatorMode>(
            key: ValueKey(_mode),
            label: AppLocalizations.of(context).gradeCalculatorCalculateForLabel,
            initialValue: modes[_mode.index],
            items: modes,
            onChanged: _gpa == null ? null : _onModeChanged,
            helperText: _missingCreditsHint,
          ),
        ],
      ],
    );
  }
}
