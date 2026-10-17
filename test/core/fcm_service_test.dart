import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/notification_count/notification_count_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/notification_count/notification_count_event.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_firebase.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/mock_services.dart';

class MockNotificationDetails extends Mock implements NotificationDetails {}

List<ReminderModel> _activeReminders(int count) => List.generate(
  count,
  (index) => ReminderModel(
    id: index + 1,
    message: 'body',
    startOfRange: DateTime.parse('2025-01-15T10:00:00Z'),
    type: 3,
    offset: 30,
    offsetType: 0,
    sent: true,
    dismissed: false,
  ),
);

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
    group('notificationsRoute', () {
      test(
        'resolves to the path-based notifications overlay under planner',
        () {
          // GIVEN/WHEN — the static route consumed by every FCM tap handler
          final route = FcmService.notificationsRoute;

          // THEN
          expect(route, '/planner/notifications');
        },
      );
    });

    group('showLocalNotification', () {
      test('calls localNotifications.show with correct parameters', () async {
        // GIVEN
        final reminder = ReminderModel(
          id: 1,
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
        );

        when(
          () => mockLocalNotifications.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        // WHEN
        await fcmService.showLocalNotification(notification);

        // THEN
        verify(
          () => mockLocalNotifications.show(
            id: 0,
            title: 'Test Title',
            body: 'Test Body',
            notificationDetails: any(named: 'notificationDetails', that: isA<NotificationDetails>()),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });
    });

    group('dismiss message', () {
      late NotificationCountBloc notificationCountBloc;

      setUp(() {
        notificationCountBloc = NotificationCountBloc(
          reminderRepository: MockReminderRepository(),
          fcmService: fcmService,
        );
        notificationCountBloc.add(
          SetActiveRemindersEvent(
            origin: EventOrigin.screen,
            reminders: _activeReminders(3),
          ),
        );
      });

      tearDown(() => notificationCountBloc.close());

      test('drops the dismissed reminder from the active set', () async {
        // GIVEN
        const message = RemoteMessage(
          data: {'action': 'dismiss', 'reminder_id': '2'},
        );

        // WHEN
        await fcmService.handleDismissMessageForTesting(message);
        await pumpEventQueue();

        // THEN
        expect(notificationCountBloc.state.count, 2);
        expect(
          notificationCountBloc.state.active.map((r) => r.id),
          [1, 3],
        );
      });

      test('an echo of the user own dismiss does not double-count', () async {
        // GIVEN
        const message = RemoteMessage(
          data: {'action': 'dismiss', 'reminder_id': '2'},
        );

        // WHEN
        await fcmService.handleDismissMessageForTesting(message);
        await fcmService.handleDismissMessageForTesting(message);
        await pumpEventQueue();

        // THEN
        expect(notificationCountBloc.state.count, 2);
      });

      test('ignores a dismiss missing its reminder_id', () async {
        // GIVEN
        const message = RemoteMessage(data: {'action': 'dismiss'});

        // WHEN
        await fcmService.handleDismissMessageForTesting(message);
        await pumpEventQueue();

        // THEN
        expect(notificationCountBloc.state.count, 3);
      });

      test('a closed bloc stops listening for dismisses', () async {
        // GIVEN
        await notificationCountBloc.close();
        const message = RemoteMessage(
          data: {'action': 'dismiss', 'reminder_id': '2'},
        );

        // WHEN
        await fcmService.handleDismissMessageForTesting(message);
        await pumpEventQueue();

        // THEN
        expect(
          notificationCountBloc.isClosed,
          isTrue,
          reason: 'A dismiss after close must not add to a closed bloc',
        );
      });
    });
  });

}

class MockDioClient extends Mock implements DioClient {}
