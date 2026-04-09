// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_state.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/generic_label.dart';
import 'package:heliumapp/presentation/ui/components/non_touch_selectable_text.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

/// Shows notifications screen (responsive: side panel on desktop, full-screen on mobile)
Future<void> showNotifications(BuildContext context) {
  unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.notificationsOpen, parameters: {'category': AnalyticsCategory.featureInteraction.value}));
  final currentUri = router.routerDelegate.currentConfiguration.uri;
  final hasDialogParam =
      currentUri.queryParameters.containsKey(DeepLinkParam.dialog);
  final basePath = hasDialogParam ? currentUri.path : null;

  final useCompact = Responsive.useCompactLayout(context);

  final result = showScreenAsDialog(
    context,
    child: NotificationsScreen(),
    width: useCompact ? double.infinity : AppConstants.notificationsDialogWidth,
    alignment: useCompact ? Alignment.center : Alignment.centerRight,
    insetPadding: useCompact
        ? EdgeInsets.zero
        : const EdgeInsets.only(top: 16, bottom: 16, right: 16, left: 100),
  );

  if (basePath != null) {
    return result.then((_) => clearRouteQueryParams(basePath));
  }
  return result;
}

class NotificationsScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  NotificationsScreen({super.key});

  StatefulWidget buildScreen() => const _NotificationsProvidedScreen();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReminderBloc(
            reminderRepository: ReminderRepositoryImpl(
              remoteDataSource: ReminderRemoteDataSourceImpl(
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

class _NotificationsProvidedScreen extends StatefulWidget {
  const _NotificationsProvidedScreen();

  @override
  State<_NotificationsProvidedScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends BasePageScreenState<_NotificationsProvidedScreen> {
  @override
  String get screenTitle => 'Notifications';

  @override
  IconData get icon => Icons.notifications;

  @override
  ScreenType get screenType => ScreenType.subPage;

  @override
  EdgeInsets get scaffoldInsets => const EdgeInsets.all(0);

  final PrefService _prefService = PrefService();

  List<NotificationModel> _notifications = [];
  List<int> _readNotificationIds = [];
  bool _isOpeningEntity = false;

  @override
  void initState() {
    super.initState();

    // Ensure PrefService is initialized
    _prefService.init().then((_) {
      setState(() {
        _readNotificationIds =
            (_prefService.getStringList('read_notification_ids') ?? [])
                .map((n) => toInt(n)!)
                .toList();
      });
    });
  }

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (mounted && settings != null) {
        _fetchReminders();
      }
      return settings;
    });
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is RemindersError) {
            showSnackBar(context, state.message!, type: SnackType.error);
          } else if (state is RemindersFetched) {
            _populateInitialStateData(state);
          } else if (state is ReminderUpdated) {
            final reminder = state.reminder;
            final shouldRemove =
                reminder.dismissed ||
                !reminder.sent ||
                reminder.startOfRange == null ||
                reminder.startOfRange!.isAfter(DateTime.now());

            if (shouldRemove) {
              if (reminder.dismissed) {
                showSnackBar(context, 'Reminder dismissed');
              }
              setState(() {
                _notifications.removeWhere((n) => n.reminder.id == reminder.id);
              });
              _readNotificationIds.remove(reminder.id);
              _storeReadNotifications();
            } else {
              final index = _notifications.indexWhere(
                (n) => n.reminder.id == reminder.id,
              );
              if (index != -1) {
                final notification = _notifications[index];
                setState(() {
                  _notifications[index] = _mapReminderToNotification(
                    reminder,
                    existingColor: notification.color,
                  );
                });
              }
            }
          } else if (state is ReminderDeleted) {
            setState(() {
              _notifications.removeWhere((n) => n.reminder.id == state.id);
            });
            _readNotificationIds.remove(state.id);
            _storeReadNotifications();
          }
        },
      ),
      BlocListener<PlannerItemBloc, PlannerItemState>(
        listener: (context, state) {
          // When homework/event is updated or deleted, remove the notification
          // since the backend may have reset the reminder's sent flag
          if (state is EventUpdated) {
            _removeNotificationByPlannerItemId(eventId: state.event.id);
          } else if (state is EventDeleted) {
            _removeNotificationByPlannerItemId(eventId: state.id);
          } else if (state is HomeworkUpdated) {
            _removeNotificationByPlannerItemId(homeworkId: state.homework.id);
          } else if (state is HomeworkDeleted) {
            _removeNotificationByPlannerItemId(homeworkId: state.id);
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is RemindersLoading) {
          return const LoadingIndicator();
        }

        if (state is RemindersError) {
          return ErrorCard(
            message: state.message!,
            source: 'notification_screen',
            onReload: () => _fetchReminders(forceRefresh: true),
          );
        }

        if (_notifications.isEmpty) {
          return Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchReminders(forceRefresh: true),
              color: context.colorScheme.primary,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: EmptyCard(
                      icon: icon,
                      message:
                          'Reminders will appear here when they are due',
                      expanded: false,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return _buildNotificationsList();
      },
    );
  }

  void _fetchReminders({bool forceRefresh = false}) {
    context.read<ReminderBloc>().add(
      FetchRemindersEvent(
        origin: EventOrigin.subScreen,
        sent: true,
        dismissed: false,
        type: 3,
        startOfRange: DateTime.now(),
        forceRefresh: forceRefresh,
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async => _fetchReminders(forceRefresh: true),
        color: context.colorScheme.primary,
        child: ListView.builder(
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            try {
              final notification = _notifications[index];
              return _buildNotificationRow(notification);
            } catch (e, st) {
              ErrorHelpers.logAndReport(
                'Failed to render notification at index $index',
                e,
                st,
              );
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  void _populateInitialStateData(RemindersFetched state) {
    final reminders = state.reminders;

    final unsupported = reminders.where((r) => r.startOfRange == null).toList();
    for (final r in unsupported) {
      ErrorHelpers.logAndReport(
        'Skipping reminder ${r.id} with null startOfRange',
        Exception('Reminder ${r.id} has null startOfRange'),
        StackTrace.current,
        hints: {'reminder_id': r.id},
      );
    }
    reminders.removeWhere((r) => r.startOfRange == null);

    Sort.byStartOfRange(reminders, userSettings!.timeZone);

    final notifications = <NotificationModel>[];
    for (final r in reminders) {
      try {
        notifications.add(_mapReminderToNotification(r));
      } catch (e, st) {
        ErrorHelpers.logAndReport(
          'Failed to map reminder ${r.id} to notification',
          e,
          st,
          hints: {'reminder_id': r.id},
        );
      }
    }

    setState(() {
      _notifications = notifications;
      isLoading = false;
    });
  }

  void _removeNotificationByPlannerItemId({int? eventId, int? homeworkId}) {
    setState(() {
      _notifications.removeWhere((n) {
        if (eventId != null) return n.reminder.event?.entity?.id == eventId;
        if (homeworkId != null) {
          return n.reminder.homework?.entity?.id == homeworkId;
        }
        return false;
      });
    });
  }

  Duration _offsetToDuration(ReminderModel reminder) {
    switch (reminder.offsetType) {
      case 1:
        return Duration(hours: reminder.offset);
      case 2:
        return Duration(days: reminder.offset);
      case 3:
        return Duration(days: reminder.offset * 7);
      default:
        return Duration(minutes: reminder.offset);
    }
  }

  String _formatCourseScheduleTime(ReminderModel reminder) {
    final course = reminder.course?.entity;

    // Derive the actual class start by adding the offset back to startOfRange,
    // matching the backend's class_start = start_of_range + offset logic.
    final classStartLocal = HeliumDateTime.toLocal(
      reminder.startOfRange!.add(_offsetToDuration(reminder)),
      userSettings!.timeZone,
    );

    if (course == null || course.schedules.isEmpty) {
      return HeliumDateTime.formatDate(classStartLocal);
    }

    final dayIndex = HeliumDateTime.getDayIndex(classStartLocal);

    // Search all schedules for one active on this day.
    final activeSchedule = course.schedules
        .where((s) => s.isDayActive(dayIndex))
        .firstOrNull;

    if (activeSchedule == null) {
      return HeliumDateTime.formatDate(classStartLocal);
    }

    final startTime = activeSchedule.getStartTimeForDayIndex(dayIndex);
    final endTime = activeSchedule.getEndTimeForDayIndex(dayIndex);
    final classStart = DateTime(
      classStartLocal.year,
      classStartLocal.month,
      classStartLocal.day,
      startTime.hour,
      startTime.minute,
    );
    final classEnd = DateTime(
      classStartLocal.year,
      classStartLocal.month,
      classStartLocal.day,
      endTime.hour,
      endTime.minute,
    );
    return HeliumDateTime.formatDateTimeRange(classStart, classEnd, true, false);
  }

  NotificationModel _mapReminderToNotification(
    ReminderModel reminder, {
    Color? existingColor,
  }) {
    final String title;
    final Color? color;
    final String timestamp;

    if (reminder.homework != null) {
      final course = reminder.homework?.entity?.course.entity;
      final category = reminder.homework?.entity?.category.entity;
      title = reminder.homework?.entity?.title as String;
      color =
          existingColor ??
          (userSettings?.colorByCategory == true
              ? category?.color
              : course?.color) ??
          FallbackConstants.fallbackColor;
      timestamp = reminder.homework!.entity!.start.toIso8601String();
    } else if (reminder.event != null) {
      title = reminder.event?.entity?.title as String;
      color =
          existingColor ??
          userSettings?.eventsColor ??
          FallbackConstants.fallbackColor;
      timestamp = reminder.event!.entity!.start.toIso8601String();
    } else if (reminder.course != null) {
      final course = reminder.course?.entity;
      title = course?.title ?? '';
      color = existingColor ?? course?.color ?? FallbackConstants.fallbackColor;
      timestamp = reminder.startOfRange!.toIso8601String();
    } else {
      title = reminder.title;
      color = existingColor ?? FallbackConstants.fallbackColor;
      timestamp = reminder.startOfRange!.toIso8601String();
    }

    return NotificationModel(
      id: reminder.id,
      title: title,
      body: reminder.title,
      color: color,
      timestamp: timestamp,
      isRead: _readNotificationIds.contains(reminder.id),
      reminder: reminder,
    );
  }

  Widget _buildNotificationRow(NotificationModel notification) {
    final PlannerItemBaseModel? plannerItem;
    if (notification.reminder.homework != null) {
      plannerItem = notification.reminder.homework?.entity;
    } else if (notification.reminder.event != null) {
      plannerItem = notification.reminder.event?.entity;
    } else {
      plannerItem = null;
    }

    final isTouchDevice = Responsive.isTouchDevice(context);

    final rowContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openNotification(notification),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.only(top: 6, right: 12.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification.isRead
                      ? Colors.transparent
                      : context.colorScheme.primary,
                ),
              ),
              if (notification.color != null)
                Container(
                  width: 4.0,
                  height: 48.0,
                  margin: const EdgeInsets.only(right: 12.0),
                  decoration: BoxDecoration(
                    color: notification.color,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // When a badge follows, Text hugs content;
                        // when alone, Flexible allows ellipsis
                        if (plannerItem is HomeworkModel &&
                                plannerItem.course.entity != null ||
                            notification.reminder.course?.entity != null &&
                                notification
                                    .reminder.course!.entity!.room.isNotEmpty)
                          Text(
                            notification.title,
                            style: AppStyles.standardBodyText(context).copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Flexible(
                            child: Text(
                              notification.title,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.standardBodyText(context)
                                  .copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                        if (plannerItem is HomeworkModel &&
                            plannerItem.course.entity != null) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CourseTitleLabel(
                                title: plannerItem.course.entity!.title,
                                color: plannerItem.course.entity!.color,
                                compact: true,
                              ),
                            ),
                          ),
                        ] else if (notification.reminder.course?.entity !=
                                null &&
                            notification
                                .reminder.course!.entity!.room.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GenericLabel(
                                label:
                                    notification.reminder.course!.entity!.room,
                                color:
                                    notification.reminder.course!.entity!.color,
                                icon: Icons.pin_drop_outlined,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),
                    NonTouchSelectableText(
                      notification.body,
                      style: AppStyles.standardBodyTextLight(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        NonTouchSelectableText(
                          plannerItem != null
                              ? HeliumDateTime.formatDateTimeRange(
                                  HeliumDateTime.toLocal(
                                    plannerItem.start,
                                    userSettings!.timeZone,
                                  ),
                                  HeliumDateTime.toLocal(
                                    plannerItem.end,
                                    userSettings!.timeZone,
                                  ),
                                  plannerItem.showEndTime,
                                  plannerItem.allDay,
                                )
                              : _formatCourseScheduleTime(
                                  notification.reminder,
                                ),
                          style: AppStyles.standardBodyTextLight(context)
                              .copyWith(
                                fontSize: 12,
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isTouchDevice) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _dismissReminder(notification),
                  icon: Icon(
                    Icons.close,
                    color: context.colorScheme.secondary.withValues(alpha: 0.7),
                    size: Responsive.getIconSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      desktop: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isTouchDevice) {
      return Dismissible(
        key: Key('notification_${notification.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: context.colorScheme.secondary,
          child: Icon(
            Icons.archive_outlined,
            color: context.colorScheme.onSecondary,
          ),
        ),
        confirmDismiss: (direction) async {
          await _dismissReminder(notification);
          return false;
        },
        child: rowContent,
      );
    }

    return rowContent;
  }

  Future<void> _openNotification(NotificationModel notification) async {
    if (_isOpeningEntity) return;
    _isOpeningEntity = true;

    _readNotificationIds.add(notification.id);

    await _storeReadNotifications();

    if (!mounted) return;

    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == notification.id) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            color: n.color,
            timestamp: n.timestamp,
            isRead: true,
            reminder: n.reminder,
          );
        }
        return n;
      }).toList();
    });

    if (!mounted) return;

    // Course reminders: navigate to /classes and open the course editor there.
    final courseId = notification.reminder.course?.id;
    if (courseId != null) {
      Navigator.of(context).pop();
      // Defer navigation so the pop completes and GoRouter processes the stack
      // change before we push the next route; calling router.go synchronously
      // after pop can conflict with GoRouter's async redirect handling
      Future.delayed(Duration.zero, () {
        router.go(
          '${AppRoute.coursesScreen}?${DeepLinkParam.id}=$courseId',
        );
      });
      return;
    }

    // Desktop: close dialog, then set entity param so shell opens the editor.
    if (DialogModeProvider.isDialogMode(context)) {
      final homeworkId = notification.reminder.homework?.id;
      final eventId = notification.reminder.event?.id;
      final basePath = router.routerDelegate.currentConfiguration.uri.path;
      Navigator.of(context).pop();
      // Defer navigation so the pop completes and GoRouter processes the stack
      // change before we push the next route; calling router.replace
      // synchronously after pop can conflict with GoRouter's async redirect
      Future.delayed(Duration.zero, () {
        if (homeworkId != null) {
          router.replace(
            '$basePath?${DeepLinkParam.homeworkId}=$homeworkId',
          );
        } else if (eventId != null) {
          router.replace(
            '$basePath?${DeepLinkParam.eventId}=$eventId',
          );
        }
      });
      return;
    }

    await showPlannerItemAdd(
      context,
      eventId: notification.reminder.event?.id,
      homeworkId: notification.reminder.homework?.id,
      isEdit: true,
      isNew: false,
    );
    _isOpeningEntity = false;
  }

  Future<void> _dismissReminder(NotificationModel notification) async {
    final req = ReminderRequestModel(dismissed: true);

    context.read<ReminderBloc>().add(
      UpdateReminderEvent(
        origin: EventOrigin.subScreen,
        id: notification.id,
        request: req,
      ),
    );
  }

  Future<void> _storeReadNotifications() async {
    await _prefService.setStringList(
      'read_notification_ids',
      _readNotificationIds.map((n) => n.toString()).toList(),
    );
  }
}
