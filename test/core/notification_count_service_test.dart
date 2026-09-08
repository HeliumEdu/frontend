import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/notification_count_service.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_repositories.dart';

ReminderModel _reminder(int id, {int? eventId}) => ReminderModel(
  id: id,
  message: 'body',
  startOfRange: DateTime.parse('2025-01-15T10:00:00Z'),
  type: 3,
  offset: 30,
  offsetType: 0,
  sent: true,
  dismissed: false,
  event: eventId == null ? null : IdOrEntity<EventModel>(id: eventId),
);

ReminderModel _reminderWithoutStartOfRange(int id) => ReminderModel(
  id: id,
  message: 'body',
  startOfRange: null,
  type: 3,
  offset: 30,
  offsetType: 0,
  sent: true,
  dismissed: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReminderRepository repository;
  late NotificationCountService service;

  setUp(() {
    repository = MockReminderRepository();
    service = NotificationCountService.forTesting(
      reminderRepository: repository,
    );
    NotificationCountService.setInstanceForTesting(service);
  });

  tearDown(NotificationCountService.resetForTesting);

  void whenCount(int total) {
    when(
      () => repository.getRemindersCount(
        sent: any(named: 'sent'),
        dismissed: any(named: 'dismissed'),
        type: any(named: 'type'),
        startOfRange: any(named: 'startOfRange'),
      ),
    ).thenAnswer((_) async => total);
  }

  group('count derives from the active list', () {
    test('setActive makes the count the number of renderable rows', () {
      // WHEN
      service.setActive([_reminder(1), _reminder(2), _reminder(3)]);

      // THEN
      expect(service.count.value, 3);
      expect(service.count.value, service.active.value.length);
    });

    test('removing a reminder drops the count with it', () {
      // GIVEN
      service.setActive([_reminder(1), _reminder(2)]);

      // WHEN
      service.remove(1);

      // THEN
      expect(service.active.value.map((r) => r.id), [2]);
      expect(service.count.value, 1);
    });

    test('removeWhere drops the count for every row it takes out', () {
      // GIVEN
      service.setActive([
        _reminder(1, eventId: 10),
        _reminder(2, eventId: 10),
        _reminder(3),
      ]);

      // WHEN
      service.removeWhere((reminder) => reminder.event?.id == 10);

      // THEN
      expect(service.active.value.map((r) => r.id), [3]);
      expect(service.count.value, 1);
    });

    test('a reminder with no startOfRange is not counted, since it is not shown', () {
      // WHEN
      service.setActive([_reminder(1), _reminderWithoutStartOfRange(2)]);

      // THEN
      expect(service.active.value.map((r) => r.id), [1]);
      expect(service.count.value, 1);
    });

    test('clear empties both', () {
      // GIVEN
      service.setActive([_reminder(1), _reminder(2)]);

      // WHEN
      service.clear();

      // THEN
      expect(service.active.value, isEmpty);
      expect(service.count.value, 0);
    });
  });

  group('upsert', () {
    test('adds a pushed reminder and raises the count', () {
      // GIVEN
      service.setActive([_reminder(1)]);

      // WHEN
      service.upsert(_reminder(2));

      // THEN
      expect(service.count.value, 2);
    });

    test('a redelivered reminder replaces rather than double-counts', () {
      // GIVEN
      service.setActive([_reminder(1)]);

      // WHEN
      service.upsert(_reminder(1));
      service.upsert(_reminder(1));

      // THEN
      expect(service.active.value.map((r) => r.id), [1]);
      expect(service.count.value, 1);
    });

    test('a reminder with no startOfRange is ignored', () {
      // GIVEN
      service.setActive([_reminder(1)]);

      // WHEN
      service.upsert(_reminderWithoutStartOfRange(2));

      // THEN
      expect(service.count.value, 1);
    });
  });

  group('an unfetched list', () {
    test('a pushed reminder nudges the count without inventing a list', () {
      // GIVEN
      whenCount(0);

      // WHEN
      service.upsert(_reminder(1));

      // THEN
      expect(service.count.value, 1);
      expect(service.active.value, isEmpty);
    });

    test('a dismiss push nudges the count down but not below zero', () {
      // WHEN
      service.remove(1);

      // THEN
      expect(service.count.value, 0);
    });
  });

  group('staleness', () {
    test('a pushed reminder marks the list for refetch', () {
      // GIVEN
      service.setActive([_reminder(1)]);

      // WHEN
      service.upsert(_reminder(2));

      // THEN
      expect(service.count.value, 2);
      expect(service.isLoaded, isFalse);
    });

    test('an authoritative fetch clears the staleness', () {
      // GIVEN
      service.setActive([_reminder(1)]);
      service.upsert(_reminder(2));

      // WHEN
      service.setActive([_reminder(1), _reminder(2)]);

      // THEN
      expect(service.isLoaded, isTrue);
      expect(service.count.value, 2);
    });
  });

  group('load state', () {
    test('is not loaded until an active set arrives', () {
      // THEN
      expect(service.isLoaded, isFalse);
    });

    test('an empty fetch still counts as loaded', () {
      // WHEN
      service.setActive([]);

      // THEN
      expect(service.isLoaded, isTrue);
      expect(service.count.value, 0);
    });

    test('reset returns to never-loaded so the next open refetches', () {
      // GIVEN
      service.setActive([_reminder(1)]);

      // WHEN
      service.reset();

      // THEN
      expect(service.isLoaded, isFalse);
      expect(service.count.value, 0);
    });
  });

  group('refresh', () {
    test('uses the count query, not the list query', () async {
      // GIVEN
      whenCount(2);

      // WHEN
      await service.refresh();

      // THEN
      expect(service.count.value, 2);
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

    test('a total that disagrees with the list drops it so the screen refetches', () async {
      // GIVEN
      service.setActive([_reminder(1), _reminder(2)]);
      whenCount(5);

      // WHEN
      await service.refresh();

      // THEN
      expect(service.count.value, 5);
      expect(service.isLoaded, isFalse);
    });

    test('a total that agrees with the list keeps it', () async {
      // GIVEN
      service.setActive([_reminder(1), _reminder(2)]);
      whenCount(2);

      // WHEN
      await service.refresh();

      // THEN
      expect(service.isLoaded, isTrue);
      expect(service.active.value.length, 2);
    });

    test('a refresh started before logout cannot repopulate after it', () async {
      // GIVEN
      final gate = Completer<int>();
      when(
        () => repository.getRemindersCount(
          sent: any(named: 'sent'),
          dismissed: any(named: 'dismissed'),
          type: any(named: 'type'),
          startOfRange: any(named: 'startOfRange'),
        ),
      ).thenAnswer((_) => gate.future);
      final inFlight = service.refresh();

      // WHEN
      service.reset();
      gate.complete(4);
      await inFlight;

      // THEN
      expect(service.count.value, 0);
      expect(service.isLoaded, isFalse);
    });

    test('a failed fetch leaves the previous set alone', () async {
      // GIVEN
      service.setActive([_reminder(1)]);
      when(
        () => repository.getRemindersCount(
          sent: any(named: 'sent'),
          dismissed: any(named: 'dismissed'),
          type: any(named: 'type'),
          startOfRange: any(named: 'startOfRange'),
        ),
      ).thenThrow(Exception('offline'));

      // WHEN
      await service.refresh();

      // THEN
      expect(service.count.value, 1);
    });
  });
}
