// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/jwt_utils.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/notification/push_token_request_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/repositories/push_notification_repository_impl.dart';
import 'package:heliumapp/data/sources/push_notification_remote_data_source.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class FcmService {
  late final DioClient _dioClient;
  late final FirebaseMessaging _firebaseMessaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final PrefService _prefService;

  final Map<String, DateTime> _recentMessageIds = {};
  static const Duration _dedupeWindow = Duration(seconds: 30);

  bool _isInitialized = false;

  bool _handlersConfigured = false;
  String? _fcmToken;

  String? _deviceId;

  // Getters
  String? get fcmToken => _fcmToken;

  static FcmService _instance = FcmService._internal();

  factory FcmService() => _instance;

  FcmService._internal()
      : _dioClient = DioClient(),
        _firebaseMessaging = FirebaseMessaging.instance,
        _localNotifications = FlutterLocalNotificationsPlugin(),
        _prefService = PrefService();

  @visibleForTesting
  FcmService.forTesting({
    required DioClient dioClient,
    required FirebaseMessaging firebaseMessaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required PrefService prefService,
  })  : _dioClient = dioClient,
        _firebaseMessaging = firebaseMessaging,
        _localNotifications = localNotifications,
        _prefService = prefService;

  @visibleForTesting
  static void resetForTesting() {
    _instance = FcmService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(FcmService instance) {
    _instance = instance;
  }

  @visibleForTesting
  Map<String, DateTime> get recentMessageIdsForTesting => _recentMessageIds;

  @visibleForTesting
  static Duration get dedupeWindowForTesting => _dedupeWindow;

  Future<void> init() async {
    if (isInitialized) return;

    try {
      await _initializeNotifications();

      await _requestPermission();

      await _getFCMToken();

      _configureMessageHandlers();

      await _registerToken();

      _isInitialized = true;
      log.info('FCM initialized successfully');
    } catch (e, s) {
      log.severe('FCM initialization failed', e, s);
      rethrow;
    }
  }

  Future<void> _initializeNotifications() async {
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

    if (!kIsWeb && Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'helium',
      'Helium App',
      description: 'Notifications for Helium',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

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

    log.info('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
    } catch (e) {
      log.info('FCM token not available: $e');
    }
  }

  Future<void> _registerToken({bool force = false}) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      log.info('No FCM token available for registration yet');
      return;
    }

    try {
      final storedDeviceId = await _prefService.getSecure(
        'pushtoken_device_id',
      );
      final storedToken = await _prefService.getSecure('last_pushtoken');

      _deviceId = storedDeviceId ?? _fcmToken!.substring(0, 30);

      final pushTokenRepo = PushTokenRepositoryImpl(
        remoteDataSource: PushTokenRemoteDataSourceImpl(dioClient: _dioClient),
      );

      final bool tokenUnchanged =
          storedToken != null && storedToken == _fcmToken;

      // Get user ID from access token
      final accessToken = await _prefService.getSecure('access_token');
      if (accessToken == null) {
        return;
      }

      final userId = JwtUtils.getUserId(accessToken);

      Future<bool> cleanExistingTokens() async {
        bool hasCurrent = false;
        try {
          final existingTokens = await pushTokenRepo.retrievePushTokens();
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
              log.info('Removed stale push token ID: ${token.id}');
            } catch (e) {
              log.warning('Failed to delete stale push token ${token.id}: $e');
            }
          }
        } catch (e) {
          log.warning('Failed to sweep existing push tokens: $e');
        }
        return hasCurrent;
      }

      if (tokenUnchanged) {
        final hasCurrentToken = await cleanExistingTokens();
        if (hasCurrentToken && !force) {
          log.info('FCM token unchanged; skipping push token registration');
          return;
        }
        if (hasCurrentToken && force) {
          log.info(
            'FCM token unchanged; forced re-registration will refresh token',
          );
        }
      }

      log.info(
        'Registering FCM token with for $userId on device $_deviceId ...',
      );

      await cleanExistingTokens();

      final request = PushTokenRequestModel(
        deviceId: _deviceId!,
        token: _fcmToken!,
      );

      await pushTokenRepo.registerPushToken(request);

      await _prefService.setSecure('pushtoken_device_id', _deviceId!);
      await _prefService.setSecure('last_pushtoken', _fcmToken!);
    } catch (e, s) {
      log.severe('Failed to register FCM token', e, s);
    }
  }

  void _configureMessageHandlers() {
    if (_handlersConfigured) return;
    _handlersConfigured = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle taps from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle taps from terminated
    _handleInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final messageId = message.messageId ?? 'unknown';
    log.info('Foreground message $messageId received from FCM');

    final payload = json.decode(message.data['json_payload']);

    final now = DateTime.now();
    _recentMessageIds.removeWhere(
      (_, ts) => now.difference(ts) > _dedupeWindow,
    );

    if (_recentMessageIds.containsKey(payload['id'].toString())) {
      log.info('Foreground message $messageId within dedupe window, skipping');
      return;
    }
    _recentMessageIds[payload['id'].toString()] = now;

    final reminder = ReminderModel.fromJson(payload);

    final String start;
    if (reminder.homework != null) {
      start = reminder.homework!.entity!.start;
    } else {
      start = reminder.event!.entity!.start;
    }

    final notification = NotificationModel(
      id: reminder.id,
      title: message.notification!.title!,
      body: message.notification!.body!,
      reminder: reminder,
      timestamp: start,
      isRead: false,
    );

    await showLocalNotification(notification);
    log.info('Foreground message $messageId notification displayed');
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final messageId = message.messageId ?? 'unknown';
    log.info('Notification $messageId tapped');
    _handleNotificationNavigation(message.data);
  }

  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      log.info('App opened from terminated state via notification');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    router.push(AppRoutes.notificationsScreen);
  }

  // Show local notification
  Future<void> showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'helium',
          'Helium App',
          channelDescription: 'Notifications for Helium',
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
      notification.id.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    log.info('Local notification tapped: ${response.id}');
    _handleNotificationNavigation({});
  }

  Future<void> registerToken({bool force = false}) async {
    await _registerToken(force: force);
  }

  String? get deviceId => _deviceId;

  bool get isInitialized => _isInitialized;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final messageId = message.messageId ?? 'unknown';
  log.info('Background message $messageId received from FCM');
  if (message.notification == null) {
    final reminder = ReminderModel.fromJson(message.data);

    final String start;
    if (reminder.homework != null) {
      start = reminder.homework!.entity!.start;
    } else {
      start = reminder.event!.entity!.start;
    }

    final notification = NotificationModel(
      id: reminder.id,
      title: message.notification!.title!,
      body: message.notification!.body!,
      reminder: reminder,
      timestamp: start,
      isRead: false,
    );
    final fcmService = FcmService();
    await fcmService.showLocalNotification(notification);
    log.info('Background message $messageId notification displayed');
  } else {
    log.info(
      'Background message $messageId already handled by system, skipping local display',
    );
  }
}
