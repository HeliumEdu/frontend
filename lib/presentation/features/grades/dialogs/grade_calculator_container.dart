// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_dialog.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_projection_tab.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/core/analytics_service.dart';

/// Tabbed dialog container for the grade calculator feature.
///
/// Tab 0 — "What Could I Get?": projects the overall grade based on
/// hypothetical scores for each ungraded assignment.
///
/// Tab 1 — "What Do I Need?": calculates the score needed in a single
/// remaining category assignment to hit a desired overall grade.
class GradeCalculatorContainer extends StatefulWidget {
  final GradeCourseModel course;
  final UserSettingsModel userSettings;
  final double defaultDesiredGradeBoost;

  const GradeCalculatorContainer({
    super.key,
    required this.course,
    required this.userSettings,
    this.defaultDesiredGradeBoost = 5.0,
  });

  @override
  State<GradeCalculatorContainer> createState() => _GradeCalculatorContainerState();
}

class _GradeCalculatorContainerState extends State<GradeCalculatorContainer>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['What Could I Get?', 'What Do I Need?'];
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    unawaited(AnalyticsService().logScreenView(screenName: 'grade_calculator_what_could_i_get'));
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      unawaited(AnalyticsService().logScreenView(
          screenName: 'grade_calculator_what_could_i_get'));
    } else {
      unawaited(AnalyticsService().logScreenView(
          screenName: 'grade_calculator_what_do_i_need'));
    }
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
                    IconButton(
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: context.colorScheme.secondary),
                    ),
                    Text('Grade Calculator', style: AppStyles.pageTitle(context)),
                    const Icon(Icons.space_bar, color: Colors.transparent),
                  ],
                ),

                TabBar(
                  controller: _tabController,
                  tabs: _tabs.map((label) => Tab(text: label)).toList(),
                  labelStyle: AppStyles.formLabel(context).copyWith(
                    fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 15),
                  ),
                  unselectedLabelStyle: AppStyles.formText(context).copyWith(
                    fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 15),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
                const SizedBox(height: 16),

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
                            currentOverallGrade: widget.course.overallGrade,
                            courseTitle: widget.course.title,
                            courseColor: widget.course.color,
                            userSettings: widget.userSettings,
                          ),
                          GradeCalculatorDialog(
                            categories: widget.course.categories,
                            currentOverallGrade: widget.course.overallGrade,
                            courseTitle: widget.course.title,
                            courseColor: widget.course.color,
                            userSettings: widget.userSettings,
                            defaultDesiredGradeBoost: widget.defaultDesiredGradeBoost,
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
}
