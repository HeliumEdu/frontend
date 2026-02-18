// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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

      test('throws ServerException on invalid response format', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse({'invalid': 'format'}));

        // WHEN/THEN
        expect(() => dataSource.getEvents(), throwsA(isA<ServerException>()));
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
          comments: '',
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
          comments: '',
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
          comments: 'Updated comments',
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

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deleteEvent(eventId: 1),
          throwsA(isA<ServerException>()),
        );
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
