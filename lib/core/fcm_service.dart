import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/data/models/notification/notification_model.dart';
import 'package:heliumedu/data/models/notification/fcm_token_model.dart';
import 'package:heliumedu/data/models/notification/push_token_request_model.dart';
import 'package:heliumedu/data/repositories/push_notification_repository_impl.dart';
import 'package:heliumedu/data/datasources/push_notification_remote_data_source.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;
  String? _deviceId;
  bool _handlersConfigured = false;

  // Dedupe cache for foreground notifications
  final Map<String, DateTime> _recentMessageIds = {};
  final Duration _dedupeWindow = Duration(seconds: 30);

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // Initialize FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission for notifications
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Configure message handlers
      _configureMessageHandlers();

      // Try to register FCM token if user is already logged in
      await _registerTokenWithHeliumEdu();

      _isInitialized = true;
      print(
        '✅ FCM Service initialized successfully*************************************',
      );
    } catch (e) {
      print('❌ FCM Service initialization failed: $e');
      rethrow;
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'helium_notifications',
      'Helium Notifications',
      description: 'Notifications for HeliumEdu app',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Notification permission status: ${settings.authorizationStatus}');
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print(
        '🔑 FCM Token:*************************************************** $_fcmToken...',
      );
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  // Register FCM token with HeliumEdu API
  Future<void> _registerTokenWithHeliumEdu({bool force = false}) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      print(
        '⚠️ No FCM token available for registration*********************************',
      );
      return;
    }

    try {
      // Load persisted identifiers
      final prefs = await SharedPreferences.getInstance();
      final storedDeviceId = prefs.getString('helium_device_id');
      final storedToken = prefs.getString('helium_last_fcm_token');

      // Reuse a stable deviceId across runs; generate once if missing
      _deviceId = storedDeviceId ?? _fcmToken!.substring(0, 30);

      final pushTokenRepo = PushNotificationRepositoryImpl(
        remoteDataSource: PushNotificationRemoteDataSourceImpl(
          dioClient: DioClient(),
        ),
      );

      final bool tokenUnchanged =
          storedToken != null && storedToken == _fcmToken;

      // Get user ID from SharedPreferences
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print('⚠️ No user ID found, skipping token registration');
        return;
      }

      Future<bool> cleanExistingTokens() async {
        bool hasCurrent = false;
        try {
          final existingTokens = await pushTokenRepo.retrievePushTokens(userId);
          for (final token in existingTokens) {
            final bool isCurrentToken = token.token == _fcmToken;
            final bool isCurrentDevice = token.deviceId == _deviceId;

            final bool shouldKeep =
                !hasCurrent && isCurrentToken && isCurrentDevice;
            if (shouldKeep) {
              hasCurrent = true;
              continue;
            }

            try {
              await pushTokenRepo.deletePushTokenById(token.id);
              print('🧹 Removed stale push token ID: ${token.id}');
            } catch (e) {
              print('⚠️ Failed to delete stale push token ${token.id}: $e');
            }
          }
        } catch (e) {
          print('⚠️ Failed to sweep existing push tokens: $e');
        }
        return hasCurrent;
      }

      if (tokenUnchanged) {
        final hasCurrentToken = await cleanExistingTokens();
        if (hasCurrentToken && !force) {
          print('ℹ️ FCM token unchanged; skipping push token registration');
          return;
        }
        if (hasCurrentToken && force) {
          print(
            'ℹ️ FCM token unchanged; forced re-registration will refresh token',
          );
        }
      }

      print('📱 Registering FCM token with HeliumEdu API...');
      print('👤 User ID: $userId');
      print('📱 Device ID: $_deviceId');
      print('📱 Device ID length: ${_deviceId!.length}');
      print('🔑 FCM Token length: ${_fcmToken!.length}');

      await cleanExistingTokens();

      final request = PushTokenRequestModel(
        deviceId: _deviceId!,
        token: _fcmToken!,
        user: userId,
        type: Platform.isIOS ? 'ios' : 'android',
      );

      await pushTokenRepo.registerPushToken(request);
      print('✅ FCM token registered with HeliumEdu API successfully');

      // Persist identifiers
      await prefs.setString('helium_device_id', _deviceId!);
      await prefs.setString('helium_last_fcm_token', _fcmToken!);
    } catch (e) {
      print(' Failed to register FCM token with HeliumEdu API: $e');
      // Don't throw error here as FCM should still work locally
    }
  }

  // Configure message handlers
  void _configureMessageHandlers() {
    if (_handlersConfigured) return;
    _handlersConfigured = true;
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification taps when app is terminated
    _handleInitialMessage();
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print(' HeliumEdu Foreground message received: ${message.messageId}');
    print(' Message data: ${message.data}');
    print(' Notification: ${message.notification}');

    final String contentFingerprint = [
      message.data['id'] ?? '',
      message.data['reminder_id'] ?? '',
      message.data['notification_id'] ?? '',
      message.notification?.title ?? '',
      message.notification?.body ?? '',
    ].join('|');

    final String key = contentFingerprint.trim().isEmpty
        ? '${message.notification?.title ?? ''}|${message.notification?.body ?? ''}'
        : contentFingerprint;

    final now = DateTime.now();
    _recentMessageIds.removeWhere(
      (_, ts) => now.difference(ts) > _dedupeWindow,
    );

    if (_recentMessageIds.containsKey(key)) {
      print(
        '⏱️ Skipping duplicate foreground notification within dedupe window',
      );
      return;
    }
    _recentMessageIds[key] = now;

    final notification = NotificationModel(
      notificationId:
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'HeliumEdu Reminder',
      body: message.notification?.body ?? 'You have a new reminder.',
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      type: message.data['type'] ?? 'reminder',
      action: message.data['action'] ?? 'view_reminder',
    );

    await showLocalNotification(notification);
    print(' HeliumEdu foreground notification displayed');
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print(' HeliumEdu Notification tapped: ${message.messageId}');
    print(' Notification data: ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      print(' App opened from terminated state via notification');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    print(' HeliumEdu Navigation data: $data');
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final dynamic rawType = data['type'];
    final typeString = rawType?.toString() ?? '';
    if (typeString.isEmpty) {
      print(' Unknown notification type: $rawType');
    }

    Navigator.of(context).pushNamed(AppRoutes.notificationScreen);
  }

  // Show local notification
  Future<void> showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'helium_notifications',
          'Helium Notifications',
          channelDescription: 'Notifications for HeliumEdu app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.notificationId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch,
      notification.title,
      notification.body,
      platformDetails,
      payload: notification.data?.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print(' Local notification tapped: ${response.payload}');
    _handleNotificationNavigation({});
  }

  // Get FCM token model
  FCMTokenModel getFCMTokenModel() {
    return FCMTokenModel(
      token: _fcmToken ?? '',
      timestamp: DateTime.now(),
      isActive: true,
    );
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    print(' All notifications cleared');
  }

  Future<void> registerTokenWithHeliumEdu({bool force = false}) async {
    await _registerTokenWithHeliumEdu(force: force);
  }

  String? get deviceId => _deviceId;
  Future<void> clearNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
    print(' Notification $notificationId cleared');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(' HeliumEdu Background message received: ${message.messageId}');
  print(' Message data: ${message.data}');
  print(' Notification: ${message.notification}');
  if (message.notification == null) {
    final notification = NotificationModel(
      notificationId:
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'HeliumEdu Reminder',
      body: 'You have a new reminder.',
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      type: message.data['type'] ?? 'reminder',
      action: message.data['action'] ?? 'view_reminder',
    );
    final fcmService = FCMService();
    await fcmService.showLocalNotification(notification);
    print('✅ HeliumEdu background notification displayed (local only)');
  } else {
    print('ℹ️ System notification already handled by FCM (skipping local)');
  }
}
