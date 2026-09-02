import 'dart:async';
import 'dart:convert';
import 'dart:io'
    if (dart.library.html) 'package:heliumapp/core/platform_stub.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_web_notifications_stub.dart'
    if (dart.library.html) 'package:heliumapp/core/fcm_web_notifications_web.dart'
    as web_notifications;
import 'package:heliumapp/core/jwt_utils.dart';
import 'package:heliumapp/core/notification_count_service.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/notification/request/push_token_request_model.dart';
import 'package:heliumapp/data/repositories/push_notification_repository_impl.dart';
import 'package:heliumapp/data/sources/push_notification_remote_data_source.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

/// The tray slot the FCM SDK posts a reminder under on Android. Foreground
/// posts and dismiss cancels address that same slot, so a redelivery replaces
/// rather than stacks and a dismiss reaches a notification this app posted.
const int _reminderNotificationId = 0;

String _reminderTag(Object reminderId) => 'reminder_$reminderId';

class FcmService with WidgetsBindingObserver {
  late final DioClient _dioClient;
  FirebaseMessaging? _firebaseMessaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final PrefService _prefService;

  final Map<String, DateTime> _recentMessageIds = {};
  static const Duration _dedupeWindow = Duration(seconds: 30);

  /// How long a registration stands before the next launch re-posts it, keeping the server's
  /// purge window measured from the last app open rather than the last sign-in.
  static const Duration _registrationHeartbeat = Duration(hours: 24);

  static void Function(String route)? _onForegroundTap;

  bool _isInitialized = false;
  bool _isSupported = true;

  bool _handlersConfigured = false;
  bool _tokenRegistered = false;
  bool _observingLifecycle = false;
  String? _fcmToken;

  String? _deviceId;

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
    _instance._stopObservingLifecycle();
    _instance = FcmService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(FcmService instance) {
    _instance = instance;
  }

  static void setForegroundTapCallback(void Function(String route) callback) {
    _onForegroundTap = callback;
  }

  @visibleForTesting
  Map<String, DateTime> get recentMessageIdsForTesting => _recentMessageIds;

  @visibleForTesting
  static Duration get dedupeWindowForTesting => _dedupeWindow;

  @visibleForTesting
  Future<void> handleDismissMessageForTesting(RemoteMessage message) =>
      _handleDismissMessage(message);

  Future<void> init() async {
    if (isInitialized) return;

    if (kIsWeb) {
      if (!web_notifications.isMessagingSupported()) {
        _log.info('FCM not supported in this browser (missing APIs), skipping initialization');
        _isSupported = false;
        return;
      }
    }

    try {
      _firebaseMessaging = FirebaseMessaging.instance;
    } catch (e) {
      _log.info('FCM not supported in this browser (instance creation failed)', e);
      _isSupported = false;
      return;
    }

    if (kIsWeb) {
      final isSupported = await _firebaseMessaging?.isSupported() ?? false;
      if (!isSupported) {
        _log.info('FCM not supported in this browser (Firebase check), skipping initialization');
        _isSupported = false;
        return;
      }
    }

    await _initializeNotifications();

    if (!await _requestPermission()) {
      _log.info(
        'FCM not supported in this browser (permission API unavailable), skipping initialization',
      );
      _isSupported = false;
      return;
    }

    await _getFCMToken();

    _configureMessageHandlers();

    _isInitialized = true;
    _log.info('FCM initialized successfully');

    _observeLifecycle();
    unawaited(_registerToken());
  }

