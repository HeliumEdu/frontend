import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/notification_count_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
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
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/layout/helium_full_screen_scroll_view.dart';
import 'package:heliumapp/presentation/ui/components/generic_label.dart';
import 'package:heliumapp/presentation/ui/components/non_touch_selectable_text.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/error_helpers.dart';

/// Navigates to the notifications route (responsive: side panel on desktop,
/// full-screen on mobile). The route's pageBuilder handles dialog rendering.
Future<void> showNotifications(BuildContext context) async {
  unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.notificationsOpen, parameters: {'category': AnalyticsCategory.featureInteraction.value}));
  await context.push<void>(AppRoute.notificationsScreen);
}

class NotificationsScreen extends StatelessWidget {
  /// Underlying shell tab path (e.g. `/notebook`, `/classes`) the dialog is
  /// overlaying. Used to scope homework/event open-from-notification flows
  /// to the originating shell so the planner-item editor lands there
  /// instead of always on /planner.
  final String shellPath;

  NotificationsScreen({
    super.key,
    this.shellPath = AppRoute.plannerScreen,
  });

  StatefulWidget buildScreen() =>
      _NotificationsProvidedScreen(shellPath: shellPath);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReminderBloc(
            reminderRepository: ReminderRepositoryImpl(
              remoteDataSource: ReminderRemoteDataSourceImpl(
                dioClient: DioClient(),
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
  final String shellPath;

  const _NotificationsProvidedScreen({required this.shellPath});

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
  List<Widget> get additionalRightHeaderButtons {
    final isEnabled = _notifications.isNotEmpty && !_isDismissingAll;

    return [
      Semantics(
        label: 'Dismiss all',
        button: true,
        child: IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          tooltip: 'Dismiss all',
          onPressed: isEnabled ? _dismissAllReminders : null,
          icon: Icon(
            Icons.clear_all,
            color: isEnabled
                ? context.colorScheme.secondary
                : context.colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    ];
  }

  /// Width floor reserved for the notification title so a long course/room
  /// badge stretches only into the space beyond it, never squeezing the title
  /// below this.
  static const double _minTitleWidth = 120.0;

  List<NotificationModel> _notifications = [];
  bool _isOpeningEntity = false;
  bool _isDismissingAll = false;

  @override
  void initState() {
    super.initState();
    NotificationCountService().active.addListener(_onActiveChanged);
  }

  @override
  void dispose() {
    NotificationCountService().active.removeListener(_onActiveChanged);
    super.dispose();
  }

  void _onActiveChanged() {
    if (!mounted) return;
    setState(() => _notifications = _mapActiveToNotifications());

    // A locally-added reminder carries whatever the push payload held, which does
    // not always include its parent; the list endpoint returns it hydrated.
    if (!NotificationCountService().isLoaded) _fetchReminders(forceRefresh: true);
  }

  List<NotificationModel> _mapActiveToNotifications() {
    return NotificationCountService().active.value
        .map(_mapReminderToNotification)
        .toList();
  }

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (mounted && settings != null) {
        if (NotificationCountService().isLoaded) {
          setState(() {
            _notifications = _mapActiveToNotifications();
            isLoading = false;
          });
        } else {
          _fetchReminders();
        }
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
            setState(() {
              _isDismissingAll = false;
              if (state.origin == EventOrigin.screen) isLoading = false;
            });
            if (state.origin != EventOrigin.screen) {
              if (!isShowingErrorCard) {
                showSnackBar(context, state.message!, type: SnackType.error);
              }
            }
          } else if (state is RemindersFetched &&
              state.origin == EventOrigin.screen) {
            _populateInitialStateData(state);
          } else if (state is ReminderUpdated) {
            final reminder = state.reminder;
            final isActive =
                reminder.sent &&
                !reminder.dismissed &&
                reminder.startOfRange != null &&
                !reminder.startOfRange!.isAfter(DateTime.now());

            if (isActive) {
              NotificationCountService().upsert(reminder);
            } else {
              if (reminder.dismissed) {
                showSnackBar(context, 'Reminder dismissed.');
              }
              NotificationCountService().remove(reminder.id);
            }
          } else if (state is ReminderDeleted) {
            NotificationCountService().remove(state.id);
          } else if (state is AllRemindersDismissed) {
            showSnackBar(context, 'All Reminders dismissed.');
            NotificationCountService().clear();
            setState(() => _isDismissingAll = false);
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
          } else if (state is AllEventsDeleted) {
            _removeEventNotifications();
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is RemindersLoading && _notifications.isEmpty) {
          return const LoadingIndicator();
        }

        if (state is RemindersError && state.origin == EventOrigin.screen) {
          return ErrorCard(
            message: state.message!,
            source: 'notification_screen',
            onReload: () => _fetchReminders(forceRefresh: true),
            expanded: true,
          );
        }

        if (_notifications.isEmpty) {
          return Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchReminders(forceRefresh: true),
              color: context.colorScheme.primary,
              child: LayoutBuilder(
                builder: (context, constraints) => HeliumFullScreenScrollView(
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
        origin: EventOrigin.screen,
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
          padding: EdgeInsets.only(
            bottom: HeliumFullScreenScrollView.insetOf(context),
          ),
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
    NotificationCountService().setActive(state.reminders);
    setState(() => isLoading = false);
  }

  void _removeEventNotifications() {
    NotificationCountService().removeWhere(
      (reminder) => reminder.event != null,
    );
  }

  void _removeNotificationByPlannerItemId({int? eventId, int? homeworkId}) {
    NotificationCountService().removeWhere((reminder) {
      if (eventId != null) return reminder.event?.id == eventId;
      if (homeworkId != null) return reminder.homework?.id == homeworkId;
      return false;
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

  NotificationModel _mapReminderToNotification(ReminderModel reminder) {
    final String title;
    final Color? color;
    final String timestamp;

    // Branch on the nested entity, not the `IdOrEntity` wrapper: a reminder PATCH
    // responds with bare parent ids, and mapping has to stay total.
    if (reminder.homework?.entity != null) {
      final homework = reminder.homework!.entity!;
      final course = homework.course.entity;
      final category = homework.category.entity;
      title = homework.title;
      color =
          (userSettings?.colorByCategory == true
              ? category?.color
              : course?.color) ??
          FallbackConstants.fallbackColor;
      timestamp = homework.start.toIso8601String();
    } else if (reminder.event?.entity != null) {
      final event = reminder.event!.entity!;
      title = event.title;
      color =
          userSettings?.eventsColor ??
          FallbackConstants.fallbackColor;
      timestamp = event.start.toIso8601String();
    } else if (reminder.course?.entity != null) {
      final course = reminder.course!.entity!;
      title = course.title;
      color = course.color;
      timestamp = reminder.startOfRange!.toIso8601String();
    } else {
      title = reminder.message;
      color = FallbackConstants.fallbackColor;
      timestamp = reminder.startOfRange!.toIso8601String();
    }

    return NotificationModel(
      id: reminder.id,
      title: title,
      body: reminder.message,
      color: color,
      timestamp: timestamp,
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // The title hugs its content and ellipsizes only when
                        // squeezed; the badge stretches to fill the row but is
                        // capped so the title always keeps at least
                        // [_minTitleWidth].
                        final badgeMaxWidth =
                            (constraints.maxWidth - _minTitleWidth)
                                .clamp(0.0, double.infinity);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                notification.title,
                                style: AppStyles.standardBodyText(context)
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (plannerItem is HomeworkModel &&
                                plannerItem.course.entity != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: badgeMaxWidth,
                                  ),
                                  child: CourseTitleLabel(
                                    title: plannerItem.course.entity!.title,
                                    color: plannerItem.course.entity!.color,
                                    compact: true,
                                  ),
                                ),
                              )
                            else if (notification.reminder.course?.entity !=
                                    null &&
                                notification
                                    .reminder.course!.entity!.room.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: badgeMaxWidth,
                                  ),
                                  child: GenericLabel(
                                    label: notification
                                        .reminder.course!.entity!.room,
                                    color: notification
                                        .reminder.course!.entity!.color,
                                    icon: Icons.pin_drop_outlined,
                                    compact: true,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                          style: AppStyles.smallSecondaryTextLight(context).copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
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
                Builder(
                  builder: (context) {
                    final iconSize = Responsive.getIconSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    );
                    return IconButton(
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.all(4),
                        minimumSize: Size.zero,
                      ),
                      constraints: const BoxConstraints(),
                      tooltip: 'Dismiss reminder',
                      onPressed: () => _dismissReminder(notification),
                      icon: Icon(
                        Icons.close,
                        color:
                            context.colorScheme.secondary.withValues(alpha: 0.7),
                        size: iconSize,
                      ),
                    );
                  },
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
            Icons.close,
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

    try {
      if (!mounted) return;

      final route = reminderEntityRoute(
        courseId: notification.reminder.course?.id,
        homeworkId: notification.reminder.homework?.id,
        eventId: notification.reminder.event?.id,
        shellPath: widget.shellPath,
      );
      if (route == null) return;

      // Close the notifications overlay, then open the entity editor. Defer so
      // the pop completes and GoRouter processes the stack change before the
      // next push — calling router.go synchronously after pop can conflict with
      // GoRouter's async redirect handling.
      if (context.canPop()) context.pop();
      Future.delayed(Duration.zero, () => router.go(route));
    } finally {
      _isOpeningEntity = false;
    }
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

  void _dismissAllReminders() {
    if (_isDismissingAll) return;
    setState(() => _isDismissingAll = true);

    context.read<ReminderBloc>().add(
      DismissAllRemindersEvent(
        origin: EventOrigin.subScreen,
        sent: true,
        type: 3,
        startOfRange: DateTime.now(),
      ),
    );
  }
}
