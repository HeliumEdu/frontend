import 'package:flutter/material.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';
import 'package:helium_student_flutter/data/models/notification/notification_model.dart';
import 'package:helium_student_flutter/core/fcm_service.dart';
import 'package:helium_student_flutter/data/repositories/reminder_repository_impl.dart';
import 'package:helium_student_flutter/data/datasources/reminder_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/reminder_response_model.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/core/app_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  String _methodLabel(int type) => type == 0 ? 'Email' : 'Push';

  String _typeKey(int type) => type == 0 ? 'email' : 'push';

  DateTime? _parseReminderDate(String? isoString) {
    if (isoString == null) return null;
    try {
      return DateTime.parse(isoString).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatReminderDate(DateTime? dateTime) {
    if (dateTime == null) return 'Scheduled: N/A';
    return 'Scheduled: ${_dateFormatter.format(dateTime)}';
  }

  NotificationModel _mapReminderToNotification(ReminderResponseModel reminder) {
    final scheduledAt = _parseReminderDate(reminder.startOfRange);
    final method = _methodLabel(reminder.type);

    final details = [
      reminder.message,
      'Method: $method',
      _formatReminderDate(scheduledAt),
    ].where((line) => line.trim().isNotEmpty).join('\n');

    return NotificationModel(
      notificationId: reminder.id.toString(),
      title: reminder.title.isNotEmpty ? reminder.title : 'Reminder',
      body: details,
      timestamp: scheduledAt ?? DateTime.now(),
      isRead: false,
      type: _typeKey(reminder.type),
      action: 'view_reminder',
      apiId: reminder.id,
      data: {
        'method': method,
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
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return; // prevent overlapping loads
    try {
      setState(() {
        _isLoading = true;
      });
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      // Load persisted read IDs
      final storedRead = prefs.getStringList('read_notification_ids') ?? [];
      _readNotificationIds = storedRead.toSet();

      if (userId == null) {
        print('⚠️ No user ID found, loading sample notifications');
        _loadSampleNotifications();
        return;
      }

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
        final aDate = _parseReminderDate(a.startOfRange);
        final bDate = _parseReminderDate(b.startOfRange);
        if (aDate == null && bDate == null) {
          return b.id.compareTo(a.id);
        }
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      final reminderNotifications = reminders
          .map(_mapReminderToNotification)
          .map((n) {
            final id = n.notificationId ?? '';
            if (_readNotificationIds.contains(id)) {
              return NotificationModel(
                notificationId: n.notificationId,
                title: n.title,
                body: n.body,
                timestamp: n.timestamp,
                isRead: true,
                type: n.type,
                action: n.action,
                apiId: n.apiId,
                data: n.data,
                imageUrl: n.imageUrl,
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
      // Fallback to sample notifications
      _loadSampleNotifications();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadSampleNotifications() {
    final now = DateTime.now();
    setState(() {
      _notifications = [
        NotificationModel(
          notificationId: 'sample_push',
          title: 'Assignment Reminder',
          body: [
            'Don\'t forget to submit Math Homework.',
            'Method: Push',
            _formatReminderDate(now.add(const Duration(minutes: 45))),
          ].join('\n'),
          timestamp: now.add(const Duration(minutes: 45)),
          isRead: false,
          type: 'push',
          action: 'view_reminder',
        ),
        NotificationModel(
          notificationId: 'sample_email',
          title: 'Email Reminder',
          body: [
            'Weekly status report is due tomorrow morning.',
            'Method: Email',
            _formatReminderDate(now.add(const Duration(hours: 12))),
          ].join('\n'),
          timestamp: now.add(const Duration(hours: 12)),
          isRead: true,
          type: 'email',
          action: 'view_reminder',
        ),
      ];
    });
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
            imageUrl: notification.imageUrl,
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
        backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
              padding: EdgeInsets.symmetric(
                  vertical: 16.v,
                  horizontal: 16.h
              ),
              decoration: BoxDecoration(
                color: whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: blackColor.withOpacity(0.05),
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
                    style: AppTextStyle.bTextStyle.copyWith(
                      color: blackColor,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _loadNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications refreshed'),
                              backgroundColor: Colors.green,
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
                            color: textColor.withOpacity(0.3),
                          ),
                          SizedBox(height: 16.v),
                          Text(
                            'No notifications yet',
                            style: AppTextStyle.eTextStyle.copyWith(
                              color: textColor.withOpacity(0.6),
                              fontSize: 16.fSize,
                            ),
                          ),
                          SizedBox(height: 8.v),
                          Text(
                            'Create a reminder to see notifications here',
                            style: AppTextStyle.fTextStyle.copyWith(
                              color: textColor.withOpacity(0.4),
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
                ).withOpacity(0.1),
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
                  Text(
                    notification.body ?? '',
                    style: AppTextStyle.fTextStyle.copyWith(
                      color: textColor.withOpacity(0.7),
                      fontSize: 12.fSize,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.v),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.adaptSize,
                        color: textColor.withOpacity(0.5),
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        _formatTimestamp(
                          notification.timestamp ?? DateTime.now(),
                        ),
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: textColor.withOpacity(0.5),
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
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: EdgeInsets.all(4.adaptSize),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.adaptSize),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: textColor.withOpacity(0.6),
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
      case 'push':
        return primaryColor;
      case 'email':
        return Colors.orange;
      default:
        return textColor;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'push':
        return Icons.notifications_active;
      case 'email':
        return Icons.mail_outline;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
