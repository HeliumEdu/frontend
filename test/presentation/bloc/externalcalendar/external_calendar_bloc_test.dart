// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockExternalCalendarRepository mockExternalCalendarRepository;
  late ExternalCalendarBloc externalCalendarBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockExternalCalendarRepository = MockExternalCalendarRepository();
    externalCalendarBloc = ExternalCalendarBloc(
      externalCalendarRepository: mockExternalCalendarRepository,
    );
  });

  tearDown(() {
    externalCalendarBloc.close();
  });

  group('ExternalCalendarBloc', () {
    test('initial state is ExternalCalendarInitial with bloc origin', () {
      expect(externalCalendarBloc.state, isA<ExternalCalendarInitial>());
    });

    group('FetchExternalCalendarsEvent', () {
      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarsFetched] when fetch succeeds',
        build: () {
          when(
            () => mockExternalCalendarRepository.getExternalCalendars(),
          ).thenAnswer((_) async => MockModels.createExternalCalendars());
          return externalCalendarBloc;
        },
        act: (bloc) =>
            bloc.add(FetchExternalCalendarsEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarsFetched>().having(
            (s) => s.externalCalendars.length,
            'calendars length',
            2,
          ),
        ],
        verify: (_) {
          verify(
            () => mockExternalCalendarRepository.getExternalCalendars(),
          ).called(1);
        },
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarsError] when HeliumException occurs',
        build: () {
          when(
            () => mockExternalCalendarRepository.getExternalCalendars(),
          ).thenThrow(ServerException(message: 'Server error'));
          return externalCalendarBloc;
        },
        act: (bloc) =>
            bloc.add(FetchExternalCalendarsEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarsError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarsError] for unexpected errors',
        build: () {
          when(
            () => mockExternalCalendarRepository.getExternalCalendars(),
          ).thenThrow(Exception('Unknown error'));
          return externalCalendarBloc;
        },
        act: (bloc) =>
            bloc.add(FetchExternalCalendarsEvent(origin: EventOrigin.screen)),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarsError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('FetchExternalCalendarEventsEvent', () {
      final from = DateTime(2025, 1, 1);
      final to = DateTime(2025, 1, 31);

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarEventsFetched] when fetch succeeds',
        build: () {
          when(
            () => mockExternalCalendarRepository.getExternalCalendarEvents(
              from: from,
              to: to,
              search: null,
            ),
          ).thenAnswer((_) async => MockModels.createExternalCalendarEvents());
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          FetchExternalCalendarEventsEvent(
            origin: EventOrigin.screen,
            from: from,
            to: to,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarEventsFetched>().having(
            (s) => s.events.length,
            'events length',
            3,
          ),
        ],
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarEventsFetched] with search filter',
        build: () {
          when(
            () => mockExternalCalendarRepository.getExternalCalendarEvents(
              from: from,
              to: to,
              search: 'meeting',
            ),
          ).thenAnswer(
            (_) async => MockModels.createExternalCalendarEvents(count: 1),
          );
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          FetchExternalCalendarEventsEvent(
            origin: EventOrigin.screen,
            from: from,
            to: to,
            search: 'meeting',
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarEventsFetched>().having(
            (s) => s.events.length,
            'events length',
            1,
          ),
        ],
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarsError] when fetch fails',
        build: () {
          when(
            () => mockExternalCalendarRepository.getExternalCalendarEvents(
              from: any(named: 'from'),
              to: any(named: 'to'),
              search: any(named: 'search'),
            ),
          ).thenThrow(NetworkException(message: 'Network error'));
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          FetchExternalCalendarEventsEvent(
            origin: EventOrigin.screen,
            from: from,
            to: to,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarsError>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ],
      );
    });

    group('CreateExternalCalendarEvent', () {
      const request = ExternalCalendarRequestModel(
        title: 'New Calendar',
        url: 'https://example.com/calendar.ics',
        color: '#FF5733',
        shownOnCalendar: true,
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarCreated] when creation succeeds',
        build: () {
          when(
            () => mockExternalCalendarRepository.createExternalCalendar(
              payload: any(named: 'payload'),
            ),
          ).thenAnswer(
            (_) async => MockModels.createExternalCalendar(
              id: 10,
              title: 'New Calendar',
            ),
          );
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          CreateExternalCalendarEvent(
            origin: EventOrigin.dialog,
            request: request,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarCreated>()
              .having((s) => s.externalCalendar.id, 'calendar id', 10)
              .having((s) => s.externalCalendar.title, 'title', 'New Calendar'),
        ],
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarsError] when creation fails',
        build: () {
          when(
            () => mockExternalCalendarRepository.createExternalCalendar(
              payload: any(named: 'payload'),
            ),
          ).thenThrow(ValidationException(message: 'Invalid calendar URL'));
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          CreateExternalCalendarEvent(
            origin: EventOrigin.dialog,
            request: request,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarsError>().having(
            (e) => e.message,
            'message',
            'Invalid calendar URL',
          ),
        ],
      );
    });

    group('UpdateExternalCalendarEvent', () {
      const calendarId = 5;
      const request = ExternalCalendarRequestModel(
        title: 'Updated Calendar',
        url: 'https://example.com/updated.ics',
        color: '#00FF00',
        shownOnCalendar: false,
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarUpdated] when update succeeds',
        build: () {
          when(
            () => mockExternalCalendarRepository.updateExternalCalendar(
              calendarId: calendarId,
              payload: any(named: 'payload'),
            ),
          ).thenAnswer(
            (_) async => MockModels.createExternalCalendar(
              id: calendarId,
              title: 'Updated Calendar',
            ),
          );
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          UpdateExternalCalendarEvent(
            origin: EventOrigin.dialog,
            id: calendarId,
            request: request,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarUpdated>()
              .having((s) => s.externalCalendar.id, 'calendar id', calendarId)
              .having(
                (s) => s.externalCalendar.title,
                'title',
                'Updated Calendar',
              ),
        ],
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarsError] when calendar not found',
        build: () {
          when(
            () => mockExternalCalendarRepository.updateExternalCalendar(
              calendarId: calendarId,
              payload: any(named: 'payload'),
            ),
          ).thenThrow(NotFoundException(message: 'Calendar not found'));
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          UpdateExternalCalendarEvent(
            origin: EventOrigin.dialog,
            id: calendarId,
            request: request,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarsError>().having(
            (e) => e.message,
            'message',
            'Calendar not found',
          ),
        ],
      );
    });

    group('DeleteExternalCalendarEvent', () {
      const calendarId = 5;

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockExternalCalendarRepository.deleteExternalCalendar(
              calendarId: calendarId,
            ),
          ).thenAnswer((_) async {});
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          DeleteExternalCalendarEvent(
            origin: EventOrigin.dialog,
            id: calendarId,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarDeleted>().having((s) => s.id, 'id', calendarId),
        ],
        verify: (_) {
          verify(
            () => mockExternalCalendarRepository.deleteExternalCalendar(
              calendarId: calendarId,
            ),
          ).called(1);
        },
      );

      blocTest<ExternalCalendarBloc, ExternalCalendarState>(
        'emits [ExternalCalendarsLoading, ExternalCalendarsError] when deletion fails',
        build: () {
          when(
            () => mockExternalCalendarRepository.deleteExternalCalendar(
              calendarId: calendarId,
            ),
          ).thenThrow(ServerException(message: 'Cannot delete calendar'));
          return externalCalendarBloc;
        },
        act: (bloc) => bloc.add(
          DeleteExternalCalendarEvent(
            origin: EventOrigin.dialog,
            id: calendarId,
          ),
        ),
        expect: () => [
          isA<ExternalCalendarsLoading>(),
          isA<ExternalCalendarsError>().having(
            (e) => e.message,
            'message',
            'Cannot delete calendar',
          ),
        ],
      );
    });
  });
}
