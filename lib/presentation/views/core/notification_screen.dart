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
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_state.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_screen.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/category_title_label.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.views');

/// Shows notifications as a dialog on desktop, or navigates on mobile.
void showNotifications(BuildContext context) {
  CalendarItemBloc? calendarItemBloc;
  try {
    calendarItemBloc = context.read<CalendarItemBloc>();
  } catch (_) {
    _log.info('CalendarItemBloc not passed, will create a new one');
  }
  AttachmentBloc? attachmentBloc;
  try {
    attachmentBloc = context.read<AttachmentBloc>();
  } catch (_) {
    _log.info('AttachmentBloc not passed, will create a new one');
  }

  final args = NotificationArgs(
    calendarItemBloc: calendarItemBloc,
    attachmentBloc: attachmentBloc,
  );

  if (Responsive.isMobile(context)) {
    context.push(AppRoutes.notificationsScreen, extra: args);
  } else {
    showScreenAsDialog(
      context,
      child: NotificationsScreen(),
      extra: args,
      width: AppConstants.notificationsDialogWidth,
      alignment: Alignment.centerRight,
      insetPadding: const EdgeInsets.only(
        top: 16,
        bottom: 16,
        right: 16,
        left: 100,
      ),
    );
  }
}

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
  IconData get icon => Icons.notifications;

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
              showSnackBar(context, 'Reminder dismissed');

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
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is RemindersLoading) {
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
          return EmptyCard(
            icon: icon,
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
          return _buildNotificationRow(notification);
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
      final category = reminder.homework?.entity?.category.entity;

      title = reminder.homework?.entity?.title as String;
      color =
          (userSettings?.colorByCategory == true
              ? category?.color
              : course?.color) ??
          FallbackConstants.fallbackColor;
    } else {
      calendarItem = reminder.event?.entity;
      title = reminder.event?.entity?.title as String;
      color = userSettings?.eventsColor ?? FallbackConstants.fallbackColor;
    }

    return NotificationModel(
      id: reminder.id,
      title: title,
      body: reminder.title,
      color: color,
      timestamp: calendarItem!.start.toIso8601String(),
      isRead: _readNotificationIds.contains(reminder.id),
      reminder: reminder,
    );
  }

  Widget _buildNotificationRow(NotificationModel notification) {
    final CalendarItemBaseModel calendarItem;
    if (notification.reminder.homework != null) {
      calendarItem =
          notification.reminder.homework?.entity as CalendarItemBaseModel;
    } else {
      calendarItem =
          notification.reminder.event?.entity as CalendarItemBaseModel;
    }

    final isTouchDevice = Responsive.isTouchDevice(context);

    final rowContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openNotification(notification),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  height: 48,
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
                    Row(
                      children: [
                        // When course label follows, Text hugs content;
                        // when alone, Flexible allows ellipsis
                        if (calendarItem is HomeworkModel &&
                            calendarItem.course.entity != null)
                          Text(
                            notification.title,
                            style: AppStyles.standardBodyText(context).copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
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
                        if (calendarItem is HomeworkModel &&
                            calendarItem.course.entity != null) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CourseTitleLabel(
                                title: calendarItem.course.entity!.title,
                                color: calendarItem.course.entity!.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppStyles.standardBodyTextLight(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          HeliumDateTime.formatDateTimeRange(
                            HeliumDateTime.toLocal(
                              calendarItem.start,
                              userSettings!.timeZone,
                            ),
                            HeliumDateTime.toLocal(
                              calendarItem.end,
                              userSettings!.timeZone,
                            ),
                            calendarItem.showEndTime,
                            calendarItem.allDay,
                          ),
                          style: AppStyles.standardBodyTextLight(context)
                              .copyWith(
                                fontSize: 12,
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                        ),
                        if (calendarItem is HomeworkModel &&
                            calendarItem.category.entity != null) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CategoryTitleLabel(
                                title: calendarItem.category.entity!.title,
                                color: calendarItem.category.entity!.color,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
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

    if (!mounted) return;

    // Close the dialog first if we're in dialog mode
    if (DialogModeProvider.isDialogMode(context)) {
      Navigator.of(context).pop();
    }

    CalendarItemBloc? calendarItemBloc;
    try {
      calendarItemBloc = context.read<CalendarItemBloc>();
    } catch (_) {
      _log.fine('CalendarItemBloc not in context, creating a new one');
      // Bloc not in context, create one
      calendarItemBloc = ProviderHelpers().createCalendarItemBloc()(context);
    }
    AttachmentBloc? attachmentBloc;
    try {
      attachmentBloc = context.read<AttachmentBloc>();
    } catch (_) {
      _log.fine('AttachmentBloc not in context, creating a new one');
      // Bloc not in context, create one
      attachmentBloc = ProviderHelpers().createAttachmentBloc()(context);
    }

    showCalendarItemAdd(
      context,
      eventId: notification.reminder.event?.id,
      homeworkId: notification.reminder.homework?.id,
      isEdit: true,
      isNew: false,
      calendarItemBloc: calendarItemBloc,
      attachmentBloc: attachmentBloc,
    );
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
