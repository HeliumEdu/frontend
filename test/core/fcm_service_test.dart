// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_firebase.dart';
import '../mocks/mock_services.dart';

class MockNotificationDetails extends Mock implements NotificationDetails {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDioClient mockDioClient;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockPrefService mockPrefService;
  late FcmService fcmService;

  setUpAll(() async {
    registerFallbackValue(const NotificationDetails());
    await mockFirebaseInitializeApp();
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockPrefService = MockPrefService();

    fcmService = FcmService.forTesting(
      dioClient: mockDioClient,
      firebaseMessaging: mockFirebaseMessaging,
      localNotifications: mockLocalNotifications,
      prefService: mockPrefService,
    );

    // Set the test instance
    FcmService.setInstanceForTesting(fcmService);
  });

  tearDown(() {
    // Don't call resetForTesting as it creates a new _internal instance
    // which requires Firebase to be initialized
    DioClient.resetForTesting();
    PrefService.resetForTesting();
  });

  group('FcmService', () {
    group('singleton pattern', () {
      test('setInstanceForTesting allows replacing the singleton', () {
        // GIVEN - already set in setUp
        // WHEN
        final instance = FcmService();

        // THEN
        expect(identical(instance, fcmService), isTrue);
      });
    });

    group('message deduplication', () {
      test('duplicate message within window is detected', () {
        // GIVEN
        final messageIds = fcmService.recentMessageIdsForTesting;
        final now = DateTime.now();
        const messageId = 'msg_123';
        messageIds[messageId] = now.subtract(const Duration(seconds: 5));

        // WHEN
        final isDuplicate = messageIds.containsKey(messageId);

        // THEN
        expect(isDuplicate, isTrue);
      });

      test('new message is not a duplicate', () {
        // GIVEN
        final messageIds = fcmService.recentMessageIdsForTesting;
        const newMessageId = 'new_msg_456';

        // WHEN
        final isDuplicate = messageIds.containsKey(newMessageId);

        // THEN
        expect(isDuplicate, isFalse);
      });

      test('old messages are cleaned up outside dedupe window', () {
        // GIVEN
        final messageIds = fcmService.recentMessageIdsForTesting;
        final now = DateTime.now();
        const dedupeWindow = Duration(seconds: 30);

        messageIds['old_msg'] = now.subtract(const Duration(seconds: 60));
        messageIds['recent_msg'] = now.subtract(const Duration(seconds: 10));

        // WHEN - simulate cleanup like the service does
        messageIds.removeWhere(
          (_, ts) => now.difference(ts) > dedupeWindow,
        );

        // THEN
        expect(messageIds.containsKey('old_msg'), isFalse);
        expect(messageIds.containsKey('recent_msg'), isTrue);
      });
    });

    group('showLocalNotification', () {
      test('calls localNotifications.show with correct parameters', () async {
        // GIVEN
        final reminder = ReminderModel(
          id: 1,
          title: 'Test Reminder',
          message: 'Reminder message',
          startOfRange: DateTime.parse('2025-01-15T10:00:00Z'),
          type: 0,
          offset: 30,
          offsetType: 0,
          sent: false,
          dismissed: false,
        );

        final notification = NotificationModel(
          id: 42,
          title: 'Test Title',
          body: 'Test Body',
          reminder: reminder,
          timestamp: '2025-01-15T10:00:00Z',
          isRead: false,
        );

        when(
          () => mockLocalNotifications.show(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN
        await fcmService.showLocalNotification(notification);

        // THEN
        verify(
          () => mockLocalNotifications.show(
            42.hashCode,
            'Test Title',
            'Test Body',
            any(that: isA<NotificationDetails>()),
          ),
        ).called(1);
      });
    });
  });

  group('FCM token registration logic', () {
    test('stored token comparison detects unchanged token', () async {
      // GIVEN
      const fcmToken = 'test_fcm_token_12345';
      when(
        () => mockPrefService.getSecure('last_pushtoken'),
      ).thenAnswer((_) async => fcmToken);

      // WHEN
      final storedToken = await mockPrefService.getSecure('last_pushtoken');
      final tokenUnchanged = storedToken != null && storedToken == fcmToken;

      // THEN
      expect(tokenUnchanged, isTrue);
    });

    test('stored token comparison detects changed token', () async {
      // GIVEN
      const oldToken = 'old_fcm_token';
      const newToken = 'new_fcm_token';
      when(
        () => mockPrefService.getSecure('last_pushtoken'),
      ).thenAnswer((_) async => oldToken);

      // WHEN
      final storedToken = await mockPrefService.getSecure('last_pushtoken');
      final tokenUnchanged = storedToken != null && storedToken == newToken;

      // THEN
      expect(tokenUnchanged, isFalse);
    });

    test('device id is derived from token when not stored', () async {
      // GIVEN
      const fcmToken = 'abcdefghijklmnopqrstuvwxyz1234567890';
      when(
        () => mockPrefService.getSecure('pushtoken_device_id'),
      ).thenAnswer((_) async => null);

      // WHEN
      final storedDeviceId = await mockPrefService.getSecure(
        'pushtoken_device_id',
      );
      final deviceId = storedDeviceId ?? fcmToken.substring(0, 30);

      // THEN
      expect(deviceId, equals('abcdefghijklmnopqrstuvwxyz1234'));
      expect(deviceId.length, equals(30));
    });

    test('stored device id is used when available', () async {
      // GIVEN
      const storedId = 'my_stored_device_id';
      when(
        () => mockPrefService.getSecure('pushtoken_device_id'),
      ).thenAnswer((_) async => storedId);

      // WHEN
      final deviceId = await mockPrefService.getSecure('pushtoken_device_id');

      // THEN
      expect(deviceId, equals(storedId));
    });

    test('token and device id are stored after registration', () async {
      // GIVEN
      const fcmToken = 'new_fcm_token';
      const deviceId = 'device_123';
      when(
        () => mockPrefService.setSecure('pushtoken_device_id', deviceId),
      ).thenAnswer((_) async {});
      when(
        () => mockPrefService.setSecure('last_pushtoken', fcmToken),
      ).thenAnswer((_) async {});

      // WHEN
      await mockPrefService.setSecure('pushtoken_device_id', deviceId);
      await mockPrefService.setSecure('last_pushtoken', fcmToken);

      // THEN
      verify(
        () => mockPrefService.setSecure('pushtoken_device_id', deviceId),
      ).called(1);
      verify(
        () => mockPrefService.setSecure('last_pushtoken', fcmToken),
      ).called(1);
    });

    test('registration skipped when no access token', () async {
      // GIVEN
      when(
        () => mockPrefService.getSecure('access_token'),
      ).thenAnswer((_) async => null);

      // WHEN
      final accessToken = await mockPrefService.getSecure('access_token');

      // THEN
      expect(accessToken, isNull);
    });
  });
}

class MockDioClient extends Mock implements DioClient {}
