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
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
          ),
        ).thenAnswer((_) async {});

        // WHEN
        await fcmService.showLocalNotification(notification);

        // THEN
        verify(
          () => mockLocalNotifications.show(
            id: 42.hashCode,
            title: 'Test Title',
            body: 'Test Body',
            notificationDetails: any(named: 'notificationDetails', that: isA<NotificationDetails>()),
          ),
        ).called(1);
      });
    });
  });

}

class MockDioClient extends Mock implements DioClient {}
