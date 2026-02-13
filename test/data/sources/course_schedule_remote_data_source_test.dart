// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late CourseScheduleRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = CourseScheduleRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('CourseScheduleRemoteDataSource', () {
    group('getCourseSchedules', () {
      test(
        'returns list of CourseScheduleModel on successful response',
        () async {
          // GIVEN
          final schedulesJson = [
            givenCourseScheduleJson(id: 1, daysOfWeek: '1010100'),
            givenCourseScheduleJson(id: 2, daysOfWeek: '0101010'),
          ];
          when(
            () => mockDio.get(any()),
          ).thenAnswer((_) async => givenSuccessResponse(schedulesJson));

          // WHEN
          final result = await dataSource.getCourseSchedules();

          // THEN
          expect(result.length, equals(2));
          expect(result[0].daysOfWeek, equals('1010100'));
          expect(result[1].daysOfWeek, equals('0101010'));
        },
      );

      test('returns empty list when API returns empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.getCourseSchedules();

        // THEN
        expect(result, isEmpty);
      });

      test('throws ServerException on invalid response format', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse({'invalid': 'format'}));

        // WHEN/THEN
        expect(
          () => dataSource.getCourseSchedules(),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getCourseScheduleForCourse', () {
      test('returns CourseScheduleModel on successful response', () async {
        // GIVEN
        final scheduleJson = givenCourseScheduleJson(
          id: 1,
          daysOfWeek: '1111100',
        );
        var callCount = 0;
        when(() => mockDio.get(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            // First call: list of schedules
            return givenSuccessResponse([
              {'id': 1},
            ]);
          } else {
            // Second call: schedule details
            return givenSuccessResponse(scheduleJson);
          }
        });

        // WHEN
        final result = await dataSource.getCourseScheduleForCourse(1, 1);

        // THEN
        verifyCourseScheduleMatchesJson(result, scheduleJson);
      });

      test('throws NotFoundException when no schedule found', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN/THEN
        expect(
          () => dataSource.getCourseScheduleForCourse(1, 1),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('createCourseSchedule', () {
      test('returns created CourseScheduleModel on 201 response', () async {
        // GIVEN
        final json = givenCourseScheduleJson(id: 1, daysOfWeek: '1010100');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = givenCourseScheduleRequestModel();

        // WHEN
        final result = await dataSource.createCourseSchedule(1, 1, request);

        // THEN
        expect(result.daysOfWeek, equals('1010100'));
      });
    });

    group('updateCourseSchedule', () {
      test('returns updated CourseScheduleModel on 200 response', () async {
        // GIVEN
        final json = givenCourseScheduleJson(id: 1, daysOfWeek: '1111111');
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = givenCourseScheduleRequestModel(daysOfWeek: '1111111');

        // WHEN
        final result = await dataSource.updateCourseSchedule(1, 1, 1, request);

        // THEN
        expect(result.daysOfWeek, equals('1111111'));
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(
          () => dataSource.getCourseSchedules(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getCourseSchedules(),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
