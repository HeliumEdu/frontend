// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late ExternalCalendarRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = ExternalCalendarRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('ExternalCalendarRemoteDataSource', () {
    group('getExternalCalendars', () {
      test(
        'returns list of ExternalCalendarModel on successful list response',
        () async {
          // GIVEN
          final calendarsJson = [
            givenExternalCalendarJson(id: 1, title: 'Google Calendar'),
            givenExternalCalendarJson(id: 2, title: 'Outlook'),
          ];
          when(
            () => mockDio.get(any()),
          ).thenAnswer((_) async => givenSuccessResponse(calendarsJson));

          // WHEN
          final result = await dataSource.getExternalCalendars();

          // THEN
          expect(result.length, equals(2));
          expect(result[0].title, equals('Google Calendar'));
          expect(result[1].title, equals('Outlook'));
        },
      );

      test('returns list from results key when response is map', () async {
        // GIVEN
        final calendarsJson = {
          'results': [
            givenExternalCalendarJson(id: 1, title: 'Google Calendar'),
          ],
        };
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(calendarsJson));

        // WHEN
        final result = await dataSource.getExternalCalendars();

        // THEN
        expect(result.length, equals(1));
        expect(result[0].title, equals('Google Calendar'));
      });

      test('returns empty list when API returns empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.getExternalCalendars();

        // THEN
        expect(result, isEmpty);
      });
    });

    group('getExternalCalendarEvents', () {
      test(
        'returns list of ExternalCalendarEventModel on successful response',
        () async {
          // GIVEN
          final eventsJson = [
            givenExternalCalendarEventJson(id: 1, title: 'Meeting'),
            givenExternalCalendarEventJson(id: 2, title: 'Conference'),
          ];
          when(
            () => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            ),
          ).thenAnswer((_) async => givenSuccessResponse(eventsJson));

          // WHEN
          final result = await dataSource.getExternalCalendarEvents(
            from: DateTime(2025, 8, 1),
            to: DateTime(2025, 12, 31),
          );

          // THEN
          expect(result.length, equals(2));
          expect(result[0].title, equals('Meeting'));
          expect(result[1].title, equals('Conference'));
        },
      );

      test('returns empty list when API returns empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.getExternalCalendarEvents(
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 12, 31),
        );

        // THEN
        expect(result, isEmpty);
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
        expect(
          () => dataSource.getExternalCalendarEvents(
            from: DateTime(2025, 8, 1),
            to: DateTime(2025, 12, 31),
          ),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('createExternalCalendar', () {
      test('returns created ExternalCalendarModel on 201 response', () async {
        // GIVEN
        final json = givenExternalCalendarJson(id: 1, title: 'New Calendar');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = givenExternalCalendarRequestModel();

        // WHEN
        final result = await dataSource.createExternalCalendar(
          payload: request,
        );

        // THEN
        expect(result.title, equals('New Calendar'));
      });
    });

    group('updateExternalCalendar', () {
      test('returns updated ExternalCalendarModel on 200 response', () async {
        // GIVEN
        final json = givenExternalCalendarJson(
          id: 1,
          title: 'Updated Calendar',
        );
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = givenExternalCalendarRequestModel(
          title: 'Updated Calendar',
        );

        // WHEN
        final result = await dataSource.updateExternalCalendar(
          calendarId: 1,
          payload: request,
        );

        // THEN
        expect(result.title, equals('Updated Calendar'));
      });
    });

    group('deleteExternalCalendar', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteExternalCalendar(calendarId: 1), completes);
      });

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deleteExternalCalendar(calendarId: 1),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(
          () => dataSource.getExternalCalendars(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getExternalCalendars(),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
