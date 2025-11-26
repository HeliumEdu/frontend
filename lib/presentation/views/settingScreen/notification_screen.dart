// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:helium_mobile/core/app_exception.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/fcm_service.dart';
import 'package:helium_mobile/data/datasources/auth_remote_data_source.dart';
import 'package:helium_mobile/data/datasources/reminder_remote_data_source.dart';
import 'package:helium_mobile/data/models/notification/notification_model.dart';
import 'package:helium_mobile/data/models/planner/reminder_response_model.dart';
import 'package:helium_mobile/data/repositories/auth_repository_impl.dart';
import 'package:helium_mobile/data/repositories/reminder_repository_impl.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:helium_mobile/utils/app_text_style.dart';
import 'package:helium_mobile/utils/formatting.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FCMService _fcmService = FCMService();
  List<NotificationModel> _notifications = [];
  final DateFormat _dateFormatter = DateFormat('EEE, MMM d • h:mm a');
  bool _isLoading = false;
  Set<String> _readNotificationIds = <String>{};
  bool _isDeleting = false;
  String _timeZone = 'Etc/UTC';

  String _typeKey(int type) => type == 0 ? 'popup' : 'email';

  NotificationModel _mapReminderToNotification(ReminderResponseModel reminder) {
    final scheduledAt = parseDateTime(reminder.startOfRange, _timeZone);

    final String title;
    final Color? color;
    if (reminder.homework != null) {
      title =
          '${reminder.homework!['title']} in ${reminder.homework!['course']['title']}';
      color = parseColor(reminder.homework!['course']['color']);
    } else {
      title = reminder.event!['title'];
      color = null;
    }

    return NotificationModel(
      notificationId: reminder.id.toString(),
      title: title,
      body: reminder.title,
      color: color,
      timestamp: scheduledAt,
      isRead: false,
      type: _typeKey(reminder.type),
      action: 'view_reminder',
      apiId: reminder.id,
      data: {
        'offset': reminder.offset,
        'homework': reminder.homework,
        'event': reminder.event,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadTimeZone();
  }

  Future<void> _loadTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    String? timeZone = prefs.getString('user_time_zone');

    if (timeZone == null || timeZone.isEmpty) {
      try {
        final dioClient = DioClient();
        final authRepository = AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
        );
        final profile = await authRepository.getProfile();
        final timeZone = profile.settings?.timeZone;
        if (timeZone != null && timeZone.trim().isNotEmpty) {
          await prefs.setString('user_time_zone', timeZone);
        }
      } catch (e) {
        print('⚠️ Failed to load time zone from profile: $e');
      }

      if (timeZone == null || timeZone.isEmpty) return;

      if (mounted && timeZone != _timeZone) {
        setState(() {
          _timeZone = timeZone;
        });
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return; // prevent overlapping loads
    try {
      setState(() {
        _isLoading = true;
      });
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      // Load persisted read IDs
      final storedRead = prefs.getStringList('read_notification_ids') ?? [];
      _readNotificationIds = storedRead.toSet();

      final reminderRepo = ReminderRepositoryImpl(
        remoteDataSource: ReminderRemoteDataSourceImpl(dioClient: DioClient()),
      );

      final reminders = await reminderRepo.getReminders();

      if (reminders.isEmpty) {
        print('📅 No reminders available, showing placeholder content');
        setState(() {
          _notifications = [];
        });
        return;
      }

      reminders.sort((a, b) {
        final aDate = parseDateTime(a.startOfRange, _timeZone);
        final bDate = parseDateTime(b.startOfRange, _timeZone);
        if (aDate == null && bDate == null) {
          return b.id.compareTo(a.id);
        }
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      final reminderNotifications = reminders
          .where((r) => (r.sent && !r.dismissed && r.type == 0))
          .map(_mapReminderToNotification)
          .map((n) {
            final id = n.notificationId ?? '';
            if (_readNotificationIds.contains(id)) {
              return NotificationModel(
                notificationId: n.notificationId,
                title: n.title,
                body: n.body,
                color: n.color,
                timestamp: n.timestamp,
                isRead: true,
                type: n.type,
                action: n.action,
                apiId: n.apiId,
                data: n.data,
              );
            }
            return n;
          })
          .toList();

      setState(() {
        _notifications = reminderNotifications;
      });

      print('✅ Loaded ${_notifications.length} reminder notifications');
    } catch (e) {
      print('❌ Failed to load notifications from API: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _markAsRead(String notificationId) {
    _readNotificationIds.add(notificationId);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(
        'read_notification_ids',
        _readNotificationIds.toList(),
      );
    });
    setState(() {
      _notifications = _notifications.map((notification) {
        if (notification.notificationId == notificationId) {
          return NotificationModel(
            notificationId: notification.notificationId,
            title: notification.title,
            body: notification.body,
            timestamp: notification.timestamp,
            isRead: true,
            type: notification.type,
            action: notification.action,
            data: notification.data,
          );
        }
        return notification;
      }).toList();
    });
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
    _fcmService.clearAllNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared'),
        backgroundColor: greenColor,
      ),
    );
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    if (_isDeleting) return;
    _isDeleting = true;
    try {
      if (notification.apiId != null) {
        final reminderRepo = ReminderRepositoryImpl(
          remoteDataSource: ReminderRemoteDataSourceImpl(
            dioClient: DioClient(),
          ),
        );
        await reminderRepo.deleteReminder(notification.apiId!);
      }

      // Remove from local list regardless (non-server items just get cleared locally)
      setState(() {
        _notifications.removeWhere(
          (n) => n.notificationId == notification.notificationId,
        );
      });
      // Also remove its read state
      if (notification.notificationId != null) {
        _readNotificationIds.remove(notification.notificationId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'read_notification_ids',
          _readNotificationIds.toList(),
        );
      }
      // Refresh from server to keep list accurate
      await _loadNotifications();
    } catch (e) {
      // Only show API error message
      String errorMessage = e.toString();
      if (e is AppException) {
        errorMessage = e.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: redColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    _isDeleting = false;
  }

  void _showDeleteConfirmation(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content: Text(
            'Are you sure you want to delete "${notification.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNotification(notification);
              },
              style: TextButton.styleFrom(foregroundColor: redColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGrey,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.v, horizontal: 16.h),
              decoration: BoxDecoration(
                color: whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: blackColor.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: textColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  Text(
                    'Notifications',
                    style: AppTextStyle.bTextStyle.copyWith(color: blackColor),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _loadNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications refreshed'),
                              backgroundColor: greenColor,
                            ),
                          );
                        },
                        icon: Icon(Icons.refresh, color: textColor, size: 20),
                        tooltip: 'Refresh',
                      ),
                      IconButton(
                        onPressed: _clearAllNotifications,
                        icon: Icon(Icons.clear_all, color: textColor, size: 20),
                        tooltip: 'Clear All',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.v),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                      ),
                    )
                  : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64.adaptSize,
                            color: textColor.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: 16.v),
                          Text(
                            'No notifications yet',
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 16.fSize,
                            ),
                          ),
                          SizedBox(height: 8.v),
                          Text(
                            'Create a reminder to see notifications here',
                            style: AppTextStyle.fTextStyle.copyWith(
                              color: textColor.withValues(alpha: 0.4),
                              fontSize: 12.fSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 12.h),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                      separatorBuilder: (context, index) {
                        return SizedBox(height: 12.v);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return GestureDetector(
      onTap: () {
        if (notification.notificationId != null) {
          _markAsRead(notification.notificationId!);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(12.adaptSize),
          border: (notification.isRead == true)
              ? null
              : Border.all(color: primaryColor, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Icon
            Container(
              padding: EdgeInsets.all(8.adaptSize),
              decoration: BoxDecoration(
                color: _getNotificationColor(
                  notification.type,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.adaptSize),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 20.adaptSize,
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title ?? 'Notification',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: (notification.isRead == true)
                                ? FontWeight.w500
                                : FontWeight.w600,
                            fontSize: 14.fSize,
                          ),
                        ),
                      ),
                      if (notification.isRead != true)
                        Container(
                          width: 8.adaptSize,
                          height: 8.adaptSize,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.v),
                  SizedBox(width: 8.h),
                  Row(
                    children: [
                      if (notification.color != null)
                        Container(
                          width: 12.h,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: notification.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      SizedBox(width: 8.v),
                      Text(
                        notification.body ?? '',
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 12.fSize,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.v),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.adaptSize,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        _dateFormatter.format(
                          notification.timestamp ?? DateTime.now(),
                        ),
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 10.fSize,
                        ),
                      ),
                      const Spacer(),

                      SizedBox(width: 8.h),
                      // Delete Menu Button
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmation(notification);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: redColor, size: 18),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: EdgeInsets.all(4.adaptSize),
                          decoration: BoxDecoration(
                            color: greyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.adaptSize),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: textColor.withValues(alpha: 0.6),
                            size: 16.adaptSize,
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
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'popup':
        return primaryColor;
      case 'email':
        return Colors.orange;
      default:
        return textColor;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'popup':
        return Icons.notifications_active;
      case 'email':
        return Icons.mail_outline;
      default:
        return Icons.notifications;
    }
  }
}
