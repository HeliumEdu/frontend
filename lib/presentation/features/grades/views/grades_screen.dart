// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
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
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/core/views/deep_link_mixin.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_bloc.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_event.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_state.dart';
import 'package:heliumapp/presentation/features/grades/dialogs/grade_calculator_dialog.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/ui/components/category_title_label.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/group_dropdown.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GradesScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final ProviderHelpers _providerHelpers = ProviderHelpers();

  GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
      child: const _GradesProvidedScreen(),
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
            Icons.warning_amber_rounded,
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

class _GradesProvidedScreen extends StatefulWidget {
  const _GradesProvidedScreen();

  @override
  State<_GradesProvidedScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends BasePageScreenState<_GradesProvidedScreen>
    with DeepLinkMixin {
  static const _savedGradeGraphSettingsKey = 'saved_grades_graph_settings';
  static const _overallSeriesName = 'Overall Grade';

  @override
  String get screenTitle => 'Grades';

  @override
  bool get enablePrint => true;

  @override
  String get routePath => AppRoute.gradesScreen;

  // Category table row element heights
  static const double _contributionBarHeight = 24;

  // Category table column widths
  static const double _gradedColTablet = 70;
  static const double _gradedColDesktop = 120;
  static const double _contributionColMobile = 90;
  static const double _contributionColTablet = 120;
  static const double _contributionColDesktop = 170;
  static const double _averageColMobile = 90;
  static const double _averageColDesktop = 105;

  // Decision variables - adjust these to tune the grade insights
  double get _atRiskThreshold =>
      (userSettings?.atRiskThreshold ??
              FallbackConstants.defaultAtRiskThreshold)
          .toDouble();

  double get _onTrackTolerance =>
      (userSettings?.onTrackTolerance ??
              FallbackConstants.defaultOnTrackTolerance)
          .toDouble();
  static const double _defaultDesiredGradeBoost =
      5.0; // Default boost above current grade for calculator
  static const double _chartAnimationDurationMs = 250;

  List<CourseGroupModel> _courseGroups = [];
  List<GradeCourseGroupModel> _grades = [];
  int? _selectedGroupId;
  int? _pendingImpactCourseId;
  final Set<int> _expandedCourseIds = {};
  final Map<int, GlobalKey> _courseCardKeys = {};

  _GraphViewMode _graphViewMode = const _GraphViewMode.term();
  final Map<String, bool> _visibleSeries = {}; // series ID -> visibility
  bool _autoAdjustToGradedRange = false;
  bool _hideLegend = false;
  bool _graphExpanded = true;

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
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdated) {
            setState(() {
              userSettings = state.user.settings;
            });
          }
        },
      ),
      BlocListener<GradeBloc, GradeState>(
        listener: (context, state) {
          if (state is GradesError) {
            showSnackBar(context, state.message!, type: SnackType.error);
          } else if (state is GradeScreenDataFetched) {
            _populateInitiateStateData(state);
            openFromQueryParams();
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
          return const Center(child: LoadingIndicator(expanded: false));
        }

        if (state is GradesError) {
          return ErrorCard(
            message: state.message!,
            source: 'grades_screen',
            onReload: () {
              return context.read<GradeBloc>().add(
                FetchGradeScreenDataEvent(forceRefresh: true),
              );
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
      _pendingImpactCourseId = null;
      isLoading = false;
    });
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
                    message: 'An unknown error occurred loading the graph.',
                    source: 'grades_screen',
                    onReload: () {
                      context.read<GradeBloc>().add(
                        FetchGradeScreenDataEvent(forceRefresh: true),
                      );
                    },
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
                try {
                  final course = courses[index];
                  return PrintPageBreak(
                    child: _buildCourseCard(
                      index,
                      course,
                      forceExpanded: isCapturing,
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
      final expectedWorkAtRiskCutoff = timePercent * (_atRiskThreshold / 100);
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
        .where(
          (course) =>
              course.numHomeworkGraded > 0 &&
              course.overallGrade < _atRiskThreshold,
        )
        .toList();
    final atRiskCount = atRiskCourses.length;
    final totalGraded = selectedGroup.courses.fold(
      0,
      (sum, course) => sum + course.numHomeworkGraded,
    );

    return MouseRegion(
      cursor: atRiskCount > 0
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: atRiskCount > 0
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
                  color: atRiskCount > 0
                      ? context.colorScheme.error.withValues(alpha: 0.15)
                      : context.semanticColors.success.withValues(alpha: 0.15),
                  border: Border.all(
                    color: atRiskCount > 0
                        ? context.colorScheme.error
                        : context.semanticColors.success,
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
                      color: atRiskCount > 0
                          ? context.colorScheme.error
                          : context.semanticColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (atRiskCount > 0 || totalGraded > 0) ...[
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
    );
  }

  Widget _buildPendingImpactCard(GradeCourseGroupModel selectedGroup) {
    final ungradedCount = selectedGroup.numHomeworkGraded > 0
        ? selectedGroup.numHomework - selectedGroup.numHomeworkGraded
        : selectedGroup.numHomework;

    // Courses sorted by ungraded count descending; top course is first
    final sortedCourses = [...selectedGroup.courses]
      ..sort((a, b) {
        final aU = a.numHomework - a.numHomeworkGraded;
        final bU = b.numHomework - b.numHomeworkGraded;
        return bU.compareTo(aU);
      });

    final topCourse =
        sortedCourses.isNotEmpty &&
            (sortedCourses.first.numHomework -
                    sortedCourses.first.numHomeworkGraded) >
                0
        ? sortedCourses.first
        : null;

    final displayCourse = _pendingImpactCourseId != null
        ? selectedGroup.courses.firstWhereOrNull(
                (c) => c.id == _pendingImpactCourseId,
              ) ??
              topCourse
        : topCourse;

    final displayUngraded = displayCourse != null
        ? displayCourse.numHomework - displayCourse.numHomeworkGraded
        : 0;

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
                      : context.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          if (displayCourse != null && displayUngraded > 0) ...[
            const SizedBox(height: 8),
            MouseRegion(
              cursor: sortedCourses.length > 1
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                onTap: sortedCourses.length > 1
                    ? () => _cyclePendingImpactCourse(sortedCourses)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: displayCourse.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.0),
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
                          style: AppStyles.smallSecondaryText(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (sortedCourses.length > 1) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz,
                          size: 12,
                          color: displayCourse.color,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
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

  void _showGradeCalculatorOptions(
    BuildContext buttonContext,
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

    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (menuContext, _) =>
              _buildGradeCalculatorPickerContent(menuContext, eligibleCourses),
        ),
      );
    } else {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        items: [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (menuContext, _) => _buildGradeCalculatorPickerContent(
                menuContext,
                eligibleCourses,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildGradeCalculatorPickerContent(
    BuildContext menuContext,
    List<GradeCourseModel> eligibleCourses,
  ) {
    return Material(
      color: context.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < eligibleCourses.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: EdgeInsets.only(
                  top: i == 0 ? 0 : 8,
                  bottom: i == eligibleCourses.length - 1 ? 0 : 8,
                ),
                child: ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.school,
                      size: 16,
                      color: eligibleCourses[i].color,
                    ),
                  ),
                  title: Text(
                    eligibleCourses[i].title,
                    style: AppStyles.formText(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: GradeLabel(
                    grade: GradeHelper.gradeForDisplay(
                      eligibleCourses[i].overallGrade,
                    ),
                    userSettings: userSettings!,
                    compact: true,
                    selectable: false,
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(menuContext);
                    _openGradeCalculator(eligibleCourses[i]);
                  },
                ),
              ),
            ],
          ],
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
    unawaited(AnalyticsService().logEvent(
      name: 'grade_calculator_opened',
      parameters: {'category': 'feature_interaction'},
    ));
    unawaited(AnalyticsService().setUserProperty(name: 'uses_grade_calculator', value: 'true'));
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
    final isTermView = _graphViewMode.isTerm;
    final List<charts.CartesianSeries<_ChartDataPoint, DateTime>> series = [];

    if (isTermView) {
      if (selectedGroup.gradePoints.isNotEmpty) {
        series.add(_buildOverallSeries(selectedGroup.gradePoints));
      }
      for (var course in selectedGroup.courses) {
        if (course.gradePoints.isNotEmpty) {
          series.add(_buildCourseSeries(course));
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
        if (course.gradePoints.isNotEmpty) {
          series.add(_buildOverallSeries(course.gradePoints));
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
      return const EmptyCard(
        icon: Icons.bar_chart,
        title: 'Nothing to visualize yet',
        message: "Come back here after you've entered some grades on 'Planner'",
        expanded: false,
      );
    }

    // Full width container like other cards
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
    final coursesWithCategories = gradeGroup.courses
        .where((course) => course.categories.isNotEmpty)
        .toList();
    final course = _getSelectedCourse();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
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
                  if (!Responsive.isMobile(context))
                    Text('Grade Trend', style: AppStyles.headingText(context)),
                  if (Responsive.isMobile(context) && course == null)
                    Text('Entire Term', style: AppStyles.headingText(context)),
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
            if (coursesWithCategories.isNotEmpty)
              PrintHidden(
                child: Builder(
                  builder: (buttonContext) => Tooltip(
                    message: 'What Grade Do I Need?',
                    child: IconButton(
                      icon: const Icon(Icons.calculate_outlined),
                      onPressed: () => _showGradeCalculatorOptions(
                        buttonContext,
                        gradeGroup,
                        coursesWithCategories,
                      ),
                    ),
                  ),
                ),
              ),
            // Gear icon for settings
            PrintHidden(
              child: Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: 'Graph settings',
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showGraphSettings(buttonContext),
                ),
              ),
            ),
            // Expand/collapse chevron
            PrintHidden(
              child: IconButton(
                icon: AnimatedRotation(
                  turns: _graphExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
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
    List<charts.CartesianSeries<_ChartDataPoint, DateTime>> series,
    int groupId,
  ) {
    final courseGroup = _getCourseGroupForId(groupId);

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
        now.isAfter(xAxisRange.min) && now.isBefore(xAxisRange.max);
    final isTermView = _graphViewMode.isTerm;

    return SizedBox(
      height: 400,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart area
          Expanded(
            child: charts.SfCartesianChart(
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
                    (
                      dynamic data,
                      dynamic point,
                      dynamic series,
                      int pointIndex,
                      int seriesIndex,
                    ) {
                      final seriesName =
                          (seriesIndex >= 0 &&
                              seriesIndex < visibleSeries.length)
                          ? (visibleSeries[seriesIndex].name ?? '')
                          : '';
                      return _buildGradeTrendTooltip(
                        chartPoint: data as _ChartDataPoint,
                        seriesName: seriesName,
                        isTermView: isTermView,
                      );
                    },
              ),
              trackballBehavior: charts.TrackballBehavior(
                enable: true,
                activationMode: charts.ActivationMode.singleTap,
                lineType: charts.TrackballLineType.vertical,
                tooltipDisplayMode: charts.TrackballDisplayMode.floatAllPoints,
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
          if (!_hideLegend)
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

  Widget _buildTrackballTooltip(
    charts.TrackballDetails trackballDetails,
    List<charts.CartesianSeries<_ChartDataPoint, DateTime>> visibleSeries,
    bool isTermView,
  ) {
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

    final pointData = dataSource[pointIndex];

    return _buildGradeTrendTooltip(
      chartPoint: pointData,
      seriesName: series.name ?? '',
      isTermView: isTermView,
    );
  }

  Widget _buildGradeTrendTooltip({
    required _ChartDataPoint chartPoint,
    required String seriesName,
    required bool isTermView,
  }) {
    final homeworkTitle = chartPoint.homeworkTitle?.trim().isNotEmpty == true
        ? chartPoint.homeworkTitle!
        : 'No assignment title';
    final homeworkGradeText = GradeHelper.gradeForDisplay(
      chartPoint.homeworkGrade,
    );
    final category = _categoryForId(chartPoint.categoryId);
    final categoryTitle = category?.title;
    final categoryColor =
        category?.color ?? context.colorScheme.onSurface.withValues(alpha: 0.6);
    final seriesColor = _seriesColorForName(seriesName);
    final isOverallSeries = seriesName == _overallSeriesName;
    final isCourseSeries = isTermView && !isOverallSeries;
    final isNonOverallSeries = !isOverallSeries;
    final classGradeAtPoint = '${chartPoint.grade.toStringAsFixed(2)}%';

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
          if (isOverallSeries)
            if (isTermView)
              Text(
                'Overall • $classGradeAtPoint',
                style: AppStyles.standardBodyText(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 14, color: categoryColor),
                  const SizedBox(width: 4),
                  Text(
                    '• $classGradeAtPoint',
                    style: AppStyles.standardBodyText(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
          if (isOverallSeries && isTermView && categoryTitle != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined, size: 13, color: categoryColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    categoryTitle,
                    style: AppStyles.smallSecondaryText(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (isCourseSeries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 14, color: seriesColor),
                const SizedBox(width: 4),
                Text(
                  '• $classGradeAtPoint',
                  style: AppStyles.standardBodyText(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          if (isNonOverallSeries) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppConstants.assignmentIcon,
                  size: 13,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$homeworkTitle • $homeworkGradeText',
                    style: AppStyles.smallSecondaryText(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(
    List<charts.CartesianSeries<_ChartDataPoint, DateTime>> series,
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

  charts.SplineSeries<_ChartDataPoint, DateTime> _buildOverallSeries(
    List<List<dynamic>> gradePoints,
  ) {
    final dataSource = _parseGradePoints(gradePoints);
    return _buildOverallLikeSeries(dataSource);
  }

  charts.SplineSeries<_ChartDataPoint, DateTime> _buildOverallLikeSeries(
    List<_ChartDataPoint> dataSource,
  ) {
    return charts.SplineSeries<_ChartDataPoint, DateTime>(
      name: _overallSeriesName,
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

  charts.SplineSeries<_ChartDataPoint, DateTime> _buildCourseSeries(
    GradeCourseModel course,
  ) {
    final dataSource = _parseGradePoints(course.gradePoints);
    return charts.SplineSeries<_ChartDataPoint, DateTime>(
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

  charts.SplineSeries<_ChartDataPoint, DateTime> _buildCategorySeries(
    GradeCategoryModel category,
  ) {
    final dataSource = _parseGradePoints(category.gradePoints);
    return charts.SplineSeries<_ChartDataPoint, DateTime>(
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

  List<_ChartDataPoint> _parseGradePoints(List<List<dynamic>> gradePoints) {
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

      return _ChartDataPoint(
        date: date,
        grade: grade,
        homeworkId: homeworkId,
        homeworkTitle: homeworkTitle,
        homeworkGrade: homeworkGrade,
        categoryId: categoryId,
      );
    }).toList();
  }

  GradeCategoryModel? _categoryForId(int? categoryId) {
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
          return category;
        }
      }
    }

    return null;
  }

  void _handlePointTap(
    BuildContext context,
    List<_ChartDataPoint> dataSource,
    charts.ChartPointDetails pointDetails,
  ) {
    final pointIndex = pointDetails.pointIndex;

    if (pointIndex == null || pointIndex >= dataSource.length) return;

    final chartDataPoint = dataSource[pointIndex];
    final homeworkId = chartDataPoint.homeworkId;

    if (homeworkId == null) {
      return; // No homework associated with this grade point
    }

    // Open the calendar item (assignment)
    openWithGuard(
      '${DeepLinkParam.homeworkId}:$homeworkId',
      () => showPlannerItemAdd(
        context,
        homeworkId: homeworkId,
        isEdit: true,
        isNew: false,
      ),
    );
  }

  _NumericRange _calculateYAxisRange(
    List<charts.CartesianSeries<_ChartDataPoint, DateTime>> visibleSeries,
  ) {
    if (visibleSeries.isEmpty) {
      return const _NumericRange(min: 0.0, max: 100.0);
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
    return _NumericRange(min: minimum, max: 100.0);
  }

  _DateTimeRange _calculateXAxisRange(
    List<charts.CartesianSeries<_ChartDataPoint, DateTime>> visibleSeries,
    CourseGroupModel courseGroup,
  ) {
    // If auto-adjust is disabled, use the full course group date range
    if (!_autoAdjustToGradedRange || visibleSeries.isEmpty) {
      return _DateTimeRange(
        min: courseGroup.startDate,
        max: courseGroup.endDate,
      );
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

    if (earliestDate != null && latestDate != null) {
      return _DateTimeRange(min: earliestDate, max: latestDate);
    }

    return _DateTimeRange(min: courseGroup.startDate, max: courseGroup.endDate);
  }

  CourseGroupModel _getCourseGroupForId(int groupId) {
    return _courseGroups.firstWhere((g) => g.id == groupId);
  }

  GradeCourseModel? _getSelectedCourse() {
    if (_graphViewMode.isTerm || _selectedGroupId == null) return null;

    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    final selectedCourseId = _graphViewMode.courseId;
    if (selectedCourseId == null) return null;
    return selectedGroup.courses.firstWhereOrNull(
      (c) => c.id == selectedCourseId,
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

  Color _seriesColorForName(String? name) {
    if (name == null || name.isEmpty) return context.colorScheme.onSurface;
    if (name == _overallSeriesName) return context.colorScheme.onSurface;

    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    final matchedCourse = selectedGroup.courses.firstWhereOrNull(
      (course) => course.title == name,
    );
    if (matchedCourse != null) return matchedCourse.color;

    final selectedCourse = _getSelectedCourse();
    final matchedCategory = selectedCourse?.categories.firstWhereOrNull(
      (category) => category.title == name,
    );
    if (matchedCategory != null) return matchedCategory.color;

    return context.colorScheme.onSurface;
  }

  void _showGraphSettings(BuildContext buttonContext) {
    final isMobile = Responsive.isMobile(context);
    final selectedGroup = _grades.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => _grades.first,
    );

    Widget buildContent(BuildContext menuContext, StateSetter setMenuState) {
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
                groupValue: _graphViewMode.radioValue,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _graphViewMode = _GraphViewMode.fromRadioValue(value);
                  });
                  Navigator.pop(menuContext);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Entire Term option
                    InkWell(
                      onTap: () {
                        setState(() {
                          _graphViewMode = const _GraphViewMode.term();
                        });
                        Navigator.pop(menuContext);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          children: [
                            const Radio<String>(value: 'term'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Entire Term',
                                style: AppStyles.formText(context),
                                overflow: TextOverflow.ellipsis,
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
                            () => _graphViewMode = _GraphViewMode.course(
                              course.id,
                            ),
                          );
                          Navigator.pop(menuContext);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            top: 8,
                            bottom: 8,
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: _GraphViewMode.course(
                                  course.id,
                                ).radioValue,
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.school, size: 16, color: course.color),
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
                value: _autoAdjustToGradedRange == true,
                onChanged: (value) {
                  _setAutoAdjustToGradedRange(value ?? false);
                  setMenuState(() {});
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Hide legend', style: AppStyles.formText(context)),
                value: _hideLegend == true,
                onChanged: (value) {
                  _setHideLegend(value ?? false);
                  setMenuState(() {});
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => StatefulBuilder(builder: buildContent),
      );
    } else {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        items: [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(builder: buildContent),
          ),
        ],
      );
    }
  }

  Widget _buildCourseCard(
    int index,
    GradeCourseModel course, {
    bool forceExpanded = false,
  }) {
    final isExpanded = forceExpanded || _expandedCourseIds.contains(course.id);

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
                      if (course.numHomeworkGraded > 0 &&
                          course.overallGrade < _atRiskThreshold) ...[
                        const SizedBox(width: 8),
                        const _AtRiskBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GradeLabel(
                        grade: GradeHelper.gradeForDisplay(course.overallGrade),
                        userSettings: userSettings!,
                        compact: Responsive.isMobile(context),
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
                ],
              ),
            ),
            PrintHidden(
              child: IconButton(
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

  void _setHideLegend(bool value) {
    setState(() {
      _hideLegend = value;
    });
    _saveGraphSettingsIfEnabled();
  }

  void _saveGraphSettingsIfEnabled() {
    if (!(userSettings?.rememberFilterState ?? false)) return;

    final graphSettings = {
      'autoAdjustToGradedRange': _autoAdjustToGradedRange,
      'hideLegend': _hideLegend,
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
      if (savedAutoAdjust == null && savedHideLegend == null) return;

      setState(() {
        if (savedAutoAdjust != null) {
          _autoAdjustToGradedRange = savedAutoAdjust;
        }
        if (savedHideLegend != null) {
          _hideLegend = savedHideLegend;
        }
      });
    } catch (_) {
      // Ignore malformed settings and keep defaults.
    }
  }

  Widget _buildCourseArea(GradeCourseModel course) {
    final hasWeightedGrading = course.categories.any((cat) => cat.weight > 0);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: course.color.withValues(alpha: 0.2)),
        ),
      ),
      child: _buildCategoryTable(course, hasWeightedGrading),
    );
  }

  Map<int, int> _largestRemainder(
    List<GradeCategoryModel> categories,
    double total,
  ) {
    final gradedCats = categories
        .where((c) => c.gradeByWeight != null && c.gradeByWeight! > 0)
        .toList();
    final rawValues = gradedCats
        .map((c) => c.gradeByWeight! / total * 100)
        .toList();
    final floors = rawValues.map((v) => v.floor()).toList();
    final remainder = 100 - floors.reduce((a, b) => a + b);
    final indices = List.generate(gradedCats.length, (i) => i)
      ..sort(
        (a, b) =>
            (rawValues[b] - floors[b]).compareTo(rawValues[a] - floors[a]),
      );
    for (int i = 0; i < remainder; i++) {
      floors[indices[i]]++;
    }
    return {
      for (int i = 0; i < gradedCats.length; i++) gradedCats[i].id: floors[i],
    };
  }

  Widget _buildCategoryTable(GradeCourseModel course, bool hasWeightedGrading) {
    final sortedCategories = [...course.categories]
      ..sort((a, b) => a.title.compareTo(b.title));
    final totalBreakdown = course.categories.fold<double>(
      0,
      (sum, cat) =>
          sum +
          (cat.gradeByWeight != null && cat.gradeByWeight! > 0
              ? cat.gradeByWeight!
              : 0),
    );
    final roundedPercentages = totalBreakdown > 0
        ? _largestRemainder(course.categories, totalBreakdown)
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
                userSettings: userSettings!,
                compact: Responsive.isMobile(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(
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
            style: AppStyles.smallSecondaryText(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      ],
    );
  }
}

class _GraphViewMode {
  final int? courseId;

  const _GraphViewMode.term() : courseId = null;

  const _GraphViewMode.course(this.courseId);

  bool get isTerm => courseId == null;

  String get radioValue => isTerm ? 'term' : courseId.toString();

  static _GraphViewMode fromRadioValue(String value) {
    if (value == 'term') {
      return const _GraphViewMode.term();
    }
    return _GraphViewMode.course(int.parse(value));
  }
}

class _NumericRange {
  final double min;
  final double max;

  const _NumericRange({required this.min, required this.max});
}

class _DateTimeRange {
  final DateTime min;
  final DateTime max;

  const _DateTimeRange({required this.min, required this.max});
}

class _ChartDataPoint {
  final DateTime date;
  final double grade;
  final int? homeworkId;
  final String? homeworkTitle;
  final dynamic homeworkGrade;
  final int? categoryId;

  _ChartDataPoint({
    required this.date,
    required this.grade,
    this.homeworkId,
    this.homeworkTitle,
    this.homeworkGrade,
    this.categoryId,
  });
}
