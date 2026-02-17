// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

// TODO: make the thresholds for at-risk classes (and eventually progress/pace ratio) configurable by the user
// TODO: in "Pending Impact", make the "x in y" badge clickable, and open it up to a menu where the user can switch which course is shown
// TODO: in "Pending Impact", based on the currently selected class, show the user which ungraded item is most impactful
// TODO: if/when a user makes a change to a grade in the open dialog (or deletes the item), grades will be recalculated, and we need to show this updated state

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/grade_repository_impl.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/grade_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/bloc/grade/grade_bloc.dart';
import 'package:heliumapp/presentation/bloc/grade/grade_event.dart';
import 'package:heliumapp/presentation/bloc/grade/grade_state.dart';
import 'package:heliumapp/presentation/dialogs/grade_calculator_dialog.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_screen.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/at_risk_badge.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/grade_label.dart';
import 'package:heliumapp/presentation/widgets/group_dropdown.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:syncfusion_flutter_gauges/gauges.dart';

class ChartDataPoint {
  final DateTime date;
  final double grade;
  final int? homeworkId;
  final String? homeworkTitle;
  final dynamic homeworkGrade;
  final int? categoryId;

  ChartDataPoint({
    required this.date,
    required this.grade,
    this.homeworkId,
    this.homeworkTitle,
    this.homeworkGrade,
    this.categoryId,
  });
}

class ChartSegment {
  final String label;
  final double value;
  final Color color;

  ChartSegment({required this.label, required this.value, required this.color});
}

class GradesScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final ProviderHelpers _providerHelpers = ProviderHelpers();

  GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: _providerHelpers.createCalendarItemBloc()),
        BlocProvider(create: _providerHelpers.createAttachmentBloc()),
        BlocProvider(
          create: (context) => GradeBloc(
            gradeRepository: GradeRepositoryImpl(
              remoteDataSource: GradeRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
      ],
      child: const GradesProvidedScreen(),
    );
  }
}

class GradesProvidedScreen extends StatefulWidget {
  const GradesProvidedScreen({super.key});

