// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_schedule_event_repository_impl.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_state.dart';
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/dialogs/course_group_dialog.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/group_dropdown.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/mobile_gesture_detector.dart';
import 'package:heliumapp/presentation/widgets/pill_badge.dart';
import 'package:heliumapp/presentation/widgets/responsive_card_grid.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class CoursesScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  CoursesScreen({super.key});

  StatefulWidget buildScreen() => const CoursesProvidedScreen();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CourseBloc(
            courseRepository: CourseRepositoryImpl(
              remoteDataSource: CourseRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
            courseScheduleRepository: CourseScheduleRepositoryImpl(
              remoteDataSource: CourseScheduleRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
            categoryRepository: CategoryRepositoryImpl(
              remoteDataSource: CategoryRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
      ],
      child: buildScreen(),
    );
  }
}

class CoursesProvidedScreen extends StatefulWidget {
  const CoursesProvidedScreen({super.key});

  @override
  State<CoursesProvidedScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends BasePageScreenState<CoursesProvidedScreen> {
  @override
  // TODO: Cleanup: have the shell pass down its label here instead
  String get screenTitle => 'Classes';

  @override
  VoidCallback get actionButtonCallback => () {
    if (_selectedGroupId != null) {
      context.push(
        AppRoutes.courseAddScreen,
        extra: CourseAddArgs(
          courseBloc: context.read<CourseBloc>(),
          courseGroupId: _selectedGroupId!,
          isEdit: false,
        ),
      );
    } else {
      showSnackBar(context, 'Create a group first', isError: true);
    }
  };

  @override
  bool get showActionButton => _courseGroups.isNotEmpty;

  // State
  List<CourseGroupModel> _courseGroups = [];
  final Map<int, List<CourseModel>> _coursesMap = {};
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();

    context.read<CourseBloc>().add(
      FetchCoursesScreenDataEvent(origin: EventOrigin.subScreen),
    );
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CoursesScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is CourseGroupCreated) {
            showSnackBar(context, 'Class group saved');

            setState(() {
              _courseGroups.add(state.courseGroup);
              Sort.byStartDate(_courseGroups);
              _selectedGroupId = state.courseGroup.id;
              _coursesMap[_selectedGroupId!] = [];
            });
          } else if (state is CourseGroupUpdated) {
            showSnackBar(context, 'Class group saved');

            setState(() {
              _courseGroups[_courseGroups.indexWhere(
                    (g) => g.id == state.courseGroup.id,
                  )] =
                  state.courseGroup;
              Sort.byStartDate(_courseGroups);
            });
          } else if (state is CourseGroupDeleted) {
            showSnackBar(context, 'Class group deleted');

            setState(() {
              _courseGroups.removeWhere((g) => g.id == state.id);
              if (_courseGroups.isEmpty) {
                _selectedGroupId = null;
              } else {
                // Reset if selected group was deleted
                if (!_courseGroups.any((g) => g.id == _selectedGroupId)) {
                  _selectedGroupId = _courseGroups.first.id;
                }
              }
            });
          } else if (state is CourseCreated) {
            if (_selectedGroupId == null) return;

            setState(() {
              _coursesMap[_selectedGroupId]!.add(state.course);
              Sort.byTitle(_coursesMap[_selectedGroupId]!);
            });
          } else if (state is CourseUpdated) {
            if (_selectedGroupId == null) return;

            setState(() {
              final index = _coursesMap[_selectedGroupId]!.indexWhere(
                (c) => c.id == state.course.id,
              );
              _coursesMap[_selectedGroupId]![index] = state.course;
              Sort.byTitle(_coursesMap[_selectedGroupId]!);
            });
          } else if (state is CourseDeleted) {
            if (_selectedGroupId == null) return;

            showSnackBar(context, 'Class deleted');

            setState(() {
              _coursesMap[_selectedGroupId]!.removeWhere(
                (c) => c.id == state.id,
              );
              Sort.byTitle(_coursesMap[_selectedGroupId]!);
            });
          } else if (state is CourseScheduleUpdated) {
            if (_selectedGroupId == null) return;

            setState(() {
              final index = _coursesMap[_selectedGroupId]!.indexWhere(
                (c) => c.id == state.schedule.course,
              );
              _coursesMap[_selectedGroupId]![index].schedules[0] =
                  state.schedule;
              Sort.byTitle(_coursesMap[_selectedGroupId]!);
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GroupDropdown(
        groups: _courseGroups,
        initialSelection: _courseGroups.firstWhereOrNull(
          (g) => g.id == _selectedGroupId,
        ),
        onChanged: (value) {
          // The "+" button has a null value
          if (value == null) return;
          if (value.id == _selectedGroupId) return;

          setState(() {
            _selectedGroupId = value.id;
          });
        },
        onCreate: () {
          showCourseGroupDialog(parentContext: context, isEdit: false);
        },
        onEdit: (group) {
          showCourseGroupDialog(
            parentContext: context,
            isEdit: true,
            group: group,
          );
        },
        onDelete: (g) => {
          context.read<CourseBloc>().add(
            DeleteCourseGroupEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: (g as BaseModel).id,
            ),
          ),
        },
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        if (state is CoursesLoading) {
          return const LoadingIndicator();
        }

        if (state is CoursesError && state.origin == EventOrigin.screen) {
          return ErrorCard(
            message: state.message!,
            onReload: () {
              context.read<CourseBloc>().add(
                FetchCoursesScreenDataEvent(origin: EventOrigin.screen),
              );
            },
          );
        }

        if (_courseGroups.isEmpty) {
          return const EmptyCard(
            icon: Icons.school,
            title: "You haven't added any groups yet",
            message: 'Click "+ Group" to get started',
          );
        }

        if (_selectedGroupId == null ||
            (_coursesMap[_selectedGroupId]?.isEmpty ?? true)) {
          return const EmptyCard(
            icon: Icons.school,
            title: "You haven't added any classes yet",
            message: 'Click "+" to get started',
          );
        }

        return _buildCoursesList();
      },
    );
  }

