// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockReminderRepository mockReminderRepository;
  late ReminderBloc reminderBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockReminderRepository = MockReminderRepository();
    reminderBloc = ReminderBloc(reminderRepository: mockReminderRepository);
  });

  tearDown(() {
    reminderBloc.close();
  });

  group('ReminderBloc', () {
    test('initial state is ReminderInitial with bloc origin', () {
      expect(reminderBloc.state, isA<ReminderInitial>());
    });

    group('FetchRemindersEvent', () {
      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersFetched] when fetch succeeds',
        build: () {
          when(
            () => mockReminderRepository.getReminders(
              sent: any(named: 'sent'),
              dismissed: any(named: 'dismissed'),
              type: any(named: 'type'),
              eventId: any(named: 'eventId'),
              homeworkId: any(named: 'homeworkId'),
            ),
          ).thenAnswer((_) async => MockModels.createReminders());
          return reminderBloc;
        },
        act: (bloc) => bloc.add(FetchRemindersEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersFetched>().having(
            (s) => s.reminders.length,
            'reminders length',
            3,
          ),
        ],
        verify: (_) {
          verify(
            () => mockReminderRepository.getReminders(
              sent: null,
              dismissed: null,
              type: null,
              eventId: null,
              homeworkId: null,
            ),
          ).called(1);
        },
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersFetched] with filters applied',
        build: () {
          when(
            () => mockReminderRepository.getReminders(
              sent: true,
              dismissed: false,
              type: 1,
              eventId: 5,
              homeworkId: null,
            ),
          ).thenAnswer((_) async => MockModels.createReminders(count: 1));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          FetchRemindersEvent(
            origin: EventOrigin.screen,
            sent: true,
            dismissed: false,
            type: 1,
            eventId: 5,
          ),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersFetched>().having(
            (s) => s.reminders.length,
            'reminders length',
            1,
          ),
        ],
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] when HeliumException occurs',
        build: () {
          when(
            () => mockReminderRepository.getReminders(
              sent: any(named: 'sent'),
              dismissed: any(named: 'dismissed'),
              type: any(named: 'type'),
              eventId: any(named: 'eventId'),
              homeworkId: any(named: 'homeworkId'),
            ),
          ).thenThrow(ServerException(message: 'Server error'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(FetchRemindersEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] with generic message for unexpected errors',
        build: () {
          when(
            () => mockReminderRepository.getReminders(
              sent: any(named: 'sent'),
              dismissed: any(named: 'dismissed'),
              type: any(named: 'type'),
              eventId: any(named: 'eventId'),
              homeworkId: any(named: 'homeworkId'),
            ),
          ).thenThrow(Exception('Unknown error'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(FetchRemindersEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('CreateReminderEvent', () {
      final request = ReminderRequestModel(
        title: 'New Reminder',
        message: 'Reminder message',
        offset: 15,
        offsetType: 0,
        type: 0,
        sent: false,
        dismissed: false,
        homework: 1,
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, ReminderCreated] when creation succeeds',
        build: () {
          when(
            () => mockReminderRepository.createReminder(any()),
          ).thenAnswer((_) async => MockModels.createReminder(id: 1));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          CreateReminderEvent(origin: EventOrigin.dialog, request: request),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<ReminderCreated>().having(
            (s) => s.reminder.id,
            'reminder id',
            1,
          ),
        ],
        verify: (_) {
          verify(() => mockReminderRepository.createReminder(any())).called(1);
        },
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] when creation fails',
        build: () {
          when(
            () => mockReminderRepository.createReminder(any()),
          ).thenThrow(ValidationException(message: 'Invalid reminder data'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          CreateReminderEvent(origin: EventOrigin.dialog, request: request),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            'Invalid reminder data',
          ),
        ],
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] for unexpected error during creation',
        build: () {
          when(
            () => mockReminderRepository.createReminder(any()),
          ).thenThrow(Exception('Database error'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          CreateReminderEvent(origin: EventOrigin.dialog, request: request),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('UpdateReminderEvent', () {
      const reminderId = 1;
      final request = ReminderRequestModel(
        title: 'Updated Reminder',
        message: 'Updated message',
        offset: 30,
        offsetType: 1,
        type: 1,
        sent: false,
        dismissed: false,
        event: 2,
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, ReminderUpdated] when update succeeds',
        build: () {
          when(
            () => mockReminderRepository.updateReminder(reminderId, any()),
          ).thenAnswer(
            (_) async => MockModels.createReminder(
              id: reminderId,
              title: 'Updated Reminder',
            ),
          );
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          UpdateReminderEvent(
            origin: EventOrigin.dialog,
            id: reminderId,
            request: request,
          ),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<ReminderUpdated>()
              .having((s) => s.reminder.id, 'reminder id', reminderId)
              .having((s) => s.reminder.title, 'title', 'Updated Reminder'),
        ],
        verify: (_) {
          verify(
            () => mockReminderRepository.updateReminder(reminderId, any()),
          ).called(1);
        },
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] when reminder not found',
        build: () {
          when(
            () => mockReminderRepository.updateReminder(reminderId, any()),
          ).thenThrow(NotFoundException(message: 'Reminder not found'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          UpdateReminderEvent(
            origin: EventOrigin.dialog,
            id: reminderId,
            request: request,
          ),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            'Reminder not found',
          ),
        ],
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] for unexpected error during update',
        build: () {
          when(
            () => mockReminderRepository.updateReminder(reminderId, any()),
          ).thenThrow(Exception('Connection lost'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          UpdateReminderEvent(
            origin: EventOrigin.dialog,
            id: reminderId,
            request: request,
          ),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('DeleteReminderEvent', () {
      const reminderId = 1;

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, ReminderDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockReminderRepository.deleteReminder(reminderId),
          ).thenAnswer((_) async {});
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          DeleteReminderEvent(origin: EventOrigin.dialog, id: reminderId),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<ReminderDeleted>().having((s) => s.id, 'id', reminderId),
        ],
        verify: (_) {
          verify(
            () => mockReminderRepository.deleteReminder(reminderId),
          ).called(1);
        },
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] when reminder not found',
        build: () {
          when(
            () => mockReminderRepository.deleteReminder(reminderId),
          ).thenThrow(NotFoundException(message: 'Reminder not found'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          DeleteReminderEvent(origin: EventOrigin.dialog, id: reminderId),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            'Reminder not found',
          ),
        ],
      );

      blocTest<ReminderBloc, ReminderState>(
        'emits [RemindersLoading, RemindersError] for unexpected error during deletion',
        build: () {
          when(
            () => mockReminderRepository.deleteReminder(reminderId),
          ).thenThrow(Exception('Timeout'));
          return reminderBloc;
        },
        act: (bloc) => bloc.add(
          DeleteReminderEvent(origin: EventOrigin.dialog, id: reminderId),
        ),
        expect: () => [
          isA<RemindersLoading>(),
          isA<RemindersError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });
  });
}
