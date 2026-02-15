// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';
import 'dart:io'
    if (dart.library.html) 'package:heliumapp/core/platform_stub.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_web_notifications_stub.dart'
    if (dart.library.html) 'package:heliumapp/core/fcm_web_notifications_web.dart'
    as web_notifications;
import 'package:heliumapp/core/jwt_utils.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/notification/request/push_token_request_model.dart';
import 'package:heliumapp/data/repositories/push_notification_repository_impl.dart';
import 'package:heliumapp/data/sources/push_notification_remote_data_source.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = Logger('core');

class FcmService {
  late final DioClient _dioClient;
  FirebaseMessaging? _firebaseMessaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final PrefService _prefService;

  final Map<String, DateTime> _recentMessageIds = {};
  static const Duration _dedupeWindow = Duration(seconds: 30);

  bool _isInitialized = false;
  bool _isSupported = true;

  bool _handlersConfigured = false;
  String? _fcmToken;

  String? _deviceId;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isSupported => _isSupported;

  static FcmService _instance = FcmService._internal();

  factory FcmService() => _instance;

  FcmService._internal()
    : _dioClient = DioClient(),
      _localNotifications = FlutterLocalNotificationsPlugin(),
      _prefService = PrefService();

  @visibleForTesting
  FcmService.forTesting({
    required DioClient dioClient,
    FirebaseMessaging? firebaseMessaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required PrefService prefService,
  }) : _dioClient = dioClient,
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

    // Check browser support on web BEFORE accessing FirebaseMessaging.instance
    if (kIsWeb) {
      // First check basic browser APIs
      if (!web_notifications.isMessagingSupported()) {
        _log.info('FCM not supported in this browser (missing APIs), skipping initialization');
        _isSupported = false;
        return;
      }
    }

    // Now safe to access FirebaseMessaging.instance
    _firebaseMessaging = FirebaseMessaging.instance;

    // Additional Firebase-level support check for web
    if (kIsWeb) {
      final isSupported = await _firebaseMessaging?.isSupported() ?? false;
      if (!isSupported) {
        _log.info('FCM not supported in this browser (Firebase check), skipping initialization');
        _isSupported = false;
        return;
      }
    }

    try {
      await _initializeNotifications();

      await _requestPermission();

      await _getFCMToken();

      _configureMessageHandlers();

      await _registerToken();

      _isInitialized = true;
      _log.info('FCM initialized successfully');
    } catch (e, s) {
      _log.severe('FCM initialization failed', e, s);
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
    if (_firebaseMessaging == null) return;

    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _log.info(
      'Notification permission status: ${settings.authorizationStatus}',
    );
  }

  Future<void> _getFCMToken() async {
    if (_firebaseMessaging == null) return;

    try {
      // On iOS, ensure APN token is available before getting FCM token
      if (!kIsWeb && Platform.isIOS) {
        try {
          final apnsToken = await _firebaseMessaging!.getAPNSToken();
          if (apnsToken != null) {
            _log.info('APN token retrieved successfully');
          } else {
            _log.warning(
              'APN token is null, FCM token may not be available yet',
            );
          }
        } catch (e) {
          _log.warning('Failed to get APN token', e);
        }
      }

      _fcmToken = await _firebaseMessaging!.getToken();

      if (_fcmToken != null) {
        _log.info('FCM token retrieved successfully');
      }
    } catch (e) {
      _log.fine('FCM token not available', e);
    }
  }