  @override
  State<GradesProvidedScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends BasePageScreenState<GradesProvidedScreen> {
  static const _savedGradeGraphSettingsKey = 'saved_grades_graph_settings';

  @override
  String get screenTitle => 'Grades';

  // Decision variables - adjust these to tune the grade insights
  static const double _atRiskThreshold =
      70.0; // Courses below this % are flagged as at-risk
  static const double _onTrackTolerance =
      10.0; // tolerance for "on track" status (work vs time)
  static const double _defaultDesiredGradeBoost =
      5.0; // Default boost above current grade for calculator
  static const double _chartAnimationDurationMs = 250;

  // State
  List<CourseGroupModel> _courseGroups = [];
  List<GradeCourseGroupModel> _grades = [];
  int? _selectedGroupId;
  final Set<int> _expandedCourseIds = {};
  final Map<int, GlobalKey> _courseCardKeys = {};

  // Graph state
  String _graphViewMode = 'term'; // 'term' or course ID
  final Map<String, bool> _visibleSeries = {}; // series ID -> visibility
  bool _autoAdjustToGradedRange =
      false; // Fit X-axis to actual grade point dates
  bool _graphExpanded = true; // Whether the graph area is expanded

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (!mounted || settings == null) return settings;
      _restoreGraphSettingsIfEnabled(settings);
      return settings;
    });
  }

  @override
  void initState() {
    super.initState();

    context.read<GradeBloc>().add(FetchGradeScreenDataEvent());
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<GradeBloc, GradeState>(
        listener: (context, state) {
          if (state is GradesError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is GradeScreenDataFetched) {
            _populateInitiateStateData(state);
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
            _expandedCourseIds.clear();
          });
        },
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<GradeBloc, GradeState>(
      builder: (context, state) {
        if (state is GradesLoading) {
          return const LoadingIndicator();
        }

        if (state is GradesError) {
          return ErrorCard(
            message: state.message!,
            onReload: () {
              return context.read<GradeBloc>().add(FetchGradeScreenDataEvent());
            },
          );
        }

        final List<GradeCourseModel> courses = _grades.isNotEmpty
            ? _grades.firstWhere((g) => g.id == _selectedGroupId).courses
            : [];

        if (_grades.isEmpty || courses.isEmpty) {
          return const EmptyCard(
            icon: Icons.bar_chart,
            title: "You haven't added any classes yet",
            message: "Head over to 'Classes' to get started",
          );
        }

        return _buildGradesPage(courses);
      },
    );
  }

  void _populateInitiateStateData(GradeScreenDataFetched state) {
    setState(() {
      _courseGroups = state.courseGroups;
      _grades = state.grades;
      if (_courseGroups.isNotEmpty) {
        _selectedGroupId = _courseGroups.first.id;
      }

      isLoading = false;
    });
  }

  Widget _buildGradesPage(List<GradeCourseModel> courses) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermSummaryArea(),

            _buildGraphArea(),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildCourseCard(index, course);
              },
            ),
          ],
        ),
      ),
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

    final cards = [
      _buildOverallGradeCard(selectedGroup),
      _buildProgressVsPaceCard(selectedGroup),
      _buildAtRiskCoursesCard(selectedGroup),
      _buildPendingImpactCard(selectedGroup),
    ];

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

  double get _summaryCardHeight => Responsive.getResponsiveValue(
    context,
    mobile: 200,
    tablet: 190,
    desktop: 260,
  );

  double get _summaryCardPadding => Responsive.getResponsiveValue(
    context,
    mobile: 12,
    tablet: 12,
    desktop: 16,
  );

  double get _summaryCircleSize => Responsive.getResponsiveValue(
    context,
    mobile: 60,
    tablet: 50,
    desktop: 80,
  );

  double get _summaryGaugeHeight => Responsive.getResponsiveValue(
    context,
    mobile: 100,
    tablet: 110,
    desktop: 140,
  );

  Widget _buildSummaryCard({required Widget child}) {
    return Card(
      elevation: 2,
      child: SizedBox(
        height: _summaryCardHeight,
        child: Padding(
          padding: EdgeInsets.all(_summaryCardPadding),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSummaryTitle(String title) {
    return Text(
      title,
      style: AppStyles.standardBodyText(
        context,
      ).copyWith(fontWeight: FontWeight.w600),
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

    // Calculate trend from grade points if available
    double? trend;
    if (selectedGroup.gradePoints.length >= 2) {
      final recent =
          GradeHelper.parseGrade(selectedGroup.gradePoints.last[1]) ?? 0.0;
      final previous =
          GradeHelper.parseGrade(
            selectedGroup.gradePoints[selectedGroup.gradePoints.length - 2][1],
          ) ??
          0.0;
      trend = recent - previous;
    }

    return _buildSummaryCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSummaryTitle('Overall Grade'),
          const SizedBox(height: 12),
          SizedBox(
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
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
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
                            const SizedBox(height: 4),
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
                                  : context.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ],
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.7,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

    // Determine status: on track, ahead, or behind
    final difference = completionPercent - timePercent;
    final String status;
    final int statusUrgency;
    if (difference > _onTrackTolerance) {
      status = 'Ahead';
      statusUrgency = 1;
    } else if (difference >= -_onTrackTolerance) {
      status = 'On Track';
      statusUrgency = 1;
    } else {
      status = 'Behind';
      final expectedWorkAtRiskCutoff =
          timePercent * (_atRiskThreshold / 100); // e.g., 70% of expected pace
      statusUrgency = completionPercent < expectedWorkAtRiskCutoff ? 3 : 2;
    }
    final statusColor = HeliumColors.urgencyColor(context, statusUrgency);

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
                width: 60,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: completionPercent / 100,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
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
                              ? Colors.white
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
                width: 60,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: timePercent / 100,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.colorScheme.outline,
                          borderRadius: BorderRadius.circular(12),
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
                              ? Colors.white
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'Ahead'
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
                    style: AppStyles.standardBodyText(
                      context,
                    ).copyWith(color: statusColor, fontWeight: FontWeight.w600),
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
        .where((course) => course.overallGrade < _atRiskThreshold)
        .toList();
    final count = atRiskCourses.length;

    return MouseRegion(
      cursor: count > 0 ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: count > 0
            ? () {
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
                    duration: const Duration(milliseconds: 300),
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
                  color: count > 0
                      ? context.colorScheme.error.withValues(alpha: 0.15)
                      : context.semanticColors.success.withValues(alpha: 0.15),
                  border: Border.all(
                    color: count > 0
                        ? context.colorScheme.error
                        : context.semanticColors.success,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: AppStyles.headingText(context).copyWith(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 32,
                        tablet: 26,
                        desktop: 40,
                      ),
                      color: count > 0
                          ? context.colorScheme.error
                          : context.semanticColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                count == 0
                    ? 'All classes passing!'
                    : 'below ${_atRiskThreshold.toInt()}%',
                style: AppStyles.smallSecondaryText(context).copyWith(
                  color: count > 0
                      ? context.colorScheme.error
                      : context.semanticColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              if (count > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap to view',
                  style: AppStyles.smallSecondaryText(
                    context,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingImpactCard(GradeCourseGroupModel selectedGroup) {
    final ungradedCount = selectedGroup.numHomeworkGraded > 0
        ? selectedGroup.numHomework - selectedGroup.numHomeworkGraded
        : selectedGroup.numHomework;

    // Find course with most ungraded work
    GradeCourseModel? topCourse;
    int maxUngraded = 0;
    for (var course in selectedGroup.courses) {
      final courseUngraded = course.numHomework - course.numHomeworkGraded;
      if (courseUngraded > maxUngraded) {
        maxUngraded = courseUngraded;
        topCourse = course;
      }
    }

    return _buildSummaryCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSummaryTitle('Pending Impact'),
          const SizedBox(height: 12),
          Container(
            width: _summaryCircleSize,
            height: _summaryCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ungradedCount > 0
                  ? context.semanticColors.warning.withValues(alpha: 0.15)
                  : context.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: ungradedCount > 0
                    ? context.semanticColors.warning
                    : context.colorScheme.outline,
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
                          : context.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ungraded ${ungradedCount.plural('assignment')}',
            style: AppStyles.smallSecondaryText(context).copyWith(
              color: ungradedCount > 0
                  ? context.semanticColors.warning
                  : context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (topCourse != null && maxUngraded > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: topCourse.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: topCourse.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$maxUngraded in ${topCourse.title}',
                      style: AppStyles.smallSecondaryText(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGradeCalculatorOptions(
    GradeCourseGroupModel selectedGroup,
    List<GradeCourseModel> courses,
  ) {
    final eligibleCourses = courses
        .where(_courseHasEligibleGradeCalculatorCategory)
        .toList();

    if (eligibleCourses.isEmpty) {
      showSnackBar(
        context,
        'No classes have exactly one remaining graded item.',
      );
      return;
    }

    if (eligibleCourses.length == 1) {
      _openGradeCalculator(eligibleCourses.first);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        content: SizedBox(
          width: Responsive.getDialogWidth(context),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: eligibleCourses.length,
            itemBuilder: (context, index) {
              final course = eligibleCourses[index];
              return ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: Responsive.getIconSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: course.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course.title,
                        style: AppStyles.formText(
                          context,
                        ).copyWith(color: context.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GradeLabel(
                    grade: GradeHelper.gradeForDisplay(course.overallGrade),
                    userSettings: userSettings!,
                    compact: true,
                    selectable: false,
                  ),
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _openGradeCalculator(course);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  bool _courseHasEligibleGradeCalculatorCategory(GradeCourseModel course) {
    return course.categories.any((category) {
      final remainingItems = category.numHomework - category.numHomeworkGraded;
      return category.weight > 0 && remainingItems == 1;
    });
  }

  void _openGradeCalculator(GradeCourseModel course) {
    showDialog(
      context: context,
      builder: (context) => GradeCalculatorDialog(
        categories: course.categories,
        currentOverallGrade: course.overallGrade,
        courseTitle: course.title,
        courseColor: course.color,
        userSettings: userSettings!,
        defaultDesiredGradeBoost: _defaultDesiredGradeBoost,
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
    final isTermView = _graphViewMode == 'term';
    final List<charts.CartesianSeries<ChartDataPoint, DateTime>> series = [];

    if (isTermView) {
      // Show overall grade + all courses
      if (selectedGroup.gradePoints.isNotEmpty) {
        series.add(_buildOverallSeries(selectedGroup));
      }
      for (var course in selectedGroup.courses) {
        if (course.gradePoints.isNotEmpty) {
          series.add(_buildCourseSeries(course));
        }
      }
    } else {
      // Show specific course with its categories
      final course = selectedGroup.courses.firstWhereOrNull(
        (c) => c.id.toString() == _graphViewMode,
      );
      if (course != null) {
        if (course.gradePoints.isNotEmpty) {
          series.add(_buildCourseOverallSeries(course));
        }
        // Add category grade trends
        for (var category in course.categories) {
          if (category.gradePoints.isNotEmpty) {
            series.add(_buildCategorySeries(category));
          }
        }
      }
    }

    // If no data to display, show empty state
    if (series.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No grade data available for visualization',
            style: AppStyles.standardBodyText(context),
          ),
        ),
      );
    }

    // Full width container like other cards
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphHeader(selectedGroup, isTermView),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _graphExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildChart(series, selectedGroup.id),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphHeader(GradeCourseGroupModel gradeGroup, bool isTermView) {
    // Get all courses with categories
    final coursesWithCategories = gradeGroup.courses
        .where((course) => course.categories.isNotEmpty)
        .toList();
    final course = _getSelectedCourse();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleGraphExpanded,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title
            Expanded(
              child: Row(
                children: [
                  Text('Grade Trend', style: AppStyles.headingText(context)),
                  if (course != null) ...[
                    const SizedBox(width: 6),
                    CourseTitleLabel(title: course.title, color: course.color),
                  ],
                ],
              ),
            ),
            // Calculator icon for grade calculator
            if (coursesWithCategories.isNotEmpty)
              Tooltip(
                message: 'What Grade Do I Need?',
                child: IconButton(
                  icon: const Icon(Icons.calculate_outlined),
                  onPressed: () => _showGradeCalculatorOptions(
                    gradeGroup,
                    coursesWithCategories,
                  ),
                ),
              ),
            // Gear icon for settings
            Builder(
              builder: (buttonContext) => IconButton(
                tooltip: 'Graph settings',
                icon: const Icon(Icons.settings),
                onPressed: () => _showGraphSettings(buttonContext),
              ),
            ),
            // Expand/collapse chevron
            IconButton(
              icon: AnimatedRotation(
                turns: _graphExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_arrow_down),
              ),
              onPressed: _toggleGraphExpanded,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleGraphExpanded() {
    setState(() {
      _graphExpanded = !_graphExpanded;
    });
  }

  Widget _buildChart(
    List<charts.CartesianSeries<ChartDataPoint, DateTime>> series,
    int groupId,
  ) {
    final courseGroup = _getCourseGroupForId(groupId);
    final isTouchDevice = Responsive.isTouchDevice(context);

    // Filter to visible series only
    final visibleSeries = series
        .where((s) => _visibleSeries[s.name] ?? true)
        .toList();

    // Calculate dynamic Y-axis range
    final yAxisRange = _calculateYAxisRange(visibleSeries);

    // Calculate X-axis range (date range)
    final xAxisRange = _calculateXAxisRange(visibleSeries, courseGroup);

    // Check if today is within the visible date range
    final now = DateTime.now();
    final showTodayMarker =
        now.isAfter(xAxisRange['min']!) && now.isBefore(xAxisRange['max']!);
    final isTermView = _graphViewMode == 'term';

    return SizedBox(
      height: 400,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart area
          Expanded(
            child: charts.SfCartesianChart(
              tooltipBehavior: charts.TooltipBehavior(
                enable: !isTouchDevice,
                header: '',
                canShowMarker: true,
                builder:
                    (
                      dynamic data,
                      dynamic point,
                      dynamic series,
                      int pointIndex,
                      int seriesIndex,
                    ) {
                      final chartPoint = data as ChartDataPoint;
                      final homeworkTitle =
                          chartPoint.homeworkTitle?.trim().isNotEmpty == true
                          ? chartPoint.homeworkTitle!
                          : 'No assignment title';
                      final homeworkGradeText = GradeHelper.gradeForDisplay(
                        chartPoint.homeworkGrade,
                      );
                      final categoryTitle = _categoryTitleForId(
                        chartPoint.categoryId,
                      );
                      final categoryColor = _categoryColorForId(
                        chartPoint.categoryId,
                      );
                      final seriesName =
                          (seriesIndex >= 0 &&
                              seriesIndex < visibleSeries.length)
                          ? (visibleSeries[seriesIndex].name ?? '')
                          : '';
                      final isOverallSeries = seriesName == 'Overall Grade';
                      final gradeLabel = isOverallSeries
                          ? 'Overall Grade'
                          : isTermView
                          ? 'Class Grade'
                          : 'Category Grade';
                      final classGradeAtPoint =
                          '${chartPoint.grade.toStringAsFixed(2)}%';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.colorScheme.outline.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$homeworkTitle ($homeworkGradeText)',
                              style: AppStyles.standardBodyText(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isTermView && categoryTitle != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 13,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      categoryTitle,
                                      style: AppStyles.smallSecondaryText(
                                        context,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '$gradeLabel: $classGradeAtPoint',
                              style: AppStyles.smallSecondaryText(context),
                            ),
                          ],
                        ),
                      );
                    },
              ),
              trackballBehavior: charts.TrackballBehavior(
                enable: isTouchDevice,
                activationMode: charts.ActivationMode.singleTap,
                lineType: charts.TrackballLineType.vertical,
                tooltipDisplayMode: charts.TrackballDisplayMode.floatAllPoints,
                tooltipSettings: charts.InteractiveTooltip(
                  enable: true,
                  color: context.colorScheme.surface,
                  borderColor: context.colorScheme.outline.withValues(
                    alpha: 0.3,
                  ),
                  borderWidth: 1,
                ),
                markerSettings: const charts.TrackballMarkerSettings(
                  markerVisibility: charts.TrackballVisibilityMode.visible,
                  width: 6,
                  height: 6,
                ),
              ),
              primaryXAxis: charts.DateTimeAxis(
                minimum: xAxisRange['min'],
                maximum: xAxisRange['max'],
                dateFormat: DateFormat('MMM dd'),
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
                minimum: yAxisRange['min'],
                maximum: yAxisRange['max'],
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
                    isVisible: true,
                    start: 0,
                    end: _atRiskThreshold,
                    color: context.semanticColors.warning.withValues(
                      alpha: 0.1,
                    ),
                    text: 'At-Risk Zone',
                    textStyle: AppStyles.smallSecondaryText(context).copyWith(
                      color: context.semanticColors.warning.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    horizontalTextAlignment: charts.TextAnchor.start,
                  ),
                ],
              ),
              series: visibleSeries,
              plotAreaBorderWidth: 0.5,
              plotAreaBorderColor: context.colorScheme.outline.withValues(
                alpha: 0.2,
              ),
            ),
          ),
          // Legend
          SizedBox(
            width: Responsive.getResponsiveValue(
              context,
              mobile: 160,
              tablet: 200,
              desktop: 240,
            ),
            child: _buildLegend(series),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    List<charts.CartesianSeries<ChartDataPoint, DateTime>> series,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: series.map((s) {
        final isVisible = _visibleSeries[s.name] ?? true;
        return Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            controlAffinity: ListTileControlAffinity.leading,
            value: isVisible,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  alignment: Alignment.center,
                  child: Icon(
                    _seriesIconForName(s.name),
                    size: 16,
                    color: s.color,
                  ),
                ),
                const SizedBox(width: 8),
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
            },
          ),
        );
      }).toList(),
    );
  }

  charts.SplineSeries<ChartDataPoint, DateTime> _buildOverallSeries(
    GradeCourseGroupModel group,
  ) {
    final dataSource = _parseGradePoints(group.gradePoints);
    return charts.SplineSeries<ChartDataPoint, DateTime>(
      name: 'Overall Grade',
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      color: context.colorScheme.onSurface,
      width: 3,
      opacity: 1,
      splineType: charts.SplineType.monotonic,
      animationDuration: _chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  charts.SplineSeries<ChartDataPoint, DateTime> _buildCourseSeries(
    GradeCourseModel course,
  ) {
    final dataSource = _parseGradePoints(course.gradePoints);
    return charts.SplineSeries<ChartDataPoint, DateTime>(
      name: course.title,
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      color: course.color,
      width: 1.75,
      opacity: 0.88,
      splineType: charts.SplineType.monotonic,
      animationDuration: _chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  charts.SplineSeries<ChartDataPoint, DateTime> _buildCourseOverallSeries(
    GradeCourseModel course,
  ) {
    final dataSource = _parseGradePoints(course.gradePoints);
    return charts.SplineSeries<ChartDataPoint, DateTime>(
      name: 'Overall Grade',
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      color: context.colorScheme.onSurface,
      width: 3,
      opacity: 1,
      splineType: charts.SplineType.monotonic,
      animationDuration: _chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  charts.SplineSeries<ChartDataPoint, DateTime> _buildCategorySeries(
    GradeCategoryModel category,
  ) {
    final dataSource = _parseGradePoints(category.gradePoints);
    return charts.SplineSeries<ChartDataPoint, DateTime>(
      name: category.title,
      dataSource: dataSource,
      xValueMapper: (point, _) => point.date,
      yValueMapper: (point, _) => point.grade,
      color: category.color,
      width: 1.75,
      opacity: 0.9,
      splineType: charts.SplineType.monotonic,
      animationDuration: _chartAnimationDurationMs,
      enableTooltip: true,
      onPointTap: (pointDetails) =>
          _handlePointTap(context, dataSource, pointDetails),
      markerSettings: const charts.MarkerSettings(
        isVisible: true,
        height: 4,
        width: 4,
      ),
    );
  }

  List<ChartDataPoint> _parseGradePoints(List<List<dynamic>> gradePoints) {
    return gradePoints.map((point) {
      // point format: [date, grade_value, homework_id, homework_title, ...]
      // date can be either a timestamp (int) or ISO string
      DateTime date;
      if (point[0] is int) {
        date = DateTime.fromMillisecondsSinceEpoch(point[0] as int);
      } else if (point[0] is String) {
        date = DateTime.parse(point[0] as String);
      } else {
        date = DateTime.now(); // Fallback
      }

      final grade = GradeHelper.parseGrade(point[1]) ?? 0.0;
      final homeworkId = point.length > 2 ? point[2] as int? : null;
      final homeworkTitle = point.length > 3 ? point[3] as String? : null;
      final homeworkGrade = point.length > 4 ? point[4] : null;
      final categoryId = point.length > 5 ? point[5] as int? : null;

      return ChartDataPoint(
        date: date,
        grade: grade,
        homeworkId: homeworkId,
        homeworkTitle: homeworkTitle,
        homeworkGrade: homeworkGrade,
        categoryId: categoryId,
      );
    }).toList();
  }

  String? _categoryTitleForId(int? categoryId) {
    if (categoryId == null || _selectedGroupId == null || _grades.isEmpty) {
      return null;
    }

    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    for (final course in selectedGroup.courses) {
      for (final category in course.categories) {
        if (category.id == categoryId) {
          return category.title;
        }
      }
    }

    return null;
  }

  Color _categoryColorForId(int? categoryId) {
    if (categoryId == null || _selectedGroupId == null || _grades.isEmpty) {
      return context.colorScheme.onSurface.withValues(alpha: 0.6);
    }

    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    for (final course in selectedGroup.courses) {
      for (final category in course.categories) {
        if (category.id == categoryId) {
          return category.color;
        }
      }
    }

    return context.colorScheme.onSurface.withValues(alpha: 0.6);
  }

  void _handlePointTap(
    BuildContext context,
    List<ChartDataPoint> dataSource,
    charts.ChartPointDetails pointDetails,
  ) {
    final pointIndex = pointDetails.pointIndex;

    if (pointIndex == null || pointIndex >= dataSource.length) return;

    // Get the actual ChartDataPoint from the data source
    final chartDataPoint = dataSource[pointIndex];
    final homeworkId = chartDataPoint.homeworkId;

    if (homeworkId == null) {
      return; // No homework associated with this grade point
    }

    // Open the calendar item (assignment)
    final calendarItemBloc = context.read<CalendarItemBloc>();
    final attachmentBloc = context.read<AttachmentBloc>();

    showCalendarItemAdd(
      context,
      homeworkId: homeworkId,
      isEdit: true,
      isNew: false,
      calendarItemBloc: calendarItemBloc,
      attachmentBloc: attachmentBloc,
    );
  }

  Map<String, double> _calculateYAxisRange(
    List<charts.CartesianSeries<ChartDataPoint, DateTime>> visibleSeries,
  ) {
    if (visibleSeries.isEmpty) {
      return {'min': 0.0, 'max': 100.0};
    }

    // Find the lowest and highest grade points across all visible series
    double lowestPoint = 100;
    double highestPoint = 0;

    for (final series in visibleSeries) {
      final dataSource = series.dataSource;
      if (dataSource != null) {
        for (final point in dataSource) {
          if (point.grade < lowestPoint) lowestPoint = point.grade;
          if (point.grade > highestPoint) highestPoint = point.grade;
        }
      }
    }

    // Apply formula: lowest_point - (100 - highest_point)
    final double calculatedMin = lowestPoint - (100 - highestPoint);

    // Ensure minimum doesn't go below 0 and add some padding
    double minimum = (calculatedMin - 5).clamp(0.0, 95.0).toDouble();

    // Round to nearest whole number for cleaner axis labels
    minimum = minimum.floorToDouble();

    // Maximum always stays at 100
    return {'min': minimum, 'max': 100.0};
  }

  Map<String, DateTime> _calculateXAxisRange(
    List<charts.CartesianSeries<ChartDataPoint, DateTime>> visibleSeries,
    CourseGroupModel courseGroup,
  ) {
    // If auto-adjust is disabled, use the full course group date range
    if (!_autoAdjustToGradedRange || visibleSeries.isEmpty) {
      return {'min': courseGroup.startDate, 'max': courseGroup.endDate};
    }

    // Find the earliest and latest dates across all visible series
    DateTime? earliestDate;
    DateTime? latestDate;

    for (final series in visibleSeries) {
      final dataSource = series.dataSource;
      if (dataSource != null) {
        for (final point in dataSource) {
          if (earliestDate == null || point.date.isBefore(earliestDate)) {
            earliestDate = point.date;
          }
          if (latestDate == null || point.date.isAfter(latestDate)) {
            latestDate = point.date;
          }
        }
      }
    }

    // If we found dates, use them; otherwise fall back to course group dates
    if (earliestDate != null && latestDate != null) {
      return {'min': earliestDate, 'max': latestDate};
    }

    return {'min': courseGroup.startDate, 'max': courseGroup.endDate};
  }

  CourseGroupModel _getCourseGroupForId(int groupId) {
    return _courseGroups.firstWhere((g) => g.id == groupId);
  }

  GradeCourseModel? _getSelectedCourse() {
    if (_graphViewMode == 'term' || _selectedGroupId == null) return null;

    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    return selectedGroup.courses.firstWhereOrNull(
      (c) => c.id.toString() == _graphViewMode,
    );
  }

  IconData _seriesIconForName(String? name) {
    if (name == null || name.isEmpty) return Icons.circle;

    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    final isCourse = selectedGroup.courses.any(
      (course) => course.title == name,
    );
    if (isCourse) return Icons.school;

    final selectedCourse = _getSelectedCourse();
    final isCategory =
        selectedCourse?.categories.any((category) => category.title == name) ??
        false;
    if (isCategory) return Icons.category_outlined;

    return Icons.circle;
  }

  void _showGraphSettings(BuildContext buttonContext) {
    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (menuContext, setMenuState) {
              return Material(
                color: context.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Radio group for graph view mode
                      RadioGroup<String>(
                        groupValue: _graphViewMode,
                        onChanged: (value) {
                          setState(() => _graphViewMode = value!);
                          Navigator.pop(menuContext);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Entire Term option
                            InkWell(
                              onTap: () {
                                setState(() => _graphViewMode = 'term');
                                Navigator.pop(menuContext);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Radio<String>(value: 'term'),
                                    Expanded(
                                      child: Text(
                                        'Entire Term',
                                        style: AppStyles.formText(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 20),
                            // Individual courses
                            ...selectedGroup.courses.map(
                              (course) => InkWell(
                                onTap: () {
                                  setState(
                                    () => _graphViewMode = course.id.toString(),
                                  );
                                  Navigator.pop(menuContext);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: course.id.toString(),
                                      ),
                                      Icon(
                                        Icons.school,
                                        size: 16,
                                        color: course.color,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          course.title,
                                          style: AppStyles.formText(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 20),
                      CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Auto-adjust to graded range',
                          style: AppStyles.formText(context),
                        ),
                        value: _autoAdjustToGradedRange,
                        onChanged: (value) {
                          _setAutoAdjustToGradedRange(value ?? false);
                          setMenuState(() {});
                        },
                        dense: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(int index, GradeCourseModel course) {
    final isExpanded = _expandedCourseIds.contains(course.id);

    return Card(
      key: _courseCardKeys.putIfAbsent(course.id, () => GlobalKey()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCourseSummaryArea(index, isExpanded, course),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded && course.categories.isNotEmpty
                  ? _buildCourseArea(course)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSummaryArea(
    int index,
    bool isExpanded,
    GradeCourseModel course,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleExpandedCourse(course.id),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: course.color.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.school_outlined,
                color: course.color,
                size: Responsive.getIconSize(
                  context,
                  mobile: 24,
                  tablet: 26,
                  desktop: 28,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CourseTitleLabel(
                        title: course.title,
                        color: course.color,
                        showIcon: false,
                      ),
                      if (course.overallGrade < _atRiskThreshold) ...[
                        const SizedBox(width: 8),
                        const AtRiskBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GradeLabel(
                        grade: GradeHelper.gradeForDisplay(course.overallGrade),
                        userSettings: userSettings!,
                      ),
                      if (course.trend != null) ...[
                        const SizedBox(width: 4),
                        Icon(
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
                      ],
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
                      SelectableText(
                        '${course.numHomeworkGraded} graded',
                        style: AppStyles.standardBodyText(context).copyWith(
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: context.colorScheme.primary,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                ),
              ),
              onPressed: () => _toggleExpandedCourse(course.id),
            ),
          ],
        ),
      ),
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

  void _saveGraphSettingsIfEnabled() {
    if (!(userSettings?.rememberFilterState ?? false)) return;

    final graphSettings = {'autoAdjustToGradedRange': _autoAdjustToGradedRange};
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
      if (savedAutoAdjust == null) return;

      setState(() {
        _autoAdjustToGradedRange = savedAutoAdjust;
      });
    } catch (_) {
      // Ignore malformed settings and keep defaults.
    }
  }

  Widget _buildCourseArea(GradeCourseModel course) {
    final hasWeightedGrading = course.categories.any((cat) => cat.weight > 0);
    final isMobile = Responsive.isMobile(context);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: course.color.withValues(alpha: 0.2)),
      ),
      child: hasWeightedGrading
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPieCharts(course)),
                const SizedBox(width: 16),
                Expanded(
                  flex: isMobile ? 3 : 2,
                  child: _buildCategoryTable(course),
                ),
              ],
            )
          : _buildCategoryTable(course),
    );
  }

  Widget _buildCategoryTable(GradeCourseModel course) {
    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: course.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Category',
                  style: AppStyles.standardBodyText(context),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Graded',
                  textAlign: TextAlign.center,
                  style: AppStyles.standardBodyText(context),
                ),
              ),
              Expanded(
                flex: 2,
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
          itemCount: course.categories.length,
          itemBuilder: (context, catIndex) {
            final category = course.categories[catIndex];
            return _buildCategoryRow(category);
          },
          separatorBuilder: (context, catIndex) {
            return const Divider(height: 1, indent: 12, endIndent: 12);
          },
        ),
      ],
    );
  }

  Widget _buildPieCharts(GradeCourseModel course) {
    final currentData = _buildCurrentDistributionData(course);

    // Sort by contribution (highest to lowest)
    currentData.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grade Breakdown Header
        Text('Grade Breakdown', style: AppStyles.headingText(context)),
        const SizedBox(height: 16),
        // Horizontal bars for each category
        ...currentData.map(
          (segment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category label
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: Responsive.getIconSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: segment.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        segment.label,
                        style: AppStyles.smallSecondaryTextLight(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${segment.value.toStringAsFixed(1)}%',
                      style: AppStyles.smallSecondaryTextLight(context)
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            color: segment.color,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: segment.value / 100,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: segment.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ChartSegment> _buildWeightDistributionData(GradeCourseModel course) {
    return course.categories
        .where((cat) => cat.weight > 0)
        .map(
          (cat) => ChartSegment(
            label: cat.title,
            value: cat.weight,
            color: cat.color,
          ),
        )
        .toList();
  }

  List<ChartSegment> _buildCurrentDistributionData(GradeCourseModel course) {
    final segments = course.categories
        .where((cat) => cat.gradeByWeight != null && cat.gradeByWeight! > 0)
        .map(
          (cat) => ChartSegment(
            label: cat.title,
            value: cat.gradeByWeight!,
            color: cat.color,
          ),
        )
        .toList();

    // If no gradeByWeight data, fall back to showing weights
    if (segments.isEmpty) {
      return _buildWeightDistributionData(course);
    }

    return segments;
  }

  Widget _buildCategoryRow(GradeCategoryModel category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.category_outlined,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  color: category.color,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    category.title,
                    style: AppStyles.standardBodyText(
                      context,
                    ).copyWith(color: context.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${category.numHomeworkGraded} of ${category.numHomework}',
              textAlign: TextAlign.center,
              style: AppStyles.standardBodyText(context).copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: GradeLabel(
                grade: GradeHelper.gradeForDisplay(category.overallGrade),
                userSettings: userSettings!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