  Widget _buildCoursesList() {
    if (_selectedGroupId == null) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: ResponsiveCardGrid<CourseModel>(
        items: _coursesMap[_selectedGroupId]!,
        itemBuilder: (context, course) => _buildCoursesCard(context, course),
      ),
    );
  }

  void _populateInitialStateData(CoursesScreenDataFetched state) {
    setState(() {
      _courseGroups = state.courseGroups;
      Sort.byStartDate(_courseGroups);

      for (var group in _courseGroups) {
        _coursesMap[group.id] = state.courses
            .where((c) => c.courseGroup == group.id)
            .toList();
        Sort.byTitle(_coursesMap[group.id]!);
      }

      if (_courseGroups.isNotEmpty) {
        _selectedGroupId = _courseGroups.first.id;
      }

      isLoading = false;
    });
  }

  Widget _buildCoursesCard(BuildContext context, CourseModel course) {
    return MobileGestureDetector(
      onTap: () => _onEdit(course),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CourseTitleLabel(
                      title: course.title,
                      color: course.color,
                    ),
                  ),
                  // TODO: Enhancement: show attachments icon, when clicked open a menu and list as rows with titles and download buttons
                  const SizedBox(width: 8),
                  if (course.teacherEmail.isNotEmpty) ...[
                    HeliumIconButton(
                      onPressed: () {
                        launchUrl(Uri.parse('mailto:${course.teacherEmail}'));
                      },
                      icon: Icons.email_outlined,
                      tooltip: 'Email teacher',
                      color: context.semanticColors.info,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (course.website.isNotEmpty) ...[
                    HeliumIconButton(
                      onPressed: () {
                        launchUrl(
                          Uri.parse(course.website),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: Icons.link_outlined,
                      tooltip: 'Launch class website',
                      color: context.semanticColors.success,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!Responsive.isMobile(context)) ...[
                    HeliumIconButton(
                      onPressed: () => _onEdit(course),
                      icon: Icons.edit_outlined,
                    ),
                    const SizedBox(width: 8),
                  ],
                  HeliumIconButton(
                    onPressed: () {
                      showConfirmDeleteDialog(
                        parentContext: context,
                        item: course,
                        additionalWarning:
                            'Any assignments associated with this class will also be deleted.',
                        onDelete: (c) {
                          context.read<CourseBloc>().add(
                            DeleteCourseEvent(
                              origin: EventOrigin.subScreen,
                              courseGroupId: c.courseGroup,
                              courseId: c.id,
                            ),
                          );
                        },
                      );
                    },
                    icon: Icons.delete_outline,
                    color: context.colorScheme.error,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (course.teacherName.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      course.teacherName,
                      style: AppStyles.headingText(context),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),

              if (course.room.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.pin_drop_outlined,
                      size: Responsive.getIconSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SelectableText(
                      course.room,
                      style: AppStyles.standardBodyText(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              const Divider(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: Responsive.getIconSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${HeliumDateTime.formatDateForDisplay(DateTime.parse(course.startDate))} to ${HeliumDateTime.formatDateForDisplay(DateTime.parse(course.endDate))}',
                    style: AppStyles.standardBodyText(context).copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 15,
                      ),
                    ),
                  ),
                ],
              ),

              if (course.schedules.isNotEmpty &&
                  course.schedules[0].daysOfWeek != '0000000') ...[
                const SizedBox(height: 12),

                Column(children: _buildCourseScheduleContainers(course)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Container> _buildCourseScheduleContainers(CourseModel course) {
    final List<Container> containers = [];

    final schedulesByTime = _groupSchedulesByTime(course.schedules);

    // Build a container for each time group
    for (final timeEntry in schedulesByTime.entries) {
      final timeRange = timeEntry.key;
      final days = timeEntry.value;

      containers.add(
        _buildGroupedScheduleContainer(days, timeRange, course.color),
      );
    }

    return containers;
  }

  Map<String, List<String>> _groupSchedulesByTime(
    List<CourseScheduleModel> schedules,
  ) {
    final Map<String, List<String>> schedulesByTime = {};

    for (final schedule in schedules) {
      if (schedule.allDaysSameTime()) {
        final activeDays = schedule.getActiveDays();
        if (activeDays.isNotEmpty) {
          final timeKey = schedule.getDateTimeRangeForDisplay(activeDays[0]);
          schedulesByTime.putIfAbsent(timeKey, () => []).addAll(activeDays);
        }
      } else {
        for (final day in schedule.getActiveDays()) {
          final timeKey = schedule.getDateTimeRangeForDisplay(day);
          schedulesByTime.putIfAbsent(timeKey, () => []).add(day);
        }
      }
    }

    return schedulesByTime;
  }

  Container _buildGroupedScheduleContainer(
    List<String> days,
    String timeRange,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: days.map((day) {
              return PillBadge(text: day, color: color);
            }).toList(),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.access_time,
                size: Responsive.getIconSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                timeRange,
                style: AppStyles.standardBodyText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onEdit(CourseModel course) {
    context.push(
      AppRoutes.courseAddScreen,
      extra: CourseAddArgs(
        courseBloc: context.read<CourseBloc>(),
        courseGroupId: course.courseGroup,
        courseId: course.id,
        isEdit: true,
      ),
    );
  }
}