  Future<void> _registerToken({bool force = false}) async {
    // If token is null, try to get it (especially important on iOS where APN may be delayed)
    if (_fcmToken?.isEmpty ?? true) {
      _log.info('FCM token not available, attempting to retrieve it now ...');
      await _getFCMToken();

      // If still null after retry, give up
      if (_fcmToken?.isEmpty ?? true) {
        _log.warning(
          'FCM token still not available after retry, skipping registration',
        );
        return;
      }
    }

    try {
      final storedDeviceId = await _prefService.getSecure(
        'pushtoken_device_id',
      );
      final storedToken = await _prefService.getSecure('last_pushtoken');

      _deviceId = storedDeviceId ?? _fcmToken?.substring(0, 30) ?? '';

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

            // Keep if it's the current token on the current device
            if (isCurrentToken && isCurrentDevice) {
              hasCurrent = true;
              continue;
            }

            // Ignore tokens for other devices
            if (!isCurrentDevice) {
              continue;
            }

            // Delete stale tokens from this device (old or duplicates)
            try {
              await pushTokenRepo.deletePushTokenById(token.id);
              _log.info(
                'Removed stale push token ID: ${token.id} from this device',
              );
            } catch (e) {
              _log.warning('Failed to delete stale push token ${token.id}', e);
            }
          }
        } catch (e) {
          _log.warning('Failed to sweep existing push tokens', e);
        }
        return hasCurrent;
      }

      if (tokenUnchanged) {
        final hasCurrentToken = await cleanExistingTokens();
        if (hasCurrentToken && !force) {
          _log.info('FCM token unchanged; skipping push token registration');
          return;
        }
        if (hasCurrentToken && force) {
          _log.info(
            'FCM token unchanged; forced re-registration will refresh token',
          );
        }
      }

      _log.info(
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
      _log.severe('Failed to register FCM token', e, s);
    }
  }

  void _configureMessageHandlers() {
    if (_handlersConfigured || _firebaseMessaging == null) return;
    _handlersConfigured = true;

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle taps from background
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Handle taps from terminated
    _handleInitialMessage();

    // Listen for token refreshes (important for iOS when APN token becomes available)
    _firebaseMessaging?.onTokenRefresh.listen((newToken) {
      _log.info('FCM token refreshed');
      _fcmToken = newToken;
      _registerToken();
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final messageId = message.messageId ?? 'unknown';
    _log.info('Foreground message $messageId received from FCM');

    if (kDebugMode) {
      if (await _handleTestMessages(message, messageId)) {
        // Return early when test messages are already handled
        return;
      }
    }

    final payload = json.decode(message.data['json_payload']);

    final now = DateTime.now();
    _recentMessageIds.removeWhere(
      (_, ts) => now.difference(ts) > _dedupeWindow,
    );

    if (_recentMessageIds.containsKey(payload['id'].toString())) {
      _log.info('Foreground message $messageId within dedupe window, skipping');
      return;
    }
    _recentMessageIds[payload['id'].toString()] = now;

    final notification = PlannerHelper.mapPayloadToNotification(
      message,
      payload,
    );

    await showLocalNotification(notification);
    _log.info('Foreground message $messageId notification displayed');
  }

  Future<void> _onNotificationTap(RemoteMessage message) async {
    final messageId = message.messageId;
    _log.info('Notification $messageId tapped');
    await router.push(AppRoute.notificationsScreen);
  }

  Future<void> _handleInitialMessage() async {
    if (_firebaseMessaging == null) return;

    final RemoteMessage? initialMessage = await _firebaseMessaging!
        .getInitialMessage();

    if (initialMessage != null) {
      _log.info('App opened from terminated state via notification');
      await router.push(AppRoute.notificationsScreen);
    }
  }

  // Show local notification
  Future<void> showLocalNotification(NotificationModel notification) async {
    if (kIsWeb) {
      // On web, use browser's Notification API directly
      if (await web_notifications.requestWebNotificationPermission()) {
        web_notifications.showWebNotification(
          notification,
          (_) => router.push(AppRoute.notificationsScreen),
        );
      }
      return;
    }

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
      interruptionLevel: InterruptionLevel.active,
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
    _log.info('Local notification tapped: ${response.id}');
    router.push(AppRoute.notificationsScreen);
  }

  Future<void> registerToken({bool force = false}) async {
    await _registerToken(force: force);
  }

  Future<void> unregisterToken() async {
    if (_deviceId == null) {
      _log.info('No device ID available, skipping token unregistration');
      return;
    }

    final pushTokenRepo = PushTokenRepositoryImpl(
      remoteDataSource: PushTokenRemoteDataSourceImpl(dioClient: _dioClient),
    );

    final existingTokens = await pushTokenRepo.retrievePushTokens();

    // Delete existing tokens for this device
    for (final token in existingTokens) {
      if (token.deviceId == _deviceId) {
        await pushTokenRepo.deletePushTokenById(token.id);
        _log.info(
          'Unregistered push token ID: ${token.id} for device $_deviceId',
        );
      }
    }

    // Clear local state
    await _prefService.setSecure('pushtoken_device_id', '');
    await _prefService.setSecure('last_pushtoken', '');
    _fcmToken = null;
    _deviceId = null;

    _log.info('Successfully unregistered push tokens for this device');
  }

  String? get deviceId => _deviceId;

  bool get isInitialized => _isInitialized;

  Future<bool> _handleTestMessages(
    RemoteMessage message,
    String messageId,
  ) async {
    // Handle Firebase Console test messages, which never have a payload
    if (message.data['json_payload'] == null) {
      if (message.notification != null) {
        _log.info(
          'Displaying notification from Firebase console: ${message.toMap()}',
        );

        final title = message.notification?.title ??
                      message.notification?.body ??
                      'Notification';

        final body = message.notification?.body ?? '';

        // Log to Sentry if we had to use fallback values
        if (message.notification?.title == null && message.notification?.body == null) {
          const msg = 'FCM notification has null title and body in test message handler';
          _log.severe(msg);
          await Sentry.captureException(
            Exception(msg),
            stackTrace: StackTrace.current,
            hint: Hint.withMap({'message_id': messageId, 'message_data': message.data}),
          );
        }

        final messageMap = message.toMap();
        messageMap['notification']['title'] = title;

        final remoteMessage = RemoteMessage.fromMap(messageMap);

        final payload = {
          'id': 1,
          'title': title,
          'message': body,
          'start_of_range': DateTime.now().toString(),
          'offset': 30,
          'offset_type': 0,
          'type': 0,
          'sent': true,
          'dismissed': false,
        };

        await showLocalNotification(
          PlannerHelper.mapPayloadToNotification(remoteMessage, payload),
        );
      } else {
        _log.warning(
          'Message $messageId has no payloads, so it will be dropped',
        );
      }

      return true;
    }

    return false;
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    _log.severe('Fireback may fail on devices without Google Play Service', e);
    // Firebase may fail on devices without Google Play Services
    return;
  }

  try {
    final messageId = message.messageId ?? 'unknown';
    _log.info('Background message $messageId received from FCM');

    // Parse the reminder data from the message
    final payload = json.decode(message.data['json_payload']);

    final notification = PlannerHelper.mapPayloadToNotification(
      message,
      payload,
    );

    final fcmService = FcmService();
    await fcmService.showLocalNotification(notification);
    _log.info('Background message $messageId notification displayed');
  } catch (e) {
    _log.severe('Background message processing failed', e);
  }
}
