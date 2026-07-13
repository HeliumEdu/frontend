// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/utils/color_helpers.dart';
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
import 'package:heliumapp/presentation/ui/components/pill_badge.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_card_grid.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
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
  String? _screenError;

  @override
  void initState() {
    super.initState();

    context.read<CourseBloc>().add(
      FetchCoursesScreenDataEvent(origin: EventOrigin.screen),
    );
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
            setState(() { isLoading = false; _screenError = state.message; });
          } else if (state is CoursesScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is CourseGroupCreated) {
            showSnackBar(context, 'Class group created.');

            setState(() {
              _courseGroups.add(state.courseGroup);
              Sort.byStartDate(_courseGroups);
              _selectedGroupId = state.courseGroup.id;
              _coursesMap[_selectedGroupId!] = [];
            });
          } else if (state is CourseGroupUpdated) {
            // No snackbar on updates

            setState(() {
              _courseGroups[_courseGroups.indexWhere(
                    (g) => g.id == state.courseGroup.id,
                  )] =
                  state.courseGroup;
              Sort.byStartDate(_courseGroups);
            });
          } else if (state is CourseGroupDeleted) {
            showSnackBar(context, 'Class group deleted.');

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
            final totalCourses = _coursesMap.values.fold<int>(0, (sum, c) => sum + c.length);
            unawaited(AnalyticsService().setUserProperty(
              name: 'course_load_bucket',
              value: _courseLoadBucket(totalCourses),
            ));
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

            showSnackBar(context, 'Class deleted.');

            setState(() {
              _coursesMap[_selectedGroupId]!.removeWhere(
                (c) => c.id == state.id,
              );
              Sort.byTitle(_coursesMap[_selectedGroupId]!);
            });
            final totalCourses = _coursesMap.values.fold<int>(0, (sum, c) => sum + c.length);
            unawaited(AnalyticsService().setUserProperty(
              name: 'course_load_bucket',
              value: _courseLoadBucket(totalCourses),
            ));
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

        if (_screenError != null) {
          return ErrorCard(
            message: _screenError!,
            source: 'courses_screen',
            onReload: () {
              context.read<CourseBloc>().add(
                FetchCoursesScreenDataEvent(origin: EventOrigin.screen, forceRefresh: true),
              );
            },
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
              hints: {'course_id': course.id},
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
        _selectedGroupId = _courseGroups.first.id;
      }

      isLoading = false;
      _screenError = null;
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

  String _formatCredits(double credits) {
    final formatted = credits % 1 == 0
        ? credits.toInt().toString()
        : credits.toStringAsFixed(1);
    return '$formatted ${credits.plural('credit')}';
  }

  List<Container> _buildCourseScheduleContainers(CourseModel course) {
    final List<Container> containers = [];

    final schedulesByTime = _groupSchedulesByTime(course.schedules);

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
          final timeKey = HeliumTime.formatTimeRange(
            schedule.getStartTimeForDay(activeDays[0]),
            schedule.getEndTimeForDay(activeDays[0]),
          );
          schedulesByTime.putIfAbsent(timeKey, () => []).addAll(activeDays);
        }
      } else {
        for (final day in schedule.getActiveDays()) {
          final timeKey = HeliumTime.formatTimeRange(
            schedule.getStartTimeForDay(day),
            schedule.getEndTimeForDay(day),
          );
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
        color: BadgeColors.background(context, color),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BadgeColors.border(context, color)),
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
              SelectableText(
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
}
