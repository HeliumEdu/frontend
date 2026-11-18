import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_bloc.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_event.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_container.dart';
import 'package:heliumapp/presentation/features/grades/widgets/grade_course_card.dart';
import 'package:heliumapp/presentation/features/grades/widgets/grade_trend_chart.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/group_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/components/hover_tap_target.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_menu.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/course_group_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/screen_dropdown_filter_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) => const _GradesProvidedScreen();
}

class _GradesProvidedScreen extends StatefulWidget {
  const _GradesProvidedScreen();

  @override
  State<_GradesProvidedScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends BasePageScreenState<_GradesProvidedScreen> {
  static const _savedGradeGraphSettingsKey = 'saved_grades_graph_settings';

  @override
  bool get enablePrint => true;


  double get _atRiskThreshold => userSettings.atRiskThreshold.toDouble();

  double get _onTrackTolerance => userSettings.onTrackTolerance.toDouble();

  double get _chartAnimationDurationMs => MotionService()
      .effectiveDuration(_chartAnimationDuration)
      .inMilliseconds
      .toDouble();
  static const double _defaultDesiredGradeBoost = 5.0;
  static const _chartAnimationDuration = Duration(milliseconds: 250);

  List<CourseGroupModel> _courseGroups = [];
  List<GradeCourseGroupModel> _grades = [];
  double? _cumulativeGpa;
  int? _selectedGroupId;
  int? _pendingImpactCourseId;
  final Set<int> _expandedCourseIds = {};
  final Map<int, GlobalKey> _courseCardKeys = {};

  GradeTrendViewMode _graphViewMode = const GradeTrendViewMode.term();
  final Map<String, bool> _visibleSeries = {};
  bool _autoAdjustToGradedRange = false;
  bool _hideLegend = false;
  bool _graphExpanded = true;

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (!mounted || settings == null) return settings;
      _restoreSelectedGroup(settings);
      _restoreGraphSettingsIfEnabled(settings);
      return settings;
    });
  }

  @override
  void loadScreenData({required bool forceRefresh}) {
    if (forceRefresh && !(settingsLoaded && userSettings.rememberFilterState)) {
      setState(() {
        _selectedGroupId = CourseGroupHelpers.currentGroupId(_courseGroups);
      });
    }
    context.read<GradeBloc>().add(
      FetchGradeScreenDataEvent(forceRefresh: forceRefresh),
    );
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdated) {
            final settings = state.user.settings;
            final priorChanged = settingsLoaded &&
                (settings.priorCredits != userSettings.priorCredits ||
                    settings.priorGpa != userSettings.priorGpa);
            setState(() {
              userSettings = settings;
            });
            if (priorChanged) {
              context.read<GradeBloc>().add(
                FetchGradeScreenDataEvent(forceRefresh: true),
              );
            }
          }
        },
      ),
      BlocListener<GradeBloc, GradeState>(
        listener: (context, state) {
          if (state is GradesError) {
            setState(() {
              isLoading = false;
              screenError = state.message ?? HeliumException.unexpectedError;
            });
          } else if (state is GradeScreenDataFetched) {
            setState(() => screenError = null);
            _populateInitialStateData(state);
          }
        },
      ),
      BlocListener<PlannerItemBloc, PlannerItemState>(
        listener: (context, state) {
          if (state is HomeworkCreated ||
              state is HomeworkDeleted ||
              state is HomeworkUpdated) {
            context.read<GradeBloc>().add(
              FetchGradeScreenDataEvent(forceRefresh: true),
            );
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    if (_courseGroups.isEmpty) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GroupDropdown(
        groups: _courseGroups,
        initialSelection: _courseGroups.firstWhereOrNull(
              (g) => g.id == _selectedGroupId,
        ),
        isReadOnly: true,
        onChanged: (value) {
          if (value == null) return;
          if (value.id == _selectedGroupId) return;

          setState(() {
            _selectedGroupId = value.id;
            _pendingImpactCourseId = null;
            _expandedCourseIds.clear();
            _showEntireTermIfGraphViewUnavailable();
          });
          _saveSelectedGroup();
        },
      ),
    );
  }


  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<GradeBloc, GradeState>(
      builder: (context, state) {
        if (state is GradesLoading) {
          return const Center(child: LoadingIndicator(expanded: false));
        }

        if (screenError != null) {
          return ErrorCard(
            message: screenError!,
            source: 'grades_screen',
            onReload: reloadPage,
          );
        }

        final List<GradeCourseModel> courses =
            _grades.firstWhereOrNull((g) => g.id == _selectedGroupId)?.courses ??
            [];

        if (_grades.isEmpty || courses.isEmpty) {
          return const EmptyCard(
            icon: Icons.bar_chart,
            title: "You haven't added any classes yet",
            message: 'Head over to "Classes" to get started',
            expanded: false,
          );
        }

        return _buildGradesPage(courses);
      },
    );
  }

  void _populateInitialStateData(GradeScreenDataFetched state) {
    setState(() {
      _courseGroups = state.courseGroups;
      _grades = state.grades;
      _cumulativeGpa = state.cumulativeGpa;
      _selectedGroupId = _selectableGroupId(_selectedGroupId);
      _pendingImpactCourseId = null;
      _showEntireTermIfGraphViewUnavailable();
      isLoading = false;
    });
  }

  /// Falls back to Entire Term when the graph's view isn't offered for the
  /// selected term: a class from another term, or GPA Across Terms.
  void _showEntireTermIfGraphViewUnavailable() {
    final selectedGroup =
        _grades.firstWhereOrNull((g) => g.id == _selectedGroupId);
    final isAvailable = _graphViewMode.isGpaAcrossTerms
        ? _offersGpaAcrossTerms
        : _graphViewMode.isTerm ||
            (selectedGroup?.courses.any((c) => c.id == _graphViewMode.courseId) ??
                false);
    if (!isAvailable) _graphViewMode = const GradeTrendViewMode.term();
  }

  bool get _offersGpaAcrossTerms {
    final termsWithGpa = _grades
        .where((g) => g.inCumulativeGpa && g.gpa != null)
        .length;
    return termsWithGpa > 1 ||
        (termsWithGpa == 1 && userSettings.priorCredits > 0);
  }

  Widget _buildGradesPage(List<GradeCourseModel> courses) {
    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrintPageBreak(child: _buildTermSummaryArea()),

            PrintPageBreak(child: Builder(
              builder: (context) {
                try {
                  return _buildGraphArea();
                } catch (e, st) {
                  ErrorHelpers.logAndReport(
                    'Failed to render grades graph',
                    e,
                    st,
                  );
                  return ErrorCard(
                    message: 'An unknown error occurred loading the graph',
                    source: 'grades_screen',
                    expanded: false,
                    onReload: reloadPage,
                  );
                }
              },
            )),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return PrintPageBreak(
                  child: GradeCourseCard(
                    cardKey: _courseCardKeys.putIfAbsent(
                      course.id,
                      () => GlobalKey(),
                    ),
                    index: index,
                    course: course,
                    isExpanded:
                        isCapturing || _expandedCourseIds.contains(course.id),
                    isAtRisk: GradeHelper.isAtRisk(course, _atRiskThreshold),
                    userSettings: userSettings,
                    onToggle: () => _toggleExpandedCourse(course.id),
                  ),
                );
              },
            ),
          ],
        );

        if (isCapturing) return content;
        return SingleChildScrollView(child: content);
      },
    );
  }

  Widget _buildTermSummaryArea() {
    if (_grades.isEmpty || _selectedGroupId == null) {
      return const SizedBox.shrink();
    }

    final selectedGroup = _grades.firstWhere(
          (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    final cardBuilders = [
          () => _buildOverallGradeCard(selectedGroup),
          () => _buildProgressVsPaceCard(selectedGroup),
          () => _buildAtRiskCoursesCard(selectedGroup),
          () => _buildPendingImpactCard(selectedGroup),
    ];
    final cards = cardBuilders.map((build) {
      try {
        return build();
      } catch (e, st) {
        ErrorHelpers.logAndReport(
          'Failed to render grades summary card',
          e,
          st,
        );
        return const SizedBox.shrink();
      }
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = Responsive.getColumnCountForWidth(
          constraints.maxWidth,
          mobile: 2,
          tablet: 2,
          desktop: 4,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 12,
            mainAxisExtent: _summaryCardHeight,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  double get _summaryCardHeight =>
      Responsive.getResponsiveValue(
        context,
        mobile: 200,
        tablet: 190,
        desktop: 260,
      );

  double get _summaryCircleSize =>
      Responsive.getResponsiveValue(
        context,
        mobile: 60,
        tablet: 50,
        desktop: 80,
      );

  /// The share of the gauge's square box that its half circle (arc and end
  /// caps) fills, from the top; the rest of the box is empty.
  static const _halfGaugeHeightFactor = 0.54;

  double get _summaryGaugeHeight =>
      Responsive.getResponsiveValue(
        context,
        mobile: 100,
        tablet: 100,
        desktop: 140,
      );

  Widget _buildSummaryCard({required Widget child}) {
    return Card(
      elevation: 2,
      child: SizedBox(
        height: _summaryCardHeight,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.containerContentInset),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSummaryTitle(String title) {
    return Text(
      title,
      style: AppStyles.standardBodyTextEmphasis(context),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOverallGradeCard(GradeCourseGroupModel selectedGroup) {
    final grade = selectedGroup.overallGrade;
    final gradeDisplay = GradeHelper.gradeForDisplay(grade);
    final overallGradeUrgency = grade >= _atRiskThreshold + _onTrackTolerance
        ? 1
        : grade >= _atRiskThreshold
        ? 2
        : 3;
    final overallGradeColor = HeliumColors.urgencyColor(
      context,
      overallGradeUrgency,
    );

    final trend = selectedGroup.trend;

    return _buildSummaryCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSummaryTitle('Overall Grade'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.topCenter,
            heightFactor: _halfGaugeHeightFactor,
            child: SizedBox(
              height: _summaryGaugeHeight,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    startAngle: 180,
                    endAngle: 0,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.15,
                      cornerStyle: CornerStyle.bothCurve,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: grade,
                        width: 0.15,
                        sizeUnit: GaugeSizeUnit.factor,
                        cornerStyle: CornerStyle.bothCurve,
                        gradient: SweepGradient(
                          colors: <Color>[
                            overallGradeColor,
                            overallGradeColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gradeDisplay,
                style: AppStyles.headingText(context).copyWith(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 28,
                    tablet: 32,
                    desktop: 36,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 4),
                Icon(
                  trend > 0
                      ? Icons.trending_up
                      : trend < 0
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  size: 20,
                  color: trend > 0
                      ? HeliumColors.urgencyColor(context, 1)
                      : trend < 0
                      ? HeliumColors.urgencyColor(context, 3)
                      : context.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
          if (selectedGroup.gpa != null ||
              (selectedGroup.inCumulativeGpa &&
                  userSettings.priorCredits > 0 &&
                  _canShowCumulativeGpa(selectedGroup)))
            _buildGpaSummary(selectedGroup),
        ],
      ),
    );
  }

  Widget _buildGpaSummary(GradeCourseGroupModel selectedGroup) {
    final showsPriorCredits = _canShowCumulativeGpa(selectedGroup) &&
        !Responsive.isSlimMobile(context);
    final hint = GradeHelper.gpaHint(
      selectedGroup,
      _grades,
      priorCredits: showsPriorCredits ? userSettings.priorCredits : 0,
      priorGpa: userSettings.priorGpa,
    );
    final showsCumulativeGpa = _canShowCumulativeGpa(selectedGroup) &&
        !(hint != null &&
            selectedGroup.gpa != null &&
            Responsive.isSlimMobile(context));
    final text = [
      if (selectedGroup.gpa != null)
        'GPA ${GradeHelper.gradePointForDisplay(selectedGroup.gpa!)}',
      if (showsCumulativeGpa)
        'All ${GradeHelper.gradePointForDisplay(_cumulativeGpa!)}',
    ].join(' • ');
    final hintColor = context.colorScheme.onSurface.withValues(
      alpha: AppStyles.mutedIconAlpha,
    );
    final hintIconSize = Responsive.getIconSize(
      context,
      mobile: 14,
      tablet: 16,
      desktop: 18,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: AppStyles.standardBodyTextEmphasis(context)),
        if (hint != null) ...[
          SizedBox(
            width: (HoverTapTarget.extentOf(context) - hintIconSize) / 2 + 4,
          ),
          HoverTapTarget(
            onTap: (anchorContext) => _showGpaHint(anchorContext, hint),
            color: hintColor,
            tooltip: 'Show GPA details',
            child: Icon(
              Icons.info_outline,
              size: hintIconSize,
              color: hintColor,
            ),
          ),
        ],
      ],
    );
  }

  bool _canShowCumulativeGpa(GradeCourseGroupModel selectedGroup) {
    return !selectedGroup.exampleSchedule &&
        _cumulativeGpa != null &&
        (_grades.where((g) => g.inCumulativeGpa).length > 1 ||
            userSettings.priorCredits > 0) &&
        !Responsive.isNarrowMobile(context);
  }

  void _showGpaHint(BuildContext anchorContext, String hint) {
    showHeliumMenu(
      context: context,
      anchorContext: anchorContext,
      builder: (menuContext, _) => HeliumMenuContent(
        width: HeliumMenuContent.listWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeliumMenuTitle(title: 'GPA'),
            const SizedBox(height: 8),
            Text(hint, style: AppStyles.standardBodyText(menuContext)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressVsPaceCard(GradeCourseGroupModel selectedGroup) {
    final courseGroup = _courseGroups.firstWhere(
          (g) => g.id == _selectedGroupId,
    );

    // Calculate completion percentage
    final completionPercent = selectedGroup.numHomework > 0
        ? (selectedGroup.numHomeworkCompleted / selectedGroup.numHomework * 100)
        .round()
        : 0;

    // Calculate time passed percentage
    final timePercent = HeliumDateTime.getPercentDiffBetween(
      courseGroup.startDate,
      courseGroup.endDate,
    );

    final difference = completionPercent - timePercent;
    final isWarmingUp = selectedGroup.numHomework == 0 ||
        (timePercent == 0 && completionPercent == 0);
    final String status;
    final Color statusColor;
    if (isWarmingUp) {
      status = 'Warming Up';
      statusColor = context.colorScheme.outline;
    } else if (completionPercent >= 100 && timePercent >= 100) {
      status = 'All Done';
      statusColor = HeliumColors.urgencyColor(context, 1);
    } else if (difference > _onTrackTolerance) {
      status = 'Ahead';
      statusColor = HeliumColors.urgencyColor(context, 1);
    } else if (difference >= -_onTrackTolerance) {
      status = 'On Track';
      statusColor = HeliumColors.urgencyColor(context, 1);
    } else {
      status = 'Behind';
      final expectedWorkAtRiskCutoff = timePercent * (_atRiskThreshold / 100);
      statusColor = HeliumColors.urgencyColor(
        context,
        completionPercent < expectedWorkAtRiskCutoff ? 3 : 2,
      );
    }

    return _buildSummaryCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildSummaryTitle('Progress vs. Pace')),
          const SizedBox(height: 16),
          // Work completion bar
          Row(
            children: [
              SizedBox(
                width: 60.0,
                child: Text(
                  'Work',
                  style: AppStyles.smallSecondaryText(context),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: completionPercent / 100,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    Container(
                      height: 24,
                      alignment: Alignment.center,
                      child: Text(
                        '$completionPercent%',
                        style: AppStyles.smallSecondaryText(context).copyWith(
                          color: completionPercent > 50
                              ? HeliumColors.contrastingTextColor(statusColor)
                              : context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time passed bar
          Row(
            children: [
              SizedBox(
                width: 60.0,
                child: Text(
                  'Time',
                  style: AppStyles.smallSecondaryText(context),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: timePercent / 100,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.colorScheme.outline,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    Container(
                      height: 24,
                      alignment: Alignment.center,
                      child: Text(
                        '$timePercent%',
                        style: AppStyles.smallSecondaryText(context).copyWith(
                          color: timePercent > 50
                              ? HeliumColors.contrastingTextColor(
                            context.colorScheme.outline,
                          )
                              : context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'Warming Up'
                        ? Icons.hourglass_top
                        : status == 'All Done'
                        ? Icons.celebration_outlined
                        : status == 'Ahead'
                        ? Icons.fast_forward
                        : status == 'Behind'
                        ? Icons.warning_outlined
                        : Icons.check_circle_outline,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: AppStyles.standardBodyTextEmphasis(context).copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskCoursesCard(GradeCourseGroupModel selectedGroup) {
    final atRiskCourses = selectedGroup.courses
        .where((course) => GradeHelper.isAtRisk(course, _atRiskThreshold))
        .toList();
    final atRiskCount = atRiskCourses.length;
    final totalGraded = selectedGroup.courses
        .where(GradeHelper.hasGrade)
        .fold(0, (sum, course) => sum + course.numHomeworkGraded);
    final hasGradedWork = atRiskCount > 0 || totalGraded > 0;
    final circleColor = atRiskCount > 0
        ? context.colorScheme.error
        : context.semanticColors.success;

    return MouseRegion(
      cursor: atRiskCount > 0
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Semantics(
        button: atRiskCount > 0,
        child: GestureDetector(
          onTap: atRiskCount > 0
              ? () {
            Feedback.forTap(context);
            final atRiskCourseIds = atRiskCourses.map((c) => c.id).toSet();

            setState(() {
              _expandedCourseIds
                ..clear()
                ..addAll(atRiskCourseIds);
            });

            final firstAtRiskId = atRiskCourses.first.id;
            Future.delayed(const Duration(milliseconds: 350), () {
              if (!mounted) return;
              final firstAtRiskContext =
                  _courseCardKeys[firstAtRiskId]?.currentContext;
              if (firstAtRiskContext == null) return;
              if (!firstAtRiskContext.mounted) return;
              Scrollable.ensureVisible(
                firstAtRiskContext,
                duration: MotionService().effectiveDuration(AppConstants.uiAnimationDuration),
                curve: Curves.easeInOut,
                alignment: 0.1,
              );
            });
          }
              : null,
          child: _buildSummaryCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSummaryTitle('At-Risk Classes'),
                const SizedBox(height: 12),
                Container(
                  width: _summaryCircleSize,
                  height: _summaryCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasGradedWork
                        ? circleColor.withValues(alpha: 0.15)
                        : context.colorScheme.surfaceContainer,
                    border: Border.all(
                      color: hasGradedWork
                          ? circleColor
                          : context.colorScheme.outline,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      atRiskCount.toString(),
                      style: AppStyles.headingText(context).copyWith(
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 32,
                          tablet: 26,
                          desktop: 40,
                        ),
                        color: hasGradedWork
                            ? circleColor
                            : context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (hasGradedWork) ...[
                  const SizedBox(height: 12),
                  Text(
                    atRiskCount == 0
                        ? 'All classes passing!'
                        : 'below ${_atRiskThreshold.toInt()}%',
                    style: AppStyles.smallSecondaryText(context).copyWith(
                      color: atRiskCount > 0
                          ? context.colorScheme.error
                          : context.semanticColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingImpactCard(GradeCourseGroupModel selectedGroup) {
    final ungradedCount = selectedGroup.numHomeworkGraded > 0
        ? selectedGroup.numHomework - selectedGroup.numHomeworkGraded
        : selectedGroup.numHomework;

    final sortedCourses = [
      for (final course in selectedGroup.courses)
        if (course.numHomework - course.numHomeworkGraded > 0) course,
    ]..sort((a, b) {
        final aU = a.numHomework - a.numHomeworkGraded;
        final bU = b.numHomework - b.numHomeworkGraded;
        return bU.compareTo(aU);
      });

    final topCourse = sortedCourses.isNotEmpty ? sortedCourses.first : null;

    final displayCourse = _pendingImpactCourseId != null
        ? selectedGroup.courses.firstWhereOrNull(
              (c) => c.id == _pendingImpactCourseId,
            ) ??
            topCourse
        : topCourse;

    final displayUngraded = displayCourse != null
        ? displayCourse.numHomework - displayCourse.numHomeworkGraded
        : 0;

    final impactAssignment = displayCourse?.ungradedAssignments.firstOrNull;
    final impactTitle = impactAssignment?.title;

    return _buildSummaryCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSummaryTitle('Pending Impact'),
          SizedBox(height: Responsive.getResponsiveValue(context, mobile: 4, desktop: 8)),
          Container(
            width: _summaryCircleSize,
            height: _summaryCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ungradedCount > 0
                  ? context.semanticColors.warning.withValues(alpha: 0.15)
                  : context.colorScheme.surfaceContainer,
              border: Border.all(
                color: ungradedCount > 0
                    ? context.semanticColors.warning
                    : context.colorScheme.outline,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                ungradedCount.toString(),
                style: AppStyles.headingText(context).copyWith(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 28,
                    tablet: 24,
                    desktop: 36,
                  ),
                  color: ungradedCount > 0
                      ? context.semanticColors.warning
                      : context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(height: Responsive.getResponsiveValue(context, mobile: 4, desktop: 8)),
          Text(
            Responsive.isNarrowMobile(context)
                ? 'ungraded'
                : 'ungraded ${ungradedCount.plural('assignment')}',
            style: AppStyles.smallSecondaryText(context).copyWith(
              color: ungradedCount > 0
                  ? context.semanticColors.warning
                  : context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
            ),
            textAlign: TextAlign.center,
          ),
          if (displayCourse != null && displayUngraded > 0) ...[
            const SizedBox(height: 4),
            MouseRegion(
              cursor: sortedCourses.length > 1
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: Semantics(
                button: sortedCourses.length > 1,
                child: GestureDetector(
                  onTap: sortedCourses.length > 1
                      ? () {
                    Feedback.forTap(context);
                    _cyclePendingImpactCourse(sortedCourses);
                  }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BadgeColors.background(context, displayCourse.color),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BadgeColors.border(context, displayCourse.color)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: displayCourse.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$displayUngraded in ${displayCourse.title}',
                            style: AppStyles.smallSecondaryText(context).copyWith(
                              color: BadgeColors.foreground(context, displayCourse.color),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sortedCourses.length > 1) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_horiz,
                            size: 12,
                            color: BadgeColors.foreground(context, displayCourse.color),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (impactTitle != null) ...[
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 2, desktop: 4)),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      Feedback.forTap(context);
                      showPlannerItemAdd(
                        context,
                        homeworkId: impactAssignment!.id,
                        isEdit: true,
                        isNew: false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BadgeColors.background(context, displayCourse.color),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: BadgeColors.border(context, displayCourse.color),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 12,
                            color: BadgeColors.foreground(context, displayCourse.color),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              impactTitle,
                              style: AppStyles.smallSecondaryText(context).copyWith(
                                color: BadgeColors.foreground(context, displayCourse.color),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _cyclePendingImpactCourse(List<GradeCourseModel> sortedCourses) {
    final currentId = _pendingImpactCourseId ?? sortedCourses.first.id;
    final currentIndex = sortedCourses.indexWhere((c) => c.id == currentId);
    final nextIndex = (currentIndex + 1) % sortedCourses.length;
    setState(() => _pendingImpactCourseId = sortedCourses[nextIndex].id);
  }

  void _showGradeCalculatorOptions(BuildContext buttonContext,
      GradeCourseGroupModel selectedGroup,
      List<GradeCourseModel> courses,) {
    if (courses.length == 1) {
      _openGradeCalculator(courses.first);
      return;
    }

    if (!_graphViewMode.isTerm) {
      final filteredCourse = courses.where((c) => c.id == _graphViewMode.courseId).firstOrNull;
      if (filteredCourse != null) {
        _openGradeCalculator(filteredCourse);
        return;
      }
    }


    showHeliumMenu(
      context: context,
      anchorContext: buttonContext,
      builder: (menuContext, _) =>
          _buildGradeCalculatorPickerContent(menuContext, courses),
    );
  }

  Widget _buildGradeCalculatorPickerContent(BuildContext menuContext,
      List<GradeCourseModel> courses,) {
    return HeliumMenuContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < courses.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : 8,
                bottom: i == courses.length - 1 ? 0 : 8,
              ),
              child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.school,
                    size: 16,
                    color: courses[i].color,
                  ),
                ),
                title: Text(
                  courses[i].title,
                  style: AppStyles.formText(context),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: GradeLabel(
                  grade: GradeHelper.gradeForDisplay(
                    courses[i].overallGrade,
                  ),
                  userSettings: userSettings,
                  compact: true,
                  selectable: false,
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(menuContext);
                  _openGradeCalculator(courses[i]);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openGradeCalculator(GradeCourseModel course) {
    unawaited(AnalyticsService().logEvent(
      name: AnalyticsEvent.gradeCalculatorOpen,
      parameters: {'category': AnalyticsCategory.featureInteraction.value},
    ));
    unawaited(AnalyticsService().setUserProperty(
        name: 'uses_grade_calculator', value: 'true'));
    final gradeBloc = context.read<GradeBloc>();
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => BlocProvider<GradeBloc>.value(
        value: gradeBloc,
        child: GradeCalculatorContainer(
          course: course,
          courseGroups: _grades,
          cumulativeGpa: _cumulativeGpa,
          userSettings: userSettings,
          defaultDesiredGradeBoost: _defaultDesiredGradeBoost,
        ),
      ),
    );
  }

  Widget _buildGraphArea() {
    if (_grades.isEmpty || _selectedGroupId == null) {
      return const SizedBox.shrink();
    }

    final selectedGroup = _grades.firstWhere(
          (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    // Determine what to display based on view mode
    final isTermView = _graphViewMode.isTerm;
    if (_graphViewMode.isGpaAcrossTerms) {
      return _buildGraphCard(
        child: _buildCollapsibleGraph(
          selectedGroup,
          isTermView,
          _buildGpaAcrossTermsChart(),
        ),
      );
    }

    final List<charts.CartesianSeries<GradeTrendPoint, DateTime>> series = [];

    if (isTermView) {
      if (selectedGroup.homeworkSeries.any((item) => item.graded)) {
        series.add(
          GradeTrendChart.buildOverallSeries(
            context,
            selectedGroup.homeworkSeries,
            chartAnimationDurationMs: _chartAnimationDurationMs,
          ),
        );
      }
      if (selectedGroup.homeworkSeries.any(
        (item) => item.graded && item.gpa != null,
      )) {
        series.add(
          GradeTrendChart.buildTermGpaSeries(
            context,
            selectedGroup.homeworkSeries,
            chartAnimationDurationMs: _chartAnimationDurationMs,
          ),
        );
      }
      for (var course in selectedGroup.courses) {
        if (course.homeworkSeries.any((item) => item.graded)) {
          series.add(
            GradeTrendChart.buildCourseSeries(
              context,
              course,
              chartAnimationDurationMs: _chartAnimationDurationMs,
            ),
          );
        }
      }
    } else {
      final selectedCourseId = _graphViewMode.courseId;
      final course = selectedCourseId == null
          ? null
          : selectedGroup.courses.firstWhereOrNull(
            (c) => c.id == selectedCourseId,
      );
      if (course != null) {
        if (course.homeworkSeries.any((item) => item.graded)) {
          series.add(
            GradeTrendChart.buildOverallSeries(
              context,
              course.homeworkSeries,
              chartAnimationDurationMs: _chartAnimationDurationMs,
            ),
          );
        }
        for (var category in course.categories) {
          if (category.homeworkSeries.any((item) => item.graded)) {
            series.add(
              GradeTrendChart.buildCategorySeries(
                context,
                category,
                chartAnimationDurationMs: _chartAnimationDurationMs,
              ),
            );
          }
        }
      }
    }

    if (series.isEmpty) {
      return _buildGraphCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade Trend', style: AppStyles.headingText(context)),
            const SizedBox(height: 16),
            const EmptyCard(
              icon: Icons.bar_chart,
              title: 'Nothing to visualize yet',
              message:
                  "Come back here after you've entered some grades on \"Planner\"",
              expanded: false,
            ),
          ],
        ),
      );
    }

    return _buildGraphCard(
      child: _buildCollapsibleGraph(
        selectedGroup,
        isTermView,
        _buildChart(series, selectedGroup.id),
      ),
    );
  }

  Widget _buildCollapsibleGraph(
    GradeCourseGroupModel selectedGroup,
    bool isTermView,
    Widget chart,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGraphHeader(selectedGroup, isTermView),
        AnimatedSize(
          duration: MotionService().effectiveDuration(AppConstants.uiAnimationDuration),
          curve: Curves.easeInOut,
          child: _graphExpanded
              ? Column(
            children: [
              const SizedBox(height: 16),
              chart,
            ],
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildGraphCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }

  Widget _buildGraphHeader(GradeCourseGroupModel gradeGroup, bool isTermView) {
    final coursesWithCategories = gradeGroup.courses
        .where((course) => course.categories.isNotEmpty)
        .toList();
    final course = GradeTrendChart.getSelectedCourse(
      grades: _grades,
      selectedGroupId: _selectedGroupId,
      graphViewMode: _graphViewMode,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Feedback.forTap(context);
          setState(() {
            _graphExpanded = !_graphExpanded;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title
            Expanded(
              child: Row(
                children: [
                  if (_graphViewMode.isGpaAcrossTerms)
                    Text('GPA Across Terms', style: AppStyles.headingText(context))
                  else ...[
                    if (!Responsive.isMobile(context))
                      Text('Grade Trend', style: AppStyles.headingText(context)),
                    if (Responsive.isMobile(context) && course == null)
                      Text('Entire Term', style: AppStyles.headingText(context)),
                  ],
                  if (course != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: CourseTitleLabel(
                        title: course.title,
                        color: course.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Calculator icon for grade calculator
            if (coursesWithCategories.isNotEmpty) const SizedBox(width: 8),
            if (coursesWithCategories.isNotEmpty)
              PrintHidden(
                child: Builder(
                  builder: (buttonContext) => IconButton.outlined(
                    tooltip: 'Grade Calculator',
                    icon: const Icon(Icons.calculate_outlined),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: context.colorScheme.primary,
                      ),
                    ),
                    onPressed: () => _showGradeCalculatorOptions(
                      buttonContext,
                      gradeGroup,
                      coursesWithCategories,
                    ),
                  ),
                ),
              ),
            if (coursesWithCategories.isNotEmpty) const SizedBox(width: 8),
            // Gear icon for settings
            PrintHidden(
              child: Builder(
                builder: (buttonContext) =>
                    IconButton.outlined(
                      icon: const Icon(Icons.settings, semanticLabel: 'Graph settings'),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: context.colorScheme.primary,
                        ),
                      ),
                      onPressed: () => _showGraphSettings(buttonContext),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            // Expand/collapse chevron
            PrintHidden(
              child: GradeExpandButton(
                isExpanded: _graphExpanded,
                onPressed: () {
                  setState(() {
                    _graphExpanded = !_graphExpanded;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
      List<charts.CartesianSeries<GradeTrendPoint, DateTime>> series,
      int groupId,) {
    final courseGroup = _getCourseGroupForId(groupId);

    // Filter to visible series only
    final visibleSeries = series
        .where((s) => _visibleSeries[s.name] ?? true)
        .toList();

    // Calculate dynamic Y-axis range
    final yAxisRange = GradeTrendChart.calculateYAxisRange(
      visibleSeries.where((s) => s.yAxisName == null).toList(),
    );
    final showsTermGpaAxis = visibleSeries.any(
      (s) => s.yAxisName == GradeTrendChart.termGpaAxisName,
    );

    // Calculate X-axis range (date range)
    final xAxisRange = GradeTrendChart.calculateXAxisRange(
      visibleSeries,
      courseGroup,
      autoAdjustToGradedRange: _autoAdjustToGradedRange,
    );

    // Check if today is within the visible date range
    final now = DateTime.now();
    final showTodayMarker =
        now.isAfter(xAxisRange.min) && now.isBefore(xAxisRange.max);
    final isTermView = _graphViewMode.isTerm;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNearestPoint = _usesNearestPoint(constraints);

        return SizedBox(
          height: 400,
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart area
          Expanded(
            child: charts.SfCartesianChart(
              margin: const EdgeInsets.fromLTRB(0, 10, 8, 6),
              tooltipBehavior: charts.TooltipBehavior(
                enable: false,
                header: '',
                canShowMarker: true,
                color: context.colorScheme.surface,
                borderColor: context.colorScheme.outline.withValues(alpha: 0.3),
                borderWidth: 1,
                elevation: 0,
                shadowColor: Colors.transparent,
                builder:
                    (dynamic data,
                    dynamic point,
                    dynamic series,
                    int pointIndex,
                    int seriesIndex,) {
                  final seriesName =
                  (seriesIndex >= 0 &&
                      seriesIndex < visibleSeries.length)
                      ? (visibleSeries[seriesIndex].name ?? '')
                      : '';
                  return GradeTrendTooltip(
                    chartPoint: data as GradeTrendPoint,
                    seriesName: seriesName,
                    isTermView: isTermView,
                    grades: _grades,
                    selectedGroupId: _selectedGroupId,
                    graphViewMode: _graphViewMode,
                  );
                },
              ),
              trackballBehavior: charts.TrackballBehavior(
                enable: true,
                activationMode: charts.ActivationMode.singleTap,
                lineType: charts.TrackballLineType.vertical,
                tooltipDisplayMode: useNearestPoint
                  ? charts.TrackballDisplayMode.nearestPoint
                  : charts.TrackballDisplayMode.floatAllPoints,
                builder: (context, trackballDetails) {
                  return _buildTrackballTooltip(
                    trackballDetails,
                    visibleSeries,
                    isTermView,
                  );
                },
                tooltipSettings: charts.InteractiveTooltip(
                  enable: true,
                  color: context.colorScheme.surface,
                  borderColor: context.colorScheme.outline.withValues(
                    alpha: 0.3,
                  ),
                  borderWidth: 1,
                  textStyle: AppStyles.smallSecondaryText(
                    context,
                  ).copyWith(color: context.colorScheme.onSurface),
                ),
                markerSettings: const charts.TrackballMarkerSettings(
                  markerVisibility: charts.TrackballVisibilityMode.visible,
                  width: 6,
                  height: 6,
                ),
              ),
              primaryXAxis: charts.DateTimeAxis(
                minimum: xAxisRange.min,
                maximum: xAxisRange.max,
                dateFormat: HeliumDateTime.dateFormatForChartAxis,
                intervalType: charts.DateTimeIntervalType.days,
                majorGridLines: charts.MajorGridLines(
                  width: 0.35,
                  color: context.colorScheme.outline.withValues(alpha: 0.22),
                ),
                axisLine: charts.AxisLine(
                  width: 0.5,
                  color: context.colorScheme.outline.withValues(alpha: 0.3),
                ),
                majorTickLines: const charts.MajorTickLines(size: 0),
                plotBands: showTodayMarker
                    ? [
                  charts.PlotBand(
                    isVisible: true,
                    start: now,
                    end: now,
                    borderWidth: 1.5,
                    borderColor: context.colorScheme.error.withValues(
                      alpha: 0.7,
                    ),
                    dashArray: const [6, 4],
                  ),
                ]
                    : const [],
              ),
              primaryYAxis: charts.NumericAxis(
                minimum: yAxisRange.min,
                maximum: yAxisRange.max,
                labelFormat: '{value}%',
                majorGridLines: charts.MajorGridLines(
                  width: 0.35,
                  color: context.colorScheme.outline.withValues(alpha: 0.22),
                ),
                decimalPlaces: 0,
                axisLine: charts.AxisLine(
                  width: 0.5,
                  color: context.colorScheme.outline.withValues(alpha: 0.3),
                ),
                majorTickLines: const charts.MajorTickLines(size: 0),
                plotBands: [
                  charts.PlotBand(
                    isVisible: _atRiskThreshold > yAxisRange.min,
                    start: 0,
                    end: _atRiskThreshold,
                    color: context.semanticColors.warning.withValues(
                      alpha: 0.1,
                    ),
                    text: 'At-Risk Zone',
                    textStyle: AppStyles.smallSecondaryText(context).copyWith(
                      color: context.semanticColors.warning.withValues(
                        alpha: AppStyles.increasedContrastAlpha(0.8),
                      ),
                    ),
                    horizontalTextAlignment: charts.TextAnchor.start,
                  ),
                ],
              ),
              axes: [
                if (showsTermGpaAxis)
                  _buildGpaAxis(
                    _grades.firstWhere((g) => g.id == groupId).gradeScale,
                    isSecondary: true,
                  ),
              ],
              series: visibleSeries,
              plotAreaBorderWidth: 0.5,
              plotAreaBorderColor: context.colorScheme.outline.withValues(
                alpha: 0.2,
              ),
            ),
          ),
          // Legend
          if (!_hideLegend)
            SizedBox(
              width: _legendWidth,
              child: _buildLegend(series),
            ),
        ],
        ),
      );
      },
    );
  }

  double get _legendWidth => Responsive.getResponsiveValue(
    context,
    mobile: 135,
    tablet: 200,
    desktop: 240,
  );

  bool _usesNearestPoint(BoxConstraints constraints) {
    final legendWidth = _hideLegend ? 0.0 : _legendWidth;
    return constraints.maxWidth - legendWidth - 8 < 430;
  }

  Widget _buildGpaAcrossTermsChart() {
    final points = GradeHelper.gpaAcrossTerms(
      _grades,
      priorCredits: userSettings.priorCredits,
      priorGpa: userSettings.priorGpa,
      onlyTermsWithGpa: _autoAdjustToGradedRange,
    );
    final series = GradeTrendChart.buildGpaAcrossTermsSeries(
      context,
      points,
      chartAnimationDurationMs: _chartAnimationDurationMs,
    );
    final visibleSeries = series
        .where((s) => _visibleSeries[s.name] ?? true)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: charts.SfCartesianChart(
                  margin: const EdgeInsets.fromLTRB(0, 10, 8, 6),
                  trackballBehavior: charts.TrackballBehavior(
                    enable: true,
                    activationMode: charts.ActivationMode.singleTap,
                    lineType: charts.TrackballLineType.vertical,
                    tooltipDisplayMode: _usesNearestPoint(constraints)
                        ? charts.TrackballDisplayMode.nearestPoint
                        : charts.TrackballDisplayMode.floatAllPoints,
                    builder: (context, trackballDetails) =>
                        _buildGpaTrackballTooltip(
                          trackballDetails,
                          visibleSeries,
                        ),
                    markerSettings: const charts.TrackballMarkerSettings(
                      markerVisibility: charts.TrackballVisibilityMode.visible,
                      width: 6,
                      height: 6,
                    ),
                  ),
                  primaryXAxis: charts.CategoryAxis(
                    arrangeByIndex: true,
                    labelIntersectAction: charts.AxisLabelIntersectAction.wrap,
                    majorGridLines: charts.MajorGridLines(
                      width: 0.35,
                      color: context.colorScheme.outline.withValues(alpha: 0.22),
                    ),
                    axisLine: charts.AxisLine(
                      width: 0.5,
                      color: context.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    majorTickLines: const charts.MajorTickLines(size: 0),
                  ),
                  primaryYAxis: _buildGpaAxis(
                    _grades.lastWhere((g) => g.inCumulativeGpa).gradeScale,
                  ),
                  series: visibleSeries,
                  plotAreaBorderWidth: 0.5,
                  plotAreaBorderColor: context.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              if (!_hideLegend)
                SizedBox(
                  width: _legendWidth,
                  child: _buildLegend(series),
                ),
            ],
          ),
        );
      },
    );
  }

  charts.NumericAxis _buildGpaAxis(
    List<GradeScaleBandModel> gradeScale, {
    bool isSecondary = false,
  }) {
    final range = GradeTrendChart.gpaAxisRange(gradeScale);
    return charts.NumericAxis(
      name: isSecondary ? GradeTrendChart.termGpaAxisName : null,
      opposedPosition: isSecondary,
      minimum: range.min,
      maximum: range.max,
      isInversed: !GradeHelper.isHigherGradePointBetter(gradeScale),
      labelStyle: isSecondary
          ? TextStyle(color: context.colorScheme.primary)
          : null,
      axisLabelFormatter: _formatGpaAxisLabel,
      majorGridLines: isSecondary
          ? const charts.MajorGridLines(width: 0)
          : charts.MajorGridLines(
              width: 0.35,
              color: context.colorScheme.outline.withValues(alpha: 0.22),
            ),
      axisLine: charts.AxisLine(
        width: 0.5,
        color: context.colorScheme.outline.withValues(alpha: 0.3),
      ),
      majorTickLines: const charts.MajorTickLines(size: 0),
    );
  }

  charts.ChartAxisLabel _formatGpaAxisLabel(
    charts.AxisLabelRenderDetails details,
  ) => charts.ChartAxisLabel(
    HeliumNumber.format(
      details.value.toDouble(),
      fractionDigits: 2,
      trimZeros: true,
    ),
    details.textStyle,
  );

  Widget _buildGpaTrackballTooltip(
    charts.TrackballDetails trackballDetails,
    List<charts.LineSeries<GpaAcrossTermsPoint, String>> visibleSeries,
  ) {
    final point = trackballDetails.point;
    final seriesIndex = trackballDetails.seriesIndex;
    final gpa = point?.y;
    if (point == null ||
        gpa == null ||
        seriesIndex == null ||
        seriesIndex < 0 ||
        seriesIndex >= visibleSeries.length) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${visibleSeries[seriesIndex].name} • '
            '${GradeHelper.gradePointForDisplay(gpa.toDouble())}',
            style: AppStyles.standardBodyTextEmphasis(context),
          ),
          const SizedBox(height: 4),
          Text('${point.x}', style: AppStyles.smallSecondaryText(context)),
        ],
      ),
    );
  }

  Widget _buildTrackballTooltip(charts.TrackballDetails trackballDetails,
      List<charts.CartesianSeries<GradeTrendPoint, DateTime>> visibleSeries,
      bool isTermView,) {
    final pointIndex = trackballDetails.pointIndex;
    final seriesIndex = trackballDetails.seriesIndex;
    if (pointIndex == null || seriesIndex == null) {
      return const SizedBox.shrink();
    }
    if (seriesIndex < 0 || seriesIndex >= visibleSeries.length) {
      return const SizedBox.shrink();
    }

    final series = visibleSeries[seriesIndex];
    final dataSource = series.dataSource;
    if (dataSource == null ||
        pointIndex < 0 ||
        pointIndex >= dataSource.length) {
      return const SizedBox.shrink();
    }

    return GradeTrendTooltip(
      chartPoint: dataSource[pointIndex],
      seriesName: series.name ?? '',
      isTermView: isTermView,
      grades: _grades,
      selectedGroupId: _selectedGroupId,
      graphViewMode: _graphViewMode,
    );
  }

  Widget _buildLegend(List<charts.CartesianSeries<dynamic, dynamic>> series) {
    return ListView(
      padding: EdgeInsets.zero,
      children: series.map((s) {
        final isVisible = _visibleSeries[s.name] ?? true;
        return Material(
          color: Colors.transparent,
          child: HeliumCheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            horizontalTitleGap: Responsive.isMobile(context) ? 8.0 : null,
            controlAffinity: ListTileControlAffinity.leading,
            value: isVisible,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  alignment: Alignment.center,
                  child: Icon(
                    GradeTrendChart.seriesIconForName(
                      s.name,
                      grades: _grades,
                      selectedGroupId: _selectedGroupId,
                      graphViewMode: _graphViewMode,
                    ),
                    size: 16,
                    color: s.color,
                  ),
                ),
                SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
                Expanded(
                  child: Text(
                    s.name ?? '',
                    style: AppStyles.smallSecondaryText(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onChanged: (value) {
              setState(() {
                _visibleSeries[s.name ?? ''] = value ?? true;
              });
              _saveGraphSettingsIfEnabled();
            },
          ),
        );
      }).toList(),
    );
  }

  CourseGroupModel _getCourseGroupForId(int groupId) {
    return _courseGroups.firstWhere((g) => g.id == groupId);
  }

  void _showGraphSettings(BuildContext buttonContext) {
    final selectedGroup = _grades.firstWhere(
          (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    Widget buildContent(BuildContext menuContext, StateSetter setMenuState) {
      return HeliumMenuContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _graphViewMode.radioValue,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _graphViewMode =
                    GradeTrendViewMode.fromRadioValue(value));
                _saveGraphSettingsIfEnabled();
                Navigator.pop(menuContext);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_offersGpaAcrossTerms)
                    RadioListTile<String>(
                      title: Text(
                        'GPA Across Terms',
                        style: AppStyles.formText(context),
                      ),
                      value:
                          const GradeTrendViewMode.gpaAcrossTerms().radioValue,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 4),
                    ),
                  RadioListTile<String>(
                    title: Text(
                      'Entire Term',
                      style: AppStyles.formText(context),
                    ),
                    value: const GradeTrendViewMode.term().radioValue,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 4),
                  ),
                  const Divider(height: 20),
                  ...selectedGroup.courses.map(
                    (course) => RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.school, size: 16,
                              color: course.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course.title,
                              style: AppStyles.formText(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      value:
                          GradeTrendViewMode.course(course.id).radioValue,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 4),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            HeliumCheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Auto-adjust to graded range',
                style: AppStyles.formText(context),
              ),
              value: _autoAdjustToGradedRange == true,
              onChanged: (value) {
                _setAutoAdjustToGradedRange(value ?? false);
                setMenuState(() {});
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            HeliumCheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Hide legend',
                style: AppStyles.formText(context),
              ),
              value: _hideLegend == true,
              onChanged: (value) {
                _setHideLegend(value ?? false);
                setMenuState(() {});
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 16),
            ListTile(
              leading: SizedBox.square(
                dimension: 40,
                child: Icon(
                  Icons.tune,
                  color: context.colorScheme.onSurface.withValues(
                    alpha: AppStyles.mutedIconAlpha,
                  ),
                ),
              ),
              title: Text(
                'Grade preferences',
                style: AppStyles.formText(context),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: context.colorScheme.onSurface.withValues(
                  alpha: AppStyles.mutedIconAlpha,
                ),
              ),
              onTap: () {
                Navigator.pop(menuContext);
                context.push(
                  '${BranchPathScope.of(context)}${AppRoute.settingScreen}/preferences'
                  '?${DeepLinkParam.section}=grades',
                );
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      );
    }

    showHeliumMenu(
      context: context,
      anchorContext: buttonContext,
      builder: buildContent,
    );
  }

  void _toggleExpandedCourse(int courseId) {
    setState(() {
      if (_expandedCourseIds.contains(courseId)) {
        _expandedCourseIds.remove(courseId);
      } else {
        _expandedCourseIds.add(courseId);
      }
    });
  }

  void _setAutoAdjustToGradedRange(bool value) {
    setState(() {
      _autoAdjustToGradedRange = value;
    });
    _saveGraphSettingsIfEnabled();
  }

  void _setHideLegend(bool value) {
    setState(() {
      _hideLegend = value;
    });
    _saveGraphSettingsIfEnabled();
  }

  void _saveGraphSettingsIfEnabled() {
    if (!settingsLoaded || !userSettings.rememberFilterState) return;

    final graphSettings = {
      'autoAdjustToGradedRange': _autoAdjustToGradedRange,
      'hideLegend': _hideLegend,
      'viewMode': _graphViewMode.radioValue,
      'visibleSeries': _visibleSeries,
    };
    PrefService().setString(
      _savedGradeGraphSettingsKey,
      jsonEncode(graphSettings),
    );
  }

  void _restoreGraphSettingsIfEnabled(UserSettingsModel settings) {
    if (!settings.rememberFilterState) return;

    final savedState = PrefService().getString(_savedGradeGraphSettingsKey);
    if (savedState == null || savedState.isEmpty) return;

    try {
      final graphSettings = jsonDecode(savedState) as Map<String, dynamic>;
      final savedAutoAdjust = graphSettings['autoAdjustToGradedRange'] as bool?;
      final savedHideLegend = graphSettings['hideLegend'] as bool?;
      final savedViewMode = graphSettings['viewMode'] as String?;
      final savedVisibleSeries =
          (graphSettings['visibleSeries'] as Map<String, dynamic>?)
              ?.cast<String, bool>();

      setState(() {
        if (savedAutoAdjust != null) {
          _autoAdjustToGradedRange = savedAutoAdjust;
        }
        if (savedHideLegend != null) {
          _hideLegend = savedHideLegend;
        }
        if (savedViewMode != null) {
          _graphViewMode = GradeTrendViewMode.fromRadioValue(savedViewMode);
          if (_grades.isNotEmpty) _showEntireTermIfGraphViewUnavailable();
        }
        if (savedVisibleSeries != null) {
          _visibleSeries.addAll(savedVisibleSeries);
        }
      });
    } catch (_) {
      // Ignore malformed settings and keep defaults.
    }
  }

  void _saveSelectedGroup() {
    if (_selectedGroupId == null || !settingsLoaded) return;

    ScreenDropdownFilterHelpers.save(
      ScreensDropdownFilterPrefKey.courseGroupId,
      _selectedGroupId!,
      userSettings,
    );
  }

  int? _selectableGroupId(int? candidate) =>
      _courseGroups.any((g) => g.id == candidate)
          ? candidate
          : CourseGroupHelpers.currentGroupId(_courseGroups);

  void _restoreSelectedGroup(UserSettingsModel settings) {
    final savedGroupId = ScreenDropdownFilterHelpers.restore(
      ScreensDropdownFilterPrefKey.courseGroupId,
      settings,
    );
    if (savedGroupId == null) return;

    setState(() {
      _selectedGroupId = _courseGroups.isEmpty
          ? savedGroupId
          : _selectableGroupId(savedGroupId);
    });
  }

}
