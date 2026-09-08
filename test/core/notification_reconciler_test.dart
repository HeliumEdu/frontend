import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/notification_reconciler.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_repositories.dart';

const _channel = MethodChannel('com.heliumedu.heliumapp/native');

ReminderModel _reminder(int id) => ReminderModel(
  id: id,
  message: 'body',
  startOfRange: DateTime.parse('2025-01-15T10:00:00Z'),
  type: 3,
  offset: 30,
  offsetType: 0,
  sent: true,
  dismissed: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReminderRepository repository;
  late NotificationReconciler reconciler;
  late List<String> delivered;
  late List<String>? cleared;

  void whenActiveReminders(List<ReminderModel> reminders) {
    when(
      () => repository.getReminders(
        sent: any(named: 'sent'),
        dismissed: any(named: 'dismissed'),
        type: any(named: 'type'),
        startOfRange: any(named: 'startOfRange'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => reminders);
  }

  setUp(() {
    repository = MockReminderRepository();
    delivered = [];
    cleared = null;

    TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          if (call.method == 'getDeliveredReminderIdentifiers') return delivered;
          if (call.method == 'removeDeliveredNotifications') {
            cleared = List<String>.from(call.arguments['identifiers'] as List);
          }
          return null;
        });

    reconciler = NotificationReconciler.forTesting(
      reminderRepository: repository,
      channel: _channel,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('clears a tray entry whose reminder is no longer active', () async {
    // GIVEN
    delivered = ['reminder_1', 'reminder_2'];
    whenActiveReminders([_reminder(2)]);

    // WHEN
    await reconciler.reconcileForTesting();

    // THEN
    expect(cleared, ['reminder_1']);
  });

  test('clears a tray entry for a reminder un-sent by a reschedule', () async {
    // GIVEN
    delivered = ['reminder_7'];
    whenActiveReminders([]);

    // WHEN
    await reconciler.reconcileForTesting();

    // THEN
    expect(cleared, ['reminder_7']);
  });

  test('leaves a tray entry whose reminder is still active', () async {
    // GIVEN
    delivered = ['reminder_1'];
    whenActiveReminders([_reminder(1)]);

    // WHEN
    await reconciler.reconcileForTesting();

    // THEN
    expect(cleared, isNull);
  });

  test('clears nothing when the active set cannot be fetched', () async {
    // GIVEN
    delivered = ['reminder_1'];
    when(
      () => repository.getReminders(
        sent: any(named: 'sent'),
        dismissed: any(named: 'dismissed'),
        type: any(named: 'type'),
        startOfRange: any(named: 'startOfRange'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenThrow(Exception('offline'));

    // WHEN
    await reconciler.reconcileForTesting();

    // THEN
    expect(cleared, isNull);
  });

  test('does not query the server when the tray is empty', () async {
    // GIVEN
    delivered = [];

    // WHEN
    await reconciler.reconcileForTesting();

    // THEN
    expect(cleared, isNull);
    verifyNever(
      () => repository.getReminders(
        sent: any(named: 'sent'),
        dismissed: any(named: 'dismissed'),
        type: any(named: 'type'),
        startOfRange: any(named: 'startOfRange'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    );
  });
}
