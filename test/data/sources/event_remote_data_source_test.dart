import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late EventRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late MockCacheService mockCacheService;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    mockCacheService = MockCacheService();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    when(() => mockDioClient.cacheService).thenReturn(mockCacheService);
    when(() => mockCacheService.invalidateAll()).thenAnswer((_) async {});
    dataSource = EventRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('EventRemoteDataSource', () {
    group('getEvents', () {
      test('returns list of EventModel on successful response', () async {
        // GIVEN
        final eventsJson = [
          givenEventJson(id: 1, title: 'Study Group'),
          givenEventJson(id: 2, title: 'Office Hours'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(eventsJson));

        // WHEN
        final result = await dataSource.getEvents();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('Study Group'));
        expect(result[1].title, equals('Office Hours'));
      });

      test('returns empty list when API returns empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.getEvents();

        // THEN
        expect(result, isEmpty);
      });

      test('parses all day events correctly', () async {
        // GIVEN
        final eventsJson = [
          givenEventJson(id: 1, allDay: true, showEndTime: false),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(eventsJson));

        // WHEN
        final result = await dataSource.getEvents();

        // THEN
        expect(result[0].allDay, isTrue);
        expect(result[0].showEndTime, isFalse);
      });

      test('parses event with color correctly', () async {
        // GIVEN
        final eventsJson = [givenEventJson(id: 1, color: '#FF5722')];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(eventsJson));

        // WHEN
        final result = await dataSource.getEvents();

        // THEN
        expect(result[0].color, isNotNull);
      });

      test('throws HeliumException on invalid response format', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse({'invalid': 'format'}));

        // WHEN/THEN
        expect(() => dataSource.getEvents(), throwsA(isA<HeliumException>()));
      });
    });

    group('getEvent', () {
      test('returns EventModel on successful response', () async {
        // GIVEN
        final json = givenEventJson(id: 1, title: 'Study Group');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getEvent(id: 1);

        // THEN
        verifyEventMatchesJson(result, json);
      });

      test('parses nested attachments correctly', () async {
        // GIVEN
        final attachmentJson = givenAttachmentJson(id: 1, event: 1);
        final json = givenEventJson(id: 1, attachments: [attachmentJson]);
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getEvent(id: 1);

        // THEN
        expect(result.attachments.length, equals(1));
      });

      test('parses nested reminders correctly', () async {
        // GIVEN
        final reminderJson = givenReminderJson(id: 1, event: 1);
        final json = givenEventJson(id: 1, reminders: [reminderJson]);
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getEvent(id: 1);

        // THEN
        expect(result.reminders.length, equals(1));
      });
    });

    group('createEvent', () {
      test('returns created EventModel on 201 response', () async {
        // GIVEN
        final json = givenEventJson(id: 1, title: 'New Event');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = EventRequestModel(
          title: 'New Event',
          allDay: false,
          showEndTime: true,
          start: '2025-09-01T10:00:00Z',
          end: '2025-09-01T12:00:00Z',
          priority: 50,
        );

        // WHEN
        final result = await dataSource.createEvent(request: request);

        // THEN
        expect(result.title, equals('New Event'));
      });

      test('throws ValidationException on 400 response', () async {
        // GIVEN
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          givenValidationException({
            'title': ['This field is required'],
          }),
        );

        final request = EventRequestModel(
          title: '',
          allDay: false,
          showEndTime: true,
          start: '2025-09-01T10:00:00Z',
          end: '2025-09-01T12:00:00Z',
          priority: 50,
        );

        // WHEN/THEN
        expect(
          () => dataSource.createEvent(request: request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('updateEvent', () {
      test('returns updated EventModel on 200 response', () async {
        // GIVEN
        final json = givenEventJson(id: 1, title: 'Updated Event');
        when(
          () => mockDio.patch(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = EventRequestModel(
          title: 'Updated Event',
          allDay: false,
          showEndTime: true,
          start: '2025-09-01T10:00:00Z',
          end: '2025-09-01T14:00:00Z',
          priority: 75,
        );

        // WHEN
        final result = await dataSource.updateEvent(
          eventId: 1,
          request: request,
        );

        // THEN
        expect(result.title, equals('Updated Event'));
      });
    });

    group('deleteEvent', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteEvent(eventId: 1), completes);
      });

      test('throws HeliumException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deleteEvent(eventId: 1),
          throwsA(isA<HeliumException>()),
        );
      });
    });

    group('occurrences of a recurring event', () {
      final occurrenceStart = DateTime.utc(2026, 11, 26, 11);

      test('updateEvent asks the API to change only the occurrence when told to', () async {
        // GIVEN
        when(
          () => mockDio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(givenEventJson(id: 33, title: 'Moved')));

        // WHEN
        final result = await dataSource.updateEvent(
          eventId: 28,
          request: EventRequestModel(start: '2026-11-27T11:00:00Z', end: '2026-11-27T12:00:00Z'),
          occurrenceStart: occurrenceStart,
          onlyThisOccurrence: true,
        );

        // THEN
        final captured = verify(
          () => mockDio.patch(
            captureAny(),
            data: captureAny(named: 'data'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).captured;
        expect(captured[0], '/planner/events/28/');
        expect(captured[1], {'start': '2026-11-27T11:00:00Z', 'end': '2026-11-27T12:00:00Z'});
        expect(captured[2], {'scope': 'this', 'occurrence_start': '2026-11-26T11:00:00.000Z'});
        expect(result.id, 33, reason: 'the response is the new standalone event');
      });

      test('updateEvent moves the whole series from an occurrence without a scope', () async {
        // GIVEN
        when(
          () => mockDio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(givenEventJson(id: 28)));

        // WHEN
        await dataSource.updateEvent(
          eventId: 28,
          request: EventRequestModel(start: '2026-11-27T11:00:00Z'),
          occurrenceStart: occurrenceStart,
        );

        // THEN
        final query = verify(
          () => mockDio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).captured.single;
        expect(query, {'occurrence_start': '2026-11-26T11:00:00.000Z'});
      });

      test('updateEvent sends no query for a plain update', () async {
        // GIVEN
        when(
          () => mockDio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(givenEventJson(id: 28)));

        // WHEN
        await dataSource.updateEvent(eventId: 28, request: EventRequestModel(title: 'Renamed'));

        // THEN
        final query = verify(
          () => mockDio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).captured.single;
        expect(query, isNull);
      });

      test('deleteEvent with an occurrence deletes only that occurrence', () async {
        // GIVEN
        when(
          () => mockDio.delete(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN
        await dataSource.deleteEvent(eventId: 28, occurrenceStart: occurrenceStart);

        // THEN
        final captured = verify(
          () => mockDio.delete(captureAny(), queryParameters: captureAny(named: 'queryParameters')),
        ).captured;
        expect(captured[0], '/planner/events/28/');
        expect(captured[1], {'scope': 'this', 'occurrence_start': '2026-11-26T11:00:00.000Z'});
      });

      test('deleteEvent without an occurrence deletes the whole event', () async {
        // GIVEN
        when(
          () => mockDio.delete(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN
        await dataSource.deleteEvent(eventId: 28);

        // THEN
        final query = verify(
          () => mockDio.delete(any(), queryParameters: captureAny(named: 'queryParameters')),
        ).captured.single;
        expect(query, isNull);
      });

      test('cloneEvent from an occurrence sends its occurrence_start', () async {
        // GIVEN
        when(
          () => mockDio.post(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer((_) async => givenSuccessResponse(givenEventJson(id: 40), statusCode: 201));

        // WHEN
        final clone = await dataSource.cloneEvent(eventId: 28, occurrenceStart: occurrenceStart);

        // THEN
        final captured = verify(
          () => mockDio.post(captureAny(), queryParameters: captureAny(named: 'queryParameters')),
        ).captured;
        expect(captured[0], '/planner/events/28/clone/');
        expect(captured[1], {'occurrence_start': '2026-11-26T11:00:00.000Z'});
        expect(clone.id, 40);
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(() => dataSource.getEvents(), throwsA(isA<NetworkException>()));
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getEvent(id: 1),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