  /// A device that cold-starts without a usable network would otherwise stay
  /// unregistered until the OS restarts the app, which can be days.
  void _observeLifecycle() {
    if (_observingLifecycle) return;
    _observingLifecycle = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addObserver(this);
    });
  }

  void _stopObservingLifecycle() {
    if (!_observingLifecycle) return;
    _observingLifecycle = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isSupported && !_tokenRegistered) {
      unawaited(_registerToken());
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
      settings: initializationSettings,
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
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Returns false if the browser's notification permission API is
  /// unavailable (distinct from the user denying permission, which is a
  /// normal [NotificationSettings] response, not a thrown error).
  Future<bool> _requestPermission() async {
    if (_firebaseMessaging == null) return true;

    final NotificationSettings settings;
    try {
      settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      _log.info('Notification permission API unavailable', e);
      return false;
    }

    _log.info(
      'Notification permission status: ${settings.authorizationStatus}',
    );

    // Let FlutterFire present foreground iOS notifications so its swizzled
    // delegate fires onMessage; a native willPresent override would suppress it.
    if (!kIsWeb && Platform.isIOS) {
      await _firebaseMessaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    return true;
  }

  Future<void> _getFCMToken() async {
    if (_firebaseMessaging == null || !_isSupported) return;

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

  Future<void>? _registrationInFlight;

  Future<void> _registerToken({bool force = false}) {
    final inFlight = _registrationInFlight;
    if (inFlight != null && !force) return inFlight;

    final next = inFlight == null
        ? _runRegisterToken(force: force)
        : inFlight.then<void>(
            (_) => _runRegisterToken(force: true),
            onError: (_) => _runRegisterToken(force: true),
          );

    late final Future<void> tracked;
    tracked = next.whenComplete(() {
      if (identical(_registrationInFlight, tracked)) {
        _registrationInFlight = null;
      }
    });
    _registrationInFlight = tracked;
    return tracked;
  }

  Future<void> _runRegisterToken({bool force = false}) async {
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

            if (isCurrentToken && isCurrentDevice) {
              hasCurrent = true;
              continue;
            }

            if (!isCurrentDevice) {
              continue;
            }

            try {
              await pushTokenRepo.deletePushTokenById(token.id);
              _log.info(
                'Removed stale push token ID: ${token.id} from this device',
              );
            } catch (e) {
              _log.warning('Failed to delete stale push token ${token.id}', e);
              unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.debugFcmTokenStaleFail, parameters: {'category': AnalyticsCategory.operational.value}));
            }
          }
        } catch (e) {
          _log.warning('Failed to sweep existing push tokens', e);
        }
        return hasCurrent;
      }

      if (tokenUnchanged) {
        final hasCurrentToken = await cleanExistingTokens();
        final heartbeatDue = await _registrationHeartbeatIsDue();
        if (hasCurrentToken && !force && !heartbeatDue) {
          _log.info('FCM token unchanged; skipping push token registration');
          _tokenRegistered = true;
          return;
        }
        if (hasCurrentToken && force) {
          _log.info(
            'FCM token unchanged; forced re-registration will refresh token',
          );
        } else if (hasCurrentToken && heartbeatDue) {
          _log.info(
            'FCM token unchanged; re-registering to keep the server registration alive',
          );
        }
      }

      _log.info('Registering FCM token for $userId ...');

      await cleanExistingTokens();

      final request = PushTokenRequestModel(
        deviceId: _deviceId!,
        token: _fcmToken!,
      );

      await pushTokenRepo.registerPushToken(request);

      await _prefService.setSecure('pushtoken_device_id', _deviceId!);
      await _prefService.setSecure('last_pushtoken', _fcmToken!);
      await _prefService.setSecure(
        'last_pushtoken_registered_at',
        DateTime.now().toUtc().toIso8601String(),
      );

      _tokenRegistered = true;
    } catch (e, s) {
      // Retried on the next resume, so a single failure isn't actionable.
      _log.warning('Failed to register FCM token', e, s);
    }
  }

  /// A registration with no readable timestamp is due, establishing one on the next post.
  Future<bool> _registrationHeartbeatIsDue() async {
    final registeredAt = await _prefService.getSecure(
      'last_pushtoken_registered_at',
    );
    if (registeredAt == null || registeredAt.isEmpty) {
      return true;
    }

    final lastRegistered = DateTime.tryParse(registeredAt);
    if (lastRegistered == null) {
      return true;
    }

    return DateTime.now().toUtc().difference(lastRegistered) >=
        _registrationHeartbeat;
  }

  void _configureMessageHandlers() {
    if (_handlersConfigured || _firebaseMessaging == null) return;
    _handlersConfigured = true;

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // iOS: APN token may become available after initial FCM setup
    _firebaseMessaging?.onTokenRefresh.listen((newToken) {
      _log.info('FCM token refreshed');
      _fcmToken = newToken;
      _registerToken();
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final messageId = message.messageId ?? 'unknown';
    _log.info('Foreground message $messageId received from FCM');

    if (message.data['action'] == 'dismiss') {
      await _handleDismissMessage(message);
      return;
    }

    if (kDebugMode) {
      if (await _handleTestMessages(message, messageId)) return;
    }

    final notification = _messageToNotification(message);

    final now = DateTime.now();
    _recentMessageIds.removeWhere(
      (_, ts) => now.difference(ts) > _dedupeWindow,
    );

    if (_recentMessageIds.containsKey(notification.id.toString())) {
      _log.info('Foreground message $messageId within dedupe window, skipping');
      unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.debugFcmMessageDeduplicate, parameters: {'category': AnalyticsCategory.operational.value}));
      return;
    }
    _recentMessageIds[notification.id.toString()] = now;

    await showLocalNotification(notification);
    NotificationCountService().increment();
    _log.info('Foreground message $messageId notification displayed');
  }

  /// Clears a reminder's notification in response to a silent
  /// `{action: dismiss, reminder_id}` push (dismissed on another device).
  /// Android cancels the shared reminder tray slot. iOS clears natively in
  /// AppDelegate and web in the service worker, so this only touches the tray
  /// on those platforms.
  ///
  /// The bell count is NOT decremented here: the dismiss push fans out to ALL
  /// devices including the originator, so this handler fires both for cross-device
  /// dismisses AND as an echo of the user's own in-app dismiss. The in-app path
  /// already decrements via the ReminderUpdated listener; decrementing here too
  /// would double-count. The count self-corrects on the next refresh() (resume,
  /// screen open) for cross-device dismisses where the screen was closed.
  Future<void> _handleDismissMessage(RemoteMessage message) async {
    final reminderId = message.data['reminder_id'];
    if (reminderId == null || reminderId.isEmpty) {
      _log.warning('Dismiss message missing reminder_id, ignoring');
      return;
    }

    _log.info('Dismiss received for reminder $reminderId; clearing notification');

    if (kIsWeb) {
      // A foregrounded tab receives dismiss via onMessage, not the SW's
      // onBackgroundMessage, so clear the notification here.
      web_notifications.dismissWebNotification(reminderId);
    } else if (Platform.isAndroid) {
      try {
        await _localNotifications.cancel(
          id: _reminderNotificationId,
          tag: _reminderTag(reminderId),
        );
      } catch (e, s) {
        _log.warning('Failed to clear notification for reminder $reminderId', e, s);
      }
    }
  }

  /// The route a tapped notification is opening, until that route is popped.
  static String? tappedDestination;

  Future<void> _onNotificationTap(RemoteMessage message) async {
    final messageId = message.messageId;
    _log.info('Notification $messageId tapped');

    final route = _routeForMessage(message);
    tappedDestination = route;
    try {
      await router.push(route);
    } finally {
      tappedDestination = null;
    }
  }

  /// Resolves the deep-link route for a tapped push: the specific entity the
  /// reminder is attached to, falling back to the notifications list if the
  /// payload carries no linked entity (or can't be parsed).
  static String _routeForMessage(RemoteMessage message) {
    try {
      return _routeForNotification(_messageToNotification(message));
    } catch (e, s) {
      _log.warning('Failed to resolve entity route for tapped push', e, s);
      return notificationsRoute;
    }
  }

  static String _routeForNotification(NotificationModel notification) {
    final reminder = notification.reminder;
    return reminderEntityRoute(
          courseId: reminder.course?.id,
          homeworkId: reminder.homework?.id,
          eventId: reminder.event?.id,
        ) ??
        notificationsRoute;
  }

  /// Read before the router is built, so a tapped notification is the initial location rather
  /// than a navigation applied over whatever rendered first. Web resolves its own from the URL.
  Future<String?> coldStartRoute() async {
    if (kIsWeb) return null;

    try {
      _firebaseMessaging ??= FirebaseMessaging.instance;

      final RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage == null) return null;

      _log.info('App opened from terminated state via notification');
      return _routeForMessage(initialMessage);
    } catch (e, s) {
      _log.warning('Failed to resolve cold-start route: ${e.runtimeType}', e, s);
      return null;
    }
  }

  /// Posts a reminder to the tray for a push that arrived while the app was
  /// foregrounded. No-op on iOS, where the system presents the notification
  /// itself, filed under the identifier the dismiss handler and the resume
  /// reconciler address.
  Future<void> showLocalNotification(NotificationModel notification) async {
    if (kIsWeb) {
      if (await web_notifications.requestWebNotificationPermission()) {
        final route = _routeForNotification(notification);
        web_notifications.showWebNotification(
          notification,
          (_) {
            if (_onForegroundTap != null) {
              _onForegroundTap!(route);
            } else {
              router.go(route);
            }
          },
        );
      }
      return;
    }

    if (Platform.isIOS) return;

    final NotificationDetails platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'helium',
        'Helium App',
        channelDescription: 'Notifications for Helium',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        tag: _reminderTag(notification.id),
      ),
    );

    await _localNotifications.show(
      id: _reminderNotificationId,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformDetails,
      payload: _routeForNotification(notification),
    );
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    _log.info('Local notification tapped: ${response.id}');

    final payload = response.payload;
    final route = payload != null && payload.isNotEmpty ? payload : notificationsRoute;
    tappedDestination = route;
    try {
      await router.push(route);
    } finally {
      tappedDestination = null;
    }
  }

  Future<void> registerToken({bool force = false}) async {
    await _registerToken(force: force);
  }

  /// Invalidates this device's registration token so the server retires the
  /// registration, for the sign-out paths where [unregisterToken] has no
  /// authenticated channel to reach the API with.
  Future<void> discardToken() async {
    if (_fcmToken == null) return;

    try {
      await _firebaseMessaging?.deleteToken();
      _log.info('Discarded FCM token after forced sign-out');
    } catch (e, s) {
      _log.warning('Failed to discard FCM token', e, s);
    }

    _fcmToken = null;
    _deviceId = null;
    _tokenRegistered = false;
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

    for (final token in existingTokens) {
      if (token.deviceId == _deviceId) {
        await pushTokenRepo.deletePushTokenById(token.id);
        _log.info('Unregistered push token ID: ${token.id}');
      }
    }

    await _prefService.setSecure('pushtoken_device_id', '');
    await _prefService.setSecure('last_pushtoken', '');
    await _prefService.setSecure('last_pushtoken_registered_at', '');
    _fcmToken = null;
    _deviceId = null;
    _tokenRegistered = false;

    _log.info('Successfully unregistered push tokens for this device');
  }

  String? get deviceId => _deviceId;

  bool get isInitialized => _isInitialized;

  @visibleForTesting
  static String get notificationsRoute =>
      '${AppRoute.plannerScreen}${AppRoute.notificationsScreen}';

  static NotificationModel _messageToNotification(RemoteMessage message) {
    final payload = json.decode(message.data['json_payload']);
    return PlannerHelper.mapPayloadToNotification(payload);
  }

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

        final payload = {
          'id': 1,
          'notification_title': title,
          'notification_body': body,
          'start_of_range': DateTime.now().toString(),
          'offset': 30,
          'offset_type': 0,
          'type': 0,
          'sent': true,
          'dismissed': false,
        };

        await showLocalNotification(
          PlannerHelper.mapPayloadToNotification(payload),
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
  // Reminder pushes are displayed natively by the OS, so this handler exists
  // to register the background isolate and to clear a notification on a dismiss
  // push. The count is left to refresh() on resume — this isolate has its own
  // memory, separate from the UI's NotificationCountService.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    _log.severe('Firebase initialization failed in background isolate', e);
    return;
  }

  _log.info('Background message ${message.messageId ?? 'unknown'} received from FCM');

  if (message.data['action'] == 'dismiss' && !kIsWeb && Platform.isAndroid) {
    final reminderId = message.data['reminder_id'];
    if (reminderId == null || reminderId.isEmpty) return;

    try {
      await FlutterLocalNotificationsPlugin().cancel(
        id: _reminderNotificationId,
        tag: _reminderTag(reminderId),
      );
    } catch (e, s) {
      // Method channels aren't guaranteed in the background isolate; a failure
      // is reconciled when the app next resumes.
      _log.warning('Background dismiss clear failed for reminder $reminderId', e, s);
    }
  }
}
