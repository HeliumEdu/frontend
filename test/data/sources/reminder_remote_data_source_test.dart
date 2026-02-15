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
import 'package:heliumapp/data/models/planner/request/reminder_request_model.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late ReminderRemoteDataSourceImpl dataSource;
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
    dataSource = ReminderRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('ReminderRemoteDataSource', () {
    group('getReminders', () {
      test('returns list of ReminderModel on successful response', () async {
        // GIVEN
        final remindersJson = [
          givenReminderJson(id: 1, title: 'Homework Due'),
          givenReminderJson(id: 2, title: 'Exam Tomorrow'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(remindersJson));

        // WHEN
        final result = await dataSource.getReminders();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('Homework Due'));
        expect(result[1].title, equals('Exam Tomorrow'));
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
        final result = await dataSource.getReminders();

        // THEN
        expect(result, isEmpty);
      });

      test('filters by homeworkId when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getReminders(homeworkId: 5);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'homework': 5}),
        ).called(1);
      });

      test('filters by eventId when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getReminders(eventId: 10);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'event': 10}),
        ).called(1);
      });

      test('filters by sent status when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getReminders(sent: false);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'sent': false}),
        ).called(1);
      });

      test('filters by dismissed status when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getReminders(dismissed: true);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'dismissed': true}),
        ).called(1);
      });

      test('parses reminder offset and type correctly', () async {
        // GIVEN
        final remindersJson = [
          givenReminderJson(id: 1, offset: 30, offsetType: 1, type: 2),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(remindersJson));

        // WHEN
        final result = await dataSource.getReminders();

        // THEN
        expect(result[0].offset, equals(30));
        expect(result[0].offsetType, equals(1));
        expect(result[0].type, equals(2));
      });

      test('parses sent and dismissed statuses', () async {
        // GIVEN
        final remindersJson = [
          givenReminderJson(id: 1, sent: true, dismissed: false),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(remindersJson));

        // WHEN
        final result = await dataSource.getReminders();

        // THEN
        expect(result[0].sent, isTrue);
        expect(result[0].dismissed, isFalse);
      });
    });

    group('createReminder', () {
      test('returns created ReminderModel on 201 response', () async {
        // GIVEN
        final json = givenReminderJson(id: 1, title: 'New Reminder');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = ReminderRequestModel(
          title: 'New Reminder',
          message: 'Test message',
          offset: 15,
          offsetType: 0,
          type: 0,
          sent: false,
          dismissed: false,
          homework: 1,
        );

        // WHEN
        final result = await dataSource.createReminder(request);

        // THEN
        expect(result.title, equals('New Reminder'));
      });

      test('throws ValidationException on 400 response', () async {
        // GIVEN
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          givenValidationException({
            'title': ['This field is required'],
          }),
        );

        final request = ReminderRequestModel(
          title: '',
          message: 'Test message',
          offset: 15,
          offsetType: 0,
          type: 0,
          sent: false,
          dismissed: false,
        );

        // WHEN/THEN
        expect(
          () => dataSource.createReminder(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('updateReminder', () {
      test('returns updated ReminderModel on 200 response', () async {
        // GIVEN
        final json = givenReminderJson(
          id: 1,
          title: 'Updated Reminder',
          dismissed: true,
        );
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = ReminderRequestModel(
          title: 'Updated Reminder',
          message: 'Updated message',
          offset: 30,
          offsetType: 1,
          type: 1,
          sent: false,
          dismissed: true,
        );

        // WHEN
        final result = await dataSource.updateReminder(1, request);

        // THEN
        expect(result.title, equals('Updated Reminder'));
      });
    });

    group('deleteReminder', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteReminder(1), completes);
      });

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deleteReminder(1),
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
        expect(
          () => dataSource.getReminders(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getReminders(),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
