// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:helium_mobile/config/app_routes.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/core/jwt_utils.dart';
import 'package:helium_mobile/data/sources/push_notification_remote_data_source.dart';
import 'package:helium_mobile/data/models/notification/fcm_token_model.dart';
import 'package:helium_mobile/data/models/notification/notification_model.dart';
import 'package:helium_mobile/data/models/notification/push_token_request_model.dart';
import 'package:helium_mobile/data/repositories/push_notification_repository_impl.dart';
import 'package:helium_mobile/helium_mobile.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class FcmService {
  static final FcmService _instance = FcmService._internal();

  factory FcmService() => _instance;

  FcmService._internal();

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

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  // Getters
  String? get fcmToken => _fcmToken;

  bool get isInitialized => _isInitialized;

  // Initialize FCM
  Future<void> init() async {
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
      await _registerToken();

      _isInitialized = true;
      log.info(
        '✅ FCM Service initialized successfully*************************************',
      );
    } catch (e) {
      log.info('❌ FCM Service initialization failed: $e');
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
      description: 'Notifications for Helium app',
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

    log.info(
      '📱 Notification permission status: ${settings.authorizationStatus}',
    );
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
    } catch (e) {
      log.info('❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _registerToken({bool force = false}) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      log.info(
        '⚠️ No FCM token available for registration*********************************',
      );
      return;
    }

    try {
      // Load persisted identifiers
      final storedDeviceId = await secureStorage.read(key: 'helium_device_id');
      final storedToken = await secureStorage.read(
        key: 'helium_last_fcm_token',
      );

      // Reuse a stable deviceId across runs; generate once if missing
      _deviceId = storedDeviceId ?? _fcmToken!.substring(0, 30);

      final pushTokenRepo = PushNotificationRepositoryImpl(
        remoteDataSource: PushNotificationRemoteDataSourceImpl(
          dioClient: DioClient(),
        ),
      );

      final bool tokenUnchanged =
          storedToken != null && storedToken == _fcmToken;

      // Get user ID from token
      final accessToken = await secureStorage.read(key: 'access_token');
      final userId = JwtUtils.getUserId(accessToken!);

      Future<bool> cleanExistingTokens() async {
        bool hasCurrent = false;
        try {
          final existingTokens = await pushTokenRepo.retrievePushTokens(
            userId!,
          );
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
              log.info('🧹 Removed stale push token ID: ${token.id}');
            } catch (e) {
              log.info('⚠️ Failed to delete stale push token ${token.id}: $e');
            }
          }
        } catch (e) {
          log.info('⚠️ Failed to sweep existing push tokens: $e');
        }
        return hasCurrent;
      }

      if (tokenUnchanged) {
        final hasCurrentToken = await cleanExistingTokens();
        if (hasCurrentToken && !force) {
          log.info('ℹ️ FCM token unchanged; skipping push token registration');
          return;
        }
        if (hasCurrentToken && force) {
          log.info(
            'ℹ️ FCM token unchanged; forced re-registration will refresh token',
          );
        }
      }

      log.info('📱 Registering FCM token with Helium API...');
      log.info('👤 User ID: $userId');
      log.info('📱 Device ID: $_deviceId');
      log.info('📱 Device ID length: ${_deviceId!.length}');
      log.info('🔑 FCM Token length: ${_fcmToken!.length}');

      await cleanExistingTokens();

      final request = PushTokenRequestModel(
        deviceId: _deviceId!,
        token: _fcmToken!,
        user: userId!,
        type: Platform.isIOS ? 'ios' : 'android',
      );

      await pushTokenRepo.registerPushToken(request);
      log.info('✅ FCM token registered with Helium API successfully');

      // Persist identifiers
      await secureStorage.write(key: 'helium_device_id', value: _deviceId!);
      await secureStorage.write(
        key: 'helium_last_fcm_token',
        value: _fcmToken!,
      );
    } catch (e) {
      log.info(' Failed to register FCM token with Helium API: $e');
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
    log.info(' Helium Foreground message received: ${message.messageId}');
    log.info(' Message data: ${message.data}');
    log.info(' Notification: ${message.notification}');

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
      log.info(
        '⏱️ Skipping duplicate foreground notification within dedupe window',
      );
      return;
    }
    _recentMessageIds[key] = now;

    final notification = NotificationModel(
      notificationId:
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Helium Reminder',
      body: message.notification?.body ?? 'You have a new reminder.',
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      type: message.data['type'] ?? 'reminder',
      action: message.data['action'] ?? 'view_reminder',
    );

    await showLocalNotification(notification);
    log.info(' Helium foreground notification displayed');
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    log.info(' Helium Notification tapped: ${message.messageId}');
    log.info(' Notification data: ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      log.info(' App opened from terminated state via notification');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    log.info(' Helium Navigation data: $data');
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final dynamic rawType = data['type'];
    final typeString = rawType?.toString() ?? '';
    if (typeString.isEmpty) {
      log.info(' Unknown notification type: $rawType');
    }

    Navigator.of(context).pushNamed(AppRoutes.notificationScreen);
  }

  // Show local notification
  Future<void> showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'helium_notifications',
          'Helium Notifications',
          channelDescription: 'Notifications for Helium app',
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
    log.info(' Local notification tapped: ${response.payload}');
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
    log.info(' All notifications cleared');
  }

  Future<void> registerToken({bool force = false}) async {
    await _registerToken(force: force);
  }

  String? get deviceId => _deviceId;

  Future<void> clearNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
    log.info(' Notification $notificationId cleared');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log.info(' Helium Background message received: ${message.messageId}');
  log.info(' Message data: ${message.data}');
  log.info(' Notification: ${message.notification}');
  if (message.notification == null) {
    final notification = NotificationModel(
      notificationId:
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Helium Reminder',
      body: 'You have a new reminder.',
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      type: message.data['type'] ?? 'reminder',
      action: message.data['action'] ?? 'view_reminder',
    );
    final fcmService = FcmService();
    await fcmService.showLocalNotification(notification);
    log.info('✅ Helium background notification displayed (local only)');
  } else {
    log.info('ℹ️ System notification already handled by FCM (skipping local)');
  }
}
