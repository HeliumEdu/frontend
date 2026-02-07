// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/reminder_request_model.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_state.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:timezone/standalone.dart' as tz;

/// Shows notifications as a dialog on desktop, or navigates on mobile.
void showNotifications(
  BuildContext context, {
  NotificationArgs? args,
}) {
  if (Responsive.isMobile(context)) {
    context.push(AppRoutes.notificationsScreen, extra: args);
  } else {
    // Try to get CalendarItemBloc from context (may not exist on all screens)
    CalendarItemBloc? calendarItemBloc;
    try {
      calendarItemBloc = context.read<CalendarItemBloc>();
    } catch (_) {
      // CalendarItemBloc not available in this context
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => _NotificationsDialog(
        calendarItemBloc: calendarItemBloc,
      ),
    );
  }
}

class _NotificationsDialog extends StatelessWidget {
  final CalendarItemBloc? calendarItemBloc;

  const _NotificationsDialog({this.calendarItemBloc});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dioClient = DioClient();

    return Dialog(
      alignment: Alignment.centerRight,
      insetPadding: const EdgeInsets.only(
        top: 16,
        bottom: 16,
        right: 16,
        left: 100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 420,
          height: screenHeight - 32,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: BlocProvider(
            create: (context) => ReminderBloc(
              reminderRepository: ReminderRepositoryImpl(
                remoteDataSource: ReminderRemoteDataSourceImpl(
                  dioClient: dioClient,
                ),
              ),
            ),
            child: _NotificationsDialogContent(
              calendarItemBloc: calendarItemBloc,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsDialogContent extends StatefulWidget {
  final CalendarItemBloc? calendarItemBloc;

  const _NotificationsDialogContent({this.calendarItemBloc});

  @override
  State<_NotificationsDialogContent> createState() =>
      _NotificationsDialogContentState();
}

class _NotificationsDialogContentState
    extends State<_NotificationsDialogContent> {
  final PrefService _prefService = PrefService();

  List<NotificationModel> _notifications = [];
  List<int> _readNotificationIds = [];
  bool _isLoading = true;
  tz.Location? _timeZone;

  @override
  void initState() {
    super.initState();

    _prefService.init().then((_) {
      setState(() {
        _readNotificationIds =
            (_prefService.getStringList('read_notification_ids') ?? [])
                .map((n) => HeliumConversion.toInt(n)!)
                .toList();
        final timeZoneStr = _prefService.getString('time_zone');
        if (timeZoneStr != null) {
          _timeZone = tz.getLocation(timeZoneStr);
        }
      });
    });

    context.read<ReminderBloc>().add(
      FetchRemindersEvent(
        origin: EventOrigin.subScreen,
        sent: true,
        dismissed: false,
        type: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications',
                style: AppStyles.pageTitle(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: BlocConsumer<ReminderBloc, ReminderState>(
            listener: (context, state) {
              if (state is RemindersFetched) {
                _populateInitialStateData(state);
              } else if (state is ReminderUpdated) {
                if (state.reminder.dismissed) {
                  setState(() {
                    _notifications.removeWhere((n) => n.id == state.reminder.id);
                  });

                  _readNotificationIds.remove(state.reminder.id);
                  _storeReadNotifications();
                }
              }
            },
            builder: (context, state) {
              if (_isLoading || state is RemindersLoading) {
                return const LoadingIndicator();
              }

              if (state is RemindersError) {
                return ErrorCard(
                  message: state.message!,
                  onReload: () {
                    context.read<ReminderBloc>().add(
                      FetchRemindersEvent(
                        origin: EventOrigin.subScreen,
                        sent: true,
                        dismissed: false,
                        type: 3,
                      ),
                    );
                  },
                );
              }

              if (_notifications.isEmpty) {
                return const EmptyCard(
                  icon: Icons.notifications_off,
                  message: 'Reminders will appear here when they are due',
                );
              }

              return _buildNotificationsList();
            },
          ),
        ),
      ],
    );
  }

  void _populateInitialStateData(RemindersFetched state) {
    final reminders = state.reminders;
    if (_timeZone != null) {
      Sort.byStartOfRange(reminders, _timeZone);
    }

    setState(() {
      _notifications =
          reminders.map((r) => _mapReminderToNotification(r)).toList();
      _isLoading = false;
    });
  }

  NotificationModel _mapReminderToNotification(ReminderModel reminder) {
    final CalendarItemBaseModel? calendarItem;
    final String title;
    final Color? color;
    if (reminder.homework != null) {
      calendarItem = reminder.homework?.entity;
      final course = reminder.homework?.entity?.course.entity;
      title = '${reminder.homework?.entity?.title} in ${course?.title}';
      color = course?.color;
    } else {
      calendarItem = reminder.event?.entity;
      title = reminder.event?.entity?.title as String;
      color = null;
    }

    return NotificationModel(
      id: reminder.id,
      title: title,
      body: reminder.title,
      color: color,
      timestamp: calendarItem!.start,
      isRead: _readNotificationIds.contains(reminder.id),
      reminder: reminder,
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _dismissNotification(notification);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: context.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openNotification(notification);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: notification.isRead
                        ? Colors.transparent
                        : context.colorScheme.primary,
                  ),
                ),
                if (notification.color != null)
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: notification.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppStyles.standardBodyText(context).copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppStyles.standardBodyTextLight(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: AppStyles.standardBodyTextLight(context).copyWith(
                          fontSize: 12,
                          color: context.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNotification(NotificationModel notification) {
    _markAsRead(notification);
    Navigator.of(context).pop();

    // If no CalendarItemBloc available, navigate to the full notifications screen
    if (widget.calendarItemBloc == null) {
      context.push(AppRoutes.notificationsScreen);
      return;
    }

    final int? eventId = notification.reminder.event?.id;
    final int? homeworkId = notification.reminder.homework?.id;

    context.push(
      AppRoutes.plannerItemAddScreen,
      extra: CalendarItemAddArgs(
        calendarItemBloc: widget.calendarItemBloc!,
        eventId: eventId,
        homeworkId: homeworkId,
        isEdit: true,
      ),
    );
  }

  void _markAsRead(NotificationModel notification) {
    if (!notification.isRead) {
      setState(() {
        _readNotificationIds.add(notification.id);
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
      _storeReadNotifications();
    }
  }

  void _dismissNotification(NotificationModel notification) {
    final req = ReminderRequestModel(
      dismissed: true,
      title: notification.title,
      message: notification.body,
      offset: notification.reminder.offset,
      offsetType: notification.reminder.offsetType,
      type: notification.reminder.type,
      sent: notification.reminder.sent,
      homework: notification.reminder.homework?.id,
      event: notification.reminder.event?.id,
    );

    context.read<ReminderBloc>().add(
      UpdateReminderEvent(
        origin: EventOrigin.subScreen,
        id: notification.id,
        request: req,
      ),
    );

    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
  }

  Future<void> _storeReadNotifications() async {
    await _prefService.setStringList(
      'read_notification_ids',
      _readNotificationIds.map((id) => id.toString()).toList(),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (_timeZone != null) {
      final dateTime = HeliumDateTime.parse(timestamp, _timeZone!);
      return HeliumDateTime.formatDateAndTimeForDisplay(dateTime);
    }
    // Fallback if timezone not yet loaded
    return HeliumDateTime.formatDateAndTimeForDisplay(DateTime.parse(timestamp));
  }
}
