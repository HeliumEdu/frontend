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
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class NotificationsScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();

  NotificationsScreen({super.key});

  StatefulWidget buildScreen() => const NotificationsProvidedScreen();

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

class NotificationsProvidedScreen extends StatefulWidget {
  const NotificationsProvidedScreen({super.key});

  @override
  State<NotificationsProvidedScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends BasePageScreenState<NotificationsProvidedScreen> {
  @override
  String get screenTitle => 'Notifications';

  @override
  ScreenType get screenType => ScreenType.subPage;

  final PrefService _prefService = PrefService();

  List<NotificationModel> _notifications = [];
  List<int> _readNotificationIds = [];

  @override
  void initState() {
    super.initState();

    // Ensure PrefService is initialized
    _prefService.init().then((_) {
      setState(() {
        _readNotificationIds =
            (_prefService.getStringList('read_notification_ids') ?? [])
                .map((n) => HeliumConversion.toInt(n)!)
                .toList();
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
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is RemindersError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is RemindersFetched) {
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
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    // TODO: on larger screens, open notifications as dialog (or preferably sidebar)
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is RemindersLoading) {
          return const LoadingIndicator();
        }

        if (state is RemindersError) {
          return buildReload(state.message!, () {
            context.read<ReminderBloc>().add(
              FetchRemindersEvent(
                origin: EventOrigin.subScreen,
                sent: true,
                dismissed: false,
                type: 3,
              ),
            );
          });
        }

        if (_notifications.isEmpty) {
          return const EmptyCard(
            icon: Icons.notifications_off,
            message: 'Reminders will appear here when they are due',
          );
        }

        return _buildNotificationsList();
      },
    );
  }

  Widget _buildNotificationsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  void _populateInitialStateData(RemindersFetched state) {
    final reminders = state.reminders;
    Sort.byStartOfRange(reminders, userSettings!.timeZone);

    setState(() {
      _notifications = reminders
          .map((r) => _mapReminderToNotification(r))
          .toList();

      isLoading = false;
    });
  }

  NotificationModel _mapReminderToNotification(ReminderModel reminder) {
    final CalendarItemBaseModel? calendarItem;
    final String title;
    final Color? color;
    if (reminder.homework != null) {
      calendarItem = reminder.homework?.entity;
      final course = reminder.homework?.entity?.course.entity;

      // TODO: refactor to use the CourseTitleLabel
      // TODO: refactor to add category information (and use label)

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

  Widget _buildNotificationCard(NotificationModel notification) {
    final CalendarItemBaseModel calendarItem;
    if (notification.reminder.homework != null) {
      calendarItem =
          notification.reminder.homework?.entity as CalendarItemBaseModel;
    } else {
      calendarItem =
          notification.reminder.event?.entity as CalendarItemBaseModel;
    }

    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Feedback.forTap(context);
              _openNotification(notification);
            },
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: (notification.isRead == true)
                    ? Border.all(
                        color: context.colorScheme.outline.withValues(
                          alpha: 0.2,
                        ),
                      )
                    : Border.all(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.2,
                        ),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: context.colorScheme.primary,
                      size: Responsive.getIconSize(
                        context,
                        mobile: 20,
                        tablet: 22,
                        desktop: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: context.eTextStyle.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: (notification.isRead == true)
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  fontSize: Responsive.getFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 15,
                                    desktop: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            if (notification.color != null)
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: notification.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              notification.body,
                              style: context.fTextStyle.copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: Responsive.getFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: Responsive.getIconSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              HeliumDateTime.formatDateTimeRangeForDisplay(
                                HeliumDateTime.parse(
                                  calendarItem.start,
                                  userSettings!.timeZone,
                                ),
                                HeliumDateTime.parse(
                                  calendarItem.end,
                                  userSettings!.timeZone,
                                ),
                                calendarItem.showEndTime,
                                calendarItem.allDay,
                              ),
                              style: context.fTextStyle.copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                                fontSize: Responsive.getFontSize(
                                  context,
                                  mobile: 10,
                                  tablet: 11,
                                  desktop: 12,
                                ),
                              ),
                            ),
                            const Spacer(),

                            const SizedBox(width: 8),

                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'dismiss') {
                                  _dismissReminder(notification);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'dismiss',
                                  height: 30,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.close,
                                        color: context.colorScheme.error,
                                        size: Responsive.getIconSize(
                                          context,
                                          mobile: 16,
                                          tablet: 18,
                                          desktop: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Dismiss'),
                                    ],
                                  ),
                                ),
                              ],
                              tooltip: '',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.more_vert,
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  size: Responsive.getIconSize(
                                    context,
                                    mobile: 16,
                                    tablet: 18,
                                    desktop: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _openNotification(NotificationModel notification) async {
    _readNotificationIds.add(notification.id);

    await _storeReadNotifications();

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

    if (mounted) {
      final int? eventId = notification.reminder.event?.id;
      final int? homeworkId = notification.reminder.homework?.id;

      await context.push(
        AppRoutes.plannerItemAddScreen,
        extra: CalendarItemAddArgs(
          calendarItemBloc: context.read<CalendarItemBloc>(),
          eventId: eventId,
          homeworkId: homeworkId,
          isEdit: true,
        ),
      );
    }
  }

  Future<void> _dismissReminder(NotificationModel notification) async {
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
  }

  Future<void> _storeReadNotifications() async {
    await _prefService.setStringList(
      'read_notification_ids',
      _readNotificationIds.map((n) => n.toString()).toList(),
    );
  }
}
