// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/grade_repository_impl.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/grade_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/grade/grade_bloc.dart';
import 'package:heliumapp/presentation/bloc/grade/grade_event.dart';
import 'package:heliumapp/presentation/bloc/grade/grade_state.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/category_title_label.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/grade_label.dart';
import 'package:heliumapp/presentation/widgets/group_dropdown.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/shadow_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class GradesScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
  @override
  // TODO: Cleanup: have the shell pass down its label here instead
  String get screenTitle => 'Grades';

  // State
  List<CourseGroupModel> _courseGroups = [];
  List<GradeCourseGroupModel> _grades = [];
  int? _selectedGroupId;
  int? _expandedCourseIndex;

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
            _expandedCourseIndex = null;
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

            const SizedBox(height: 12),

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
    const double minBoxWidth = 150.0;
    const double maxBoxWidth = 170.0;
    const double boxHeight = 120.0;
    const double spacing = 8.0;
    const double maxContainerWidth = 800.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContainerWidth),
        child: ShadowContainer(
          padding: const EdgeInsets.all(18),
          color: context.colorScheme.primary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - 40;
              final canFitFour =
                  availableWidth >= (minBoxWidth * 4 + spacing * 3);
              final itemsPerRow = canFitFour ? 4 : 2;
              final itemWidth =
                  (availableWidth - (spacing * (itemsPerRow - 1))) /
                  itemsPerRow;
              // Only clamp to max in 4-item mode; in 2-item mode use full width to prevent 3+1 layout
              final finalWidth = canFitFour
                  ? itemWidth.clamp(minBoxWidth, maxBoxWidth)
                  : itemWidth;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: finalWidth,
                    height: boxHeight,
                    child: _buildSummaryCard(context, index),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGraphArea() {
    // TODO: Feature Parity: implement graphs like current frontend, with https://pub.dev/packages/syncfusion_flutter_charts
    return const SizedBox.shrink();
  }

  Widget _buildCourseCard(int index, GradeCourseModel course) {
    final isExpanded = _expandedCourseIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_expandedCourseIndex == index) {
              _expandedCourseIndex = null;
            } else {
              _expandedCourseIndex = index;
            }
          });
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCourseSummaryArea(isExpanded, course),

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
        ),
      ),
    );
  }

  Widget _buildCourseSummaryArea(bool isExpanded, GradeCourseModel course) {
    return Row(
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
              CourseTitleLabel(
                title: course.title,
                color: course.color,
                showIcon: false,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GradeLabel(
                    grade: Format.gradeForDisplay(course.overallGrade),
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
                    color: context.colorScheme.onSurface.withValues(alpha: 0.3),
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
        AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
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
        ),
      ],
    );
  }

  Widget _buildCourseArea(GradeCourseModel course) {
    // TODO: Feature Parity: implement pie charts like current frontend, with SyncFusion widgets

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: course.color.withValues(alpha: 0.2)),
      ),
      child: Column(
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
      ),
    );
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
                Flexible(
                  child: CategoryTitleLabel(
                    title: category.title,
                    color: category.color,
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
                grade: Format.gradeForDisplay(category.overallGrade),
                userSettings: userSettings!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int index) {
    final selectedGroup = _grades.firstWhere((g) => g.id == _selectedGroupId);

    // Build summary cards based on index
    Widget cardContent;
    switch (index) {
      case 0:
        cardContent = _buildCompletedSummaryCard(selectedGroup);
        break;
      case 1:
        cardContent = _buildThruTermSummaryCard();
        break;
      case 2:
        cardContent = _buildAssignmentsSummaryCard(selectedGroup);
        break;
      case 3:
        cardContent = _buildGradedSummaryCard(selectedGroup);
        break;
      default:
        throw HeliumException(
          message: '$index is not a valid GradeSummaryCard index.',
        );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.onPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: cardContent,
    );
  }

  Widget _buildCompletedSummaryCard(GradeCourseGroupModel selectedGroup) {
    final remainingAssignments =
        selectedGroup.numHomework - selectedGroup.numHomeworkGraded;
    final completionPercentage = selectedGroup.numHomework > 0
        ? (selectedGroup.numHomeworkCompleted / selectedGroup.numHomework * 100)
              .round()
        : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.onPrimary.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              '$completionPercentage%',
              style: AppStyles.standardBodyText(context).copyWith(
                color: context.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedGroup.numHomeworkCompleted} complete',
          textAlign: TextAlign.center,
          style: AppStyles.smallSecondaryText(context).copyWith(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
        ),
        Text(
          '$remainingAssignments ${remainingAssignments.plural('assignment')} left',
          textAlign: TextAlign.center,
          style: AppStyles.smallSecondaryText(context).copyWith(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildThruTermSummaryCard() {
    final courseGroup = _courseGroups.firstWhere(
      (g) => g.id == _selectedGroupId,
    );

    final thruTermPercentage = HeliumDateTime.getPercentDiffBetween(
      courseGroup.startDate,
      courseGroup.endDate,
    );
    final daysLeft = HeliumDateTime.getDaysBetween(
      courseGroup.startDate,
      courseGroup.endDate,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.onPrimary.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              '$thruTermPercentage%',
              style: AppStyles.standardBodyText(context).copyWith(
                color: context.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'through term',
          textAlign: TextAlign.center,
          style: AppStyles.smallSecondaryText(context).copyWith(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
        ),
        Text(
          '$daysLeft ${daysLeft.plural('day')} left',
          textAlign: TextAlign.center,
          style: AppStyles.smallSecondaryText(context).copyWith(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsSummaryCard(GradeCourseGroupModel selectedGroup) {
    final selectedGroup = _grades.firstWhere((g) => g.id == _selectedGroupId);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          selectedGroup.numHomework.toString(),
          style: AppStyles.headingText(
            context,
          ).copyWith(color: context.colorScheme.onPrimary),
        ),
        Text(
          'total ${selectedGroup.numHomework.plural('assignment')}',
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppStyles.standardBodyText(context).copyWith(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildGradedSummaryCard(GradeCourseGroupModel selectedGroup) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          selectedGroup.numHomeworkGraded.toString(),
          style: AppStyles.headingText(
            context,
          ).copyWith(color: context.colorScheme.onPrimary),
        ),
        Text(
          'graded',
          textAlign: TextAlign.center,
          softWrap: true,
          style: AppStyles.standardBodyText(context).copyWith(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
