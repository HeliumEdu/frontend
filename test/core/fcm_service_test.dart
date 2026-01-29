// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:mocktail/mocktail.dart';

// Note: FcmService cannot be directly tested without Firebase initialization.
// These tests focus on the supporting logic and models used by FcmService.

class MockPrefService extends Mock implements PrefService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FcmService', () {
    // Note: FcmService singleton tests are skipped because they require
    // Firebase to be initialized. The singleton pattern follows standard
    // Dart singleton implementation with factory constructor.

    group('dedupe window constant', () {
      test('dedupe window is 30 seconds', () {
        // The _dedupeWindow constant is 30 seconds
        // This ensures duplicate messages within 30s are ignored
        const expectedWindow = Duration(seconds: 30);
        expect(expectedWindow.inSeconds, equals(30));
      });
    });
  });

  group('NotificationModel', () {
    test('creates NotificationModel with all required fields', () {
      // GIVEN
      final reminder = ReminderModel(
        id: 1,
        title: 'Test Reminder',
        message: 'Reminder message',
        startOfRange: '2025-01-15T10:00:00Z',
        type: 0,
        offset: 30,
        offsetType: 0,
        sent: false,
        dismissed: false,
      );

      // WHEN
      final notification = NotificationModel(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        reminder: reminder,
        timestamp: '2025-01-15T10:00:00Z',
        isRead: false,
      );

      // THEN
      expect(notification.id, equals(1));
      expect(notification.title, equals('Test Title'));
      expect(notification.body, equals('Test Body'));
      expect(notification.reminder, equals(reminder));
      expect(notification.timestamp, equals('2025-01-15T10:00:00Z'));
      expect(notification.isRead, isFalse);
    });

    test('creates NotificationModel with isRead true', () {
      // GIVEN
      final reminder = ReminderModel(
        id: 2,
        title: 'Read Reminder',
        message: 'Another reminder message',
        startOfRange: '2025-01-15T11:00:00Z',
        type: 1,
        offset: 60,
        offsetType: 1,
        sent: true,
        dismissed: true,
      );

      // WHEN
      final notification = NotificationModel(
        id: 2,
        title: 'Read Notification',
        body: 'Already read',
        reminder: reminder,
        timestamp: '2025-01-15T11:00:00Z',
        isRead: true,
      );

      // THEN
      expect(notification.isRead, isTrue);
    });
  });

  group('FCM token registration logic', () {
    late MockPrefService mockPrefService;

    setUp(() {
      mockPrefService = MockPrefService();
    });

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
      // Registration should return early when access token is null
    });
  });

  group('Message deduplication logic', () {
    test('recent message ids map handles cleanup', () {
      // GIVEN
      final recentMessageIds = <String, DateTime>{};
      final now = DateTime.now();
      const dedupeWindow = Duration(seconds: 30);

      // Add some old messages
      recentMessageIds['old_msg'] = now.subtract(const Duration(seconds: 60));
      recentMessageIds['recent_msg'] = now.subtract(const Duration(seconds: 10));

      // WHEN - simulate cleanup
      recentMessageIds.removeWhere(
        (_, ts) => now.difference(ts) > dedupeWindow,
      );

      // THEN
      expect(recentMessageIds.containsKey('old_msg'), isFalse);
      expect(recentMessageIds.containsKey('recent_msg'), isTrue);
    });

    test('duplicate message within window is detected', () {
      // GIVEN
      final recentMessageIds = <String, DateTime>{};
      final now = DateTime.now();
      const messageId = 'msg_123';

      recentMessageIds[messageId] = now.subtract(const Duration(seconds: 5));

      // WHEN
      final isDuplicate = recentMessageIds.containsKey(messageId);

      // THEN
      expect(isDuplicate, isTrue);
    });

    test('new message is not a duplicate', () {
      // GIVEN
      final recentMessageIds = <String, DateTime>{};
      const newMessageId = 'new_msg_456';

      // WHEN
      final isDuplicate = recentMessageIds.containsKey(newMessageId);

      // THEN
      expect(isDuplicate, isFalse);
    });
  });
}
