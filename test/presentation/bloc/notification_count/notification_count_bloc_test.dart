import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/notification_count/notification_count_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/notification_count/notification_count_event.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_repositories.dart';
import '../../../mocks/mock_services.dart';

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
  late NotificationCountBloc bloc;

  setUp(() {
    repository = MockReminderRepository();
    bloc = NotificationCountBloc(
      reminderRepository: repository,
      fcmService: MockFcmService(),
    );
  });

  tearDown(() => bloc.close());

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
    test('setActive makes the count the number of renderable rows', () async {
      // WHEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1), _reminder(2), _reminder(3)],
        ),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 3);
      expect(bloc.state.count, bloc.state.active.length);
    });

    test('removing a reminder drops the count with it', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1), _reminder(2)],
        ),
      );

      // WHEN
      bloc.add(RemoveReminderEvent(origin: EventOrigin.screen, reminderId: 1));

      await pumpEventQueue();

      // THEN
      expect(bloc.state.active.map((r) => r.id), [2]);
      expect(bloc.state.count, 1);
    });

    test('removeWhere drops the count for every row it takes out', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [
            _reminder(1, eventId: 10),
            _reminder(2, eventId: 10),
            _reminder(3),
          ],
        ),
      );

      // WHEN
      bloc.add(
        RemoveRemindersWhereEvent(
          origin: EventOrigin.screen,
          test: (reminder) => reminder.event?.id == 10,
        ),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.active.map((r) => r.id), [3]);
      expect(bloc.state.count, 1);
    });

    test(
      'a reminder with no startOfRange is not counted, since it is not shown',
      () async {
        // WHEN
        bloc.add(
          SetActiveRemindersEvent(
            origin: EventOrigin.screen,
            reminders: [_reminder(1), _reminderWithoutStartOfRange(2)],
          ),
        );

        await pumpEventQueue();

        // THEN
        expect(bloc.state.active.map((r) => r.id), [1]);
        expect(bloc.state.count, 1);
      },
    );

    test('clear empties both', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1), _reminder(2)],
        ),
      );

      // WHEN
      bloc.add(ClearRemindersEvent(origin: EventOrigin.screen));

      await pumpEventQueue();

      // THEN
      expect(bloc.state.active, isEmpty);
      expect(bloc.state.count, 0);
    });
  });

  group('upsert', () {
    test('adds a pushed reminder and raises the count', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1)],
        ),
      );

      // WHEN
      bloc.add(
        UpsertReminderEvent(origin: EventOrigin.screen, reminder: _reminder(2)),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 2);
    });

    test('a redelivered reminder replaces rather than double-counts', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1)],
        ),
      );

      // WHEN
      bloc.add(
        UpsertReminderEvent(origin: EventOrigin.screen, reminder: _reminder(1)),
      );
      bloc.add(
        UpsertReminderEvent(origin: EventOrigin.screen, reminder: _reminder(1)),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.active.map((r) => r.id), [1]);
      expect(bloc.state.count, 1);
    });

    test('a reminder with no startOfRange is ignored', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1)],
        ),
      );

      // WHEN
      bloc.add(
        UpsertReminderEvent(
          origin: EventOrigin.screen,
          reminder: _reminderWithoutStartOfRange(2),
        ),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 1);
    });
  });

  group('an unfetched list', () {
    test(
      'a pushed reminder refetches the count rather than inventing a list',
      () async {
        // GIVEN
        whenCount(3);

        // WHEN
        bloc.add(
          UpsertReminderEvent(
            origin: EventOrigin.screen,
            reminder: _reminder(1),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        await pumpEventQueue();

        // THEN
        expect(bloc.state.count, 3);
        expect(bloc.state.active, isEmpty);
      },
    );

    test('a redelivered push cannot inflate the count', () async {
      // GIVEN
      whenCount(3);

      // WHEN
      bloc.add(
        UpsertReminderEvent(origin: EventOrigin.screen, reminder: _reminder(1)),
      );
      bloc.add(
        UpsertReminderEvent(origin: EventOrigin.screen, reminder: _reminder(1)),
      );
      await Future<void>.delayed(Duration.zero);

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 3);
    });

    test('a dismiss push refetches the count', () async {
      // GIVEN
      whenCount(2);

      // WHEN
      bloc.add(RemoveReminderEvent(origin: EventOrigin.screen, reminderId: 1));
      await Future<void>.delayed(Duration.zero);

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 2);
    });

    test('a dismiss delivered twice cannot double-decrement', () async {
      // GIVEN
      whenCount(2);

      // WHEN
      bloc.add(RemoveReminderEvent(origin: EventOrigin.screen, reminderId: 1));
      bloc.add(RemoveReminderEvent(origin: EventOrigin.screen, reminderId: 1));
      await Future<void>.delayed(Duration.zero);

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 2);
    });
  });

  group('staleness', () {
    test('a pushed reminder marks the list for refetch', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1)],
        ),
      );

      // WHEN
      bloc.add(
        UpsertReminderEvent(origin: EventOrigin.screen, reminder: _reminder(2)),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 2);
      expect(bloc.state.isLoaded, isFalse);
    });

    test('an authoritative fetch clears the staleness', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1)],
        ),
      );
      bloc.add(
        UpsertReminderEvent(origin: EventOrigin.screen, reminder: _reminder(2)),
      );

      // WHEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1), _reminder(2)],
        ),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.isLoaded, isTrue);
      expect(bloc.state.count, 2);
    });
  });

  group('load state', () {
    test('is not loaded until an active set arrives', () async {
      await pumpEventQueue();

      // THEN
      expect(bloc.state.isLoaded, isFalse);
    });

    test('an empty fetch still counts as loaded', () async {
      // WHEN
      bloc.add(
        SetActiveRemindersEvent(origin: EventOrigin.screen, reminders: []),
      );

      await pumpEventQueue();

      // THEN
      expect(bloc.state.isLoaded, isTrue);
      expect(bloc.state.count, 0);
    });

    test('reset returns to never-loaded so the next open refetches', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1)],
        ),
      );

      // WHEN
      bloc.add(ResetNotificationCountEvent());

      await pumpEventQueue();

      // THEN
      expect(bloc.state.isLoaded, isFalse);
      expect(bloc.state.count, 0);
    });
  });

  group('refresh', () {
    test('uses the count query, not the list query', () async {
      // GIVEN
      whenCount(2);

      // WHEN
      bloc.add(RefreshNotificationCountEvent(origin: EventOrigin.screen));

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 2);
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

    test(
      'a total that disagrees with the list drops it so the screen refetches',
      () async {
        // GIVEN
        bloc.add(
          SetActiveRemindersEvent(
            origin: EventOrigin.screen,
            reminders: [_reminder(1), _reminder(2)],
          ),
        );
        whenCount(5);

        // WHEN
        bloc.add(RefreshNotificationCountEvent(origin: EventOrigin.screen));

        await pumpEventQueue();

        // THEN
        expect(bloc.state.count, 5);
        expect(bloc.state.isLoaded, isFalse);
      },
    );

    test('a total that agrees with the list keeps it', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1), _reminder(2)],
        ),
      );
      whenCount(2);

      // WHEN
      bloc.add(RefreshNotificationCountEvent(origin: EventOrigin.screen));

      await pumpEventQueue();

      // THEN
      expect(bloc.state.isLoaded, isTrue);
      expect(bloc.state.active.length, 2);
    });

    test(
      'a refresh started before logout cannot repopulate after it',
      () async {
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
        bloc.add(RefreshNotificationCountEvent(origin: EventOrigin.screen));
        await pumpEventQueue();

        // WHEN
        bloc.add(ResetNotificationCountEvent());
        gate.complete(4);

        await pumpEventQueue();

        // THEN
        expect(bloc.state.count, 0);
        expect(bloc.state.isLoaded, isFalse);
      },
    );

    test('a failed fetch leaves the previous set alone', () async {
      // GIVEN
      bloc.add(
        SetActiveRemindersEvent(
          origin: EventOrigin.screen,
          reminders: [_reminder(1)],
        ),
      );
      when(
        () => repository.getRemindersCount(
          sent: any(named: 'sent'),
          dismissed: any(named: 'dismissed'),
          type: any(named: 'type'),
          startOfRange: any(named: 'startOfRange'),
        ),
      ).thenThrow(Exception('offline'));

      // WHEN
      bloc.add(RefreshNotificationCountEvent(origin: EventOrigin.screen));

      await pumpEventQueue();

      // THEN
      expect(bloc.state.count, 1);
    });
  });
}
