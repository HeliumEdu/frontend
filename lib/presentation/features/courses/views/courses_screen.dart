import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_state.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/courses/widgets/schedule_summary.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/courses/dialogs/course_group_dialog.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/core/views/deep_link_mixin.dart';
import 'package:heliumapp/presentation/features/courses/views/course_add_screen.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/components/group_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/mobile_gesture_detector.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_card_grid.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/course_group_helpers.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/screen_dropdown_filter_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) => const _CoursesProvidedScreen();
}

class _CoursesProvidedScreen extends StatefulWidget {
  const _CoursesProvidedScreen();

  @override
  State<_CoursesProvidedScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends BasePageScreenState<_CoursesProvidedScreen>
    with DeepLinkMixin {
  @override
  bool get enablePrint => true;

  @override
  String get routePath => AppRoute.coursesScreen;

  @override
  VoidCallback get actionButtonCallback => () {
    if (_selectedGroupId != null) {
      showCourseAdd(
        context,
        courseGroupId: _selectedGroupId!,
        isNew: true,
      );
    } else {
      showSnackBar(context, 'Create a group first.', type: SnackType.info);
    }
  };

  @override
  bool get showActionButton => _courseGroups.isNotEmpty;

  List<CourseGroupModel> _courseGroups = [];
  final Map<int, List<CourseModel>> _coursesMap = {};
  final Map<int, int> _categoryCounts = {};
  final Map<int, int> _categoryToCourse = {};
  final Map<int, int> _attachmentCounts = {};
  final Map<int, int> _reminderCounts = {};
  final Map<int, int> _reminderToCourse = {};
  int? _selectedGroupId;

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (!mounted || settings == null) return settings;
      _restoreSelectedGroup(settings);
      return settings;
    });
  }

  @override
  void initState() {
    super.initState();

    DioClient().cacheService.addInactivityResumeListener(
      _resetSelectedGroupOnResume,
    );
    context.read<CourseBloc>().add(
      FetchCoursesScreenDataEvent(origin: EventOrigin.screen),
    );
  }

  @override
  void dispose() {
    DioClient().cacheService.removeInactivityResumeListener(
      _resetSelectedGroupOnResume,
    );
    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthScheduleDataRefreshed) {
            context.read<CourseBloc>().add(
              FetchCoursesScreenDataEvent(origin: EventOrigin.screen),
            );
          } else if (state is AuthProfileUpdated) {
            setState(() {
              userSettings = state.user.settings;
            });
          }
        },
      ),
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CoursesError && state.origin == EventOrigin.screen) {
            setState(() { isLoading = false; screenError = state.message; });
          } else if (state is CoursesScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is CourseGroupCreated) {
            showSnackBar(context, 'Group created.');

            setState(() {
              _courseGroups.add(state.courseGroup);
              Sort.byStartDate(_courseGroups);
              _selectedGroupId = state.courseGroup.id;
              _coursesMap[_selectedGroupId!] = [];
            });
            _saveSelectedGroup();
          } else if (state is CourseGroupUpdated) {
            // No snackbar on updates

            setState(() {
              final index = _courseGroups.indexWhere(
                (g) => g.id == state.courseGroup.id,
              );
              if (index == -1) return;
              _courseGroups[index] = state.courseGroup;
              Sort.byStartDate(_courseGroups);
            });
          } else if (state is CourseGroupDeleted) {
            showSnackBar(context, 'Group deleted.');

            setState(() {
              _courseGroups.removeWhere((g) => g.id == state.id);
              _coursesMap.remove(state.id);
              if (_courseGroups.isEmpty) {
                _selectedGroupId = null;
              } else if (!_courseGroups.any((g) => g.id == _selectedGroupId)) {
                // Reset if selected group was deleted
                _selectedGroupId = CourseGroupHelpers.currentGroupId(
                  _courseGroups,
                );
              }
            });
            _saveSelectedGroup();
          } else if (state is CourseCreated) {
            setState(() {
              _coursesMap
                  .putIfAbsent(state.course.courseGroup, () => [])
                  .add(state.course);
              Sort.byTitle(_coursesMap[state.course.courseGroup]!);
            });
            final totalCourses = _coursesMap.values.fold<int>(0, (sum, c) => sum + c.length);
            unawaited(AnalyticsService().setUserProperty(
              name: 'course_load_bucket',
              value: _courseLoadBucket(totalCourses),
            ));
          } else if (state is CourseUpdated) {
            setState(() {
              for (final courses in _coursesMap.values) {
                courses.removeWhere((c) => c.id == state.course.id);
              }
              _coursesMap
                  .putIfAbsent(state.course.courseGroup, () => [])
                  .add(state.course);
              Sort.byTitle(_coursesMap[state.course.courseGroup]!);
            });
          } else if (state is CourseDeleted) {
            showSnackBar(context, 'Class deleted.');

            setState(() {
              for (final courses in _coursesMap.values) {
                courses.removeWhere((c) => c.id == state.id);
              }
            });
            final totalCourses = _coursesMap.values.fold<int>(0, (sum, c) => sum + c.length);
            unawaited(AnalyticsService().setUserProperty(
              name: 'course_load_bucket',
              value: _courseLoadBucket(totalCourses),
            ));
          } else if (state is CourseScheduleUpdated) {
            // Find the schedule's course across loaded groups (its group may
            // differ from the active filter) and replace that schedule by id
            // rather than assuming a single schedule at index 0.
            setState(() {
              for (final courses in _coursesMap.values) {
                final courseIndex = courses.indexWhere(
                  (c) => c.id == state.schedule.course,
                );
                if (courseIndex == -1) continue;

                final schedules = courses[courseIndex].schedules;
                final scheduleIndex = schedules.indexWhere(
                  (s) => s.id == state.schedule.id,
                );
                if (scheduleIndex >= 0) {
                  schedules[scheduleIndex] = state.schedule;
                } else {
                  schedules.add(state.schedule);
                }
                Sort.byTitle(courses);
                break;
              }
            });
          }
        },
      ),
      BlocListener<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryCreated) {
            setState(() {
              _categoryCounts[state.category.course] =
                  (_categoryCounts[state.category.course] ?? 0) + 1;
              _categoryToCourse[state.category.id] = state.category.course;
            });
          } else if (state is CategoryDeleted) {
            final courseId = _categoryToCourse.remove(state.id);
            if (courseId != null) {
              setState(() {
                final current = _categoryCounts[courseId] ?? 0;
                if (current > 1) {
                  _categoryCounts[courseId] = current - 1;
                } else {
                  _categoryCounts.remove(courseId);
                }
              });
            }
          } else if (state is CategoriesFetched && state.categories.isNotEmpty) {
            final courseId = state.categories.first.course;
            setState(() {
              _categoryToCourse.removeWhere((_, v) => v == courseId);
              _categoryCounts[courseId] = state.categories.length;
              for (final category in state.categories) {
                _categoryToCourse[category.id] = courseId;
              }
            });
          }
        },
      ),
      BlocListener<AttachmentBloc, AttachmentState>(
        listener: (context, state) {
          if (state is AttachmentsCreated) {
            setState(() {
              for (final attachment in state.attachments) {
                if (attachment.course != null) {
                  _attachmentCounts[attachment.course!] =
                      (_attachmentCounts[attachment.course!] ?? 0) + 1;
                }
              }
            });
          } else if (state is AttachmentDeleted && state.courseId != null) {
            setState(() {
              final current = _attachmentCounts[state.courseId] ?? 0;
              if (current > 1) {
                _attachmentCounts[state.courseId!] = current - 1;
              } else {
                _attachmentCounts.remove(state.courseId);
              }
            });
          }
        },
      ),
      BlocListener<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is ReminderCreated) {
            final courseId = state.reminder.course?.id;
            if (courseId != null) {
              setState(() {
                _reminderCounts[courseId] =
                    (_reminderCounts[courseId] ?? 0) + 1;
                _reminderToCourse[state.reminder.id] = courseId;
              });
            }
          } else if (state is ReminderDeleted) {
            final courseId = _reminderToCourse.remove(state.id);
            if (courseId != null) {
              setState(() {
                final current = _reminderCounts[courseId] ?? 0;
                if (current > 1) {
                  _reminderCounts[courseId] = current - 1;
                } else {
                  _reminderCounts.remove(courseId);
                }
              });
            }
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GroupDropdown(
          groups: _courseGroups,
          initialSelection: _courseGroups.firstWhereOrNull(
            (g) => g.id == _selectedGroupId,
          ),
          isReadOnly: isCapturing,
          onChanged: (value) {
            // The "+" button has a null value
            if (value == null) return;
            if (value.id == _selectedGroupId) return;

            setState(() {
              _selectedGroupId = value.id;
            });
            _saveSelectedGroup();
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
                origin: EventOrigin.screen,
                courseGroupId: (g as BaseModel).id,
              ),
            ),
          },
        ),
      ),
    );
  }


  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        if (state is CoursesLoading && state.origin == EventOrigin.screen) {
          return const Center(child: LoadingIndicator(expanded: false));
        }

        if (screenError != null) {
          return ErrorCard(
            message: screenError!,
            source: 'courses_screen',
            onReload: reloadPage,
          );
        }

        if (_courseGroups.isEmpty) {
          return EmptyCard(
            icon: Icons.school,
            title: "You haven't added any groups yet",
            message: 'Click "+ Add Group" to get started',
            expanded: false,
            action: HeliumElevatedButton(
              buttonText: 'Where to Start',
              icon: Icons.menu_book_outlined,
              backgroundColor: context.colorScheme.onSurfaceVariant,
              fullWidth: false,
              onPressed: () => UrlHelpers.launchWebUrl(AppConstants.supportWhereToStartUrl),
            ),
          );
        }

        if (_selectedGroupId == null ||
            (_coursesMap[_selectedGroupId]?.isEmpty ?? true)) {
          return EmptyCard(
            icon: Icons.school,
            title: "You haven't added any classes yet",
            message: 'Click "+" to get started',
            expanded: false,
            action: HeliumElevatedButton(
              buttonText: 'Where to Start',
              icon: Icons.menu_book_outlined,
              backgroundColor: context.colorScheme.onSurfaceVariant,
              fullWidth: false,
              onPressed: () => UrlHelpers.launchWebUrl(AppConstants.supportWhereToStartUrl),
            ),
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

    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) => ResponsiveCardGrid<CourseModel>(
        maxCardWidth: Responsive.isDesktop(context) ? 430 : 390,
        shrinkWrap: isCapturing,
        printPageBreakAfterRow: true,
        items: _coursesMap[_selectedGroupId]!,
        itemBuilder: (context, course) {
          try {
            return _buildCourseCard(context, course);
          } catch (e, st) {
            ErrorHelpers.logAndReport(
              'Failed to render course card ${course.id}',
              e,
              st,
            );
            return const SizedBox.shrink();
          }
        },
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

      _categoryCounts.clear();
      _categoryToCourse.clear();
      for (final category in state.categories) {
        _categoryCounts[category.course] =
            (_categoryCounts[category.course] ?? 0) + 1;
        _categoryToCourse[category.id] = category.course;
      }

      _attachmentCounts.clear();
      for (final attachment in state.attachments) {
        if (attachment.course != null) {
          _attachmentCounts[attachment.course!] =
              (_attachmentCounts[attachment.course!] ?? 0) + 1;
        }
      }

      _reminderCounts.clear();
      _reminderToCourse.clear();
      for (final reminder in state.reminders) {
        final courseId = reminder.course?.id;
        if (courseId != null) {
          _reminderCounts[courseId] = (_reminderCounts[courseId] ?? 0) + 1;
          _reminderToCourse[reminder.id] = courseId;
        }
      }

      if (_courseGroups.isNotEmpty) {
        if (_selectedGroupId == null ||
            !_courseGroups.any((g) => g.id == _selectedGroupId)) {
          _selectedGroupId = CourseGroupHelpers.currentGroupId(_courseGroups);
        }
      } else {
        _selectedGroupId = null;
      }

      isLoading = false;
      screenError = null;
    });

    openFromQueryParams();
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final categoryCount = _categoryCounts[course.id] ?? 0;
    final attachmentCount = _attachmentCounts[course.id] ?? 0;
    final reminderCount = _reminderCounts[course.id] ?? 0;

    return MobileGestureDetector(
      onTap: () => _onEdit(course),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(width: 8),
                  if (course.teacherEmail.isNotEmpty) ...[
                    PrintHidden(
                      child: HeliumIconButton(
                        onPressed: () {
                          UrlHelpers.launchMailUrl(course.teacherEmail);
                        },
                        icon: Icons.email_outlined,
                        tooltip: 'Email teacher',
                        color: context.semanticColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (course.website != null) ...[
                    PrintHidden(
                      child: HeliumIconButton(
                        onPressed: () {
                          UrlHelpers.launchWebUrl(course.website.toString());
                        },
                        icon: Icons.launch_outlined,
                        tooltip: 'Launch class website',
                        color: context.semanticColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!Responsive.isMobile(context)) ...[
                    PrintHidden(
                      child: HeliumIconButton(
                        onPressed: () => _onEdit(course),
                        icon: Icons.edit_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PrintHidden(
                    child: HeliumIconButton(
                      onPressed: () {
                        showConfirmDeleteDialog(
                          parentContext: context,
                          item: course,
                          label: course.title,
                          additionalWarning:
                              'Any assignments associated with this class, including attachments and other data, will also be deleted.',
                          onDelete: (c) {
                            context.read<CourseBloc>().add(
                              DeleteCourseEvent(
                                origin: EventOrigin.screen,
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
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course.teacherName.isNotEmpty) ...[
                          SelectableText(
                            course.teacherName,
                            style: AppStyles.headingText(context),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (course.isOnline)
                          Row(
                            children: [
                              Icon(
                                Icons.language,
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
                                'Online',
                                style: AppStyles.standardBodyText(
                                  context,
                                ).copyWith(
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontSize: Responsive.getFontSize(
                                    context,
                                    mobile: 13,
                                    tablet: 14,
                                    desktop: 15,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (course.room.isNotEmpty)
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
                                color: context.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 4),
                              SelectableText(
                                course.room,
                                style: AppStyles.standardBodyText(
                                  context,
                                ).copyWith(
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (categoryCount > 0) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: Responsive.getIconSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 16,
                              ),
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$categoryCount ${categoryCount.plural('category', 'categories')}',
                              style: AppStyles.smallSecondaryText(
                                context,
                              ).copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            if (course.hasWeightedGrading == true) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.balance,
                                size: Responsive.getIconSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 16,
                                ),
                                color: context.colorScheme.onSurface,
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (course.credits > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: Responsive.getIconSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 16,
                              ),
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatCredits(course.credits),
                              style: AppStyles.smallSecondaryText(
                                context,
                              ).copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (attachmentCount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attachment,
                              size: Responsive.getIconSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 16,
                              ),
                              color: context.semanticColors.success.withValues(
                                alpha: 0.9,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$attachmentCount',
                              style: AppStyles.smallSecondaryText(
                                context,
                              ).copyWith(
                                color: context.semanticColors.success.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
                  Expanded(
                    child: SelectableText(
                      '${HeliumDateTime.formatDate(course.startDate)} to ${HeliumDateTime.formatDate(course.endDate)}',
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
                  ),
                  if (reminderCount > 0) ...[
                    Icon(
                      Icons.notifications_outlined,
                      size: Responsive.getIconSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 16,
                      ),
                      color: context.colorScheme.primary.withValues(
                        alpha: 0.9,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$reminderCount',
                      style: AppStyles.smallSecondaryText(
                        context,
                      ).copyWith(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              if (course.schedules.any(
                (schedule) =>
                    schedule.daysOfWeek != '0000000' || schedule.isRotating,
              )) ...[
                const SizedBox(height: 12),

                Column(children: _buildCourseScheduleContainers(course)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCredits(double credits) {
    final formatted = credits % 1 == 0
        ? credits.toInt().toString()
        : credits.toStringAsFixed(1);
    return '$formatted ${credits.plural('credit')}';
  }

  List<Container> _buildCourseScheduleContainers(CourseModel course) {
    final List<Container> containers = [];

    final renderable = course.schedules
        .where((s) => s.daysOfWeek != '0000000' || s.isRotating)
        .toList();
    final ordered = Sort.courseSchedulesForDisplay(renderable);

    for (final schedule in ordered) {
      if (schedule.groupsByTime().isEmpty) {
        continue;
      }

      containers.add(_buildScheduleContainer(schedule, course.color));
    }

    return containers;
  }

  Container _buildScheduleContainer(CourseScheduleModel schedule, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BadgeColors.background(context, color),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BadgeColors.border(context, color)),
      ),
      child: ScheduleSummary(
        schedule: schedule,
        color: color,
        selectable: true,
      ),
    );
  }

  void _onEdit(CourseModel course) {
    showCourseAdd(
      context,
      courseGroupId: course.courseGroup,
      courseId: course.id,
      isNew: false,
    );
  }

  String _courseLoadBucket(int count) {
    if (count <= 1) return '1';
    if (count <= 3) return '2_3';
    if (count <= 5) return '4_5';
    return '6_plus';
  }

  void _saveSelectedGroup() {
    if (_selectedGroupId == null) return;

    ScreenDropdownFilterHelpers.save(
      ScreensDropdownFilterPrefKey.coursesGroupId,
      _selectedGroupId!,
      userSettings,
    );
  }

  void _restoreSelectedGroup(UserSettingsModel settings) {
    final savedGroupId = ScreenDropdownFilterHelpers.restore(
      ScreensDropdownFilterPrefKey.coursesGroupId,
      settings,
    );
    if (savedGroupId == null) return;

    setState(() {
      _selectedGroupId = savedGroupId;
    });
  }

  /// Fires on the same inactivity-resume threshold that makes the shell clear
  /// the saved selection — but a screen that's currently mounted (i.e. the
  /// user was sitting on it when they backgrounded/foregrounded) won't
  /// otherwise pick that up, since restoring only happens on mount.
  void _resetSelectedGroupOnResume() {
    if (!mounted) return;

    setState(() {
      _selectedGroupId = CourseGroupHelpers.currentGroupId(_courseGroups);
    });
  }
}
