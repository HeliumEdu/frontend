// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late CourseRemoteDataSourceImpl dataSource;
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
    dataSource = CourseRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('CourseRemoteDataSource', () {
    group('getCourseGroups', () {
      test('returns list of CourseGroupModel on successful response', () async {
        // GIVEN
        final courseGroupsJson = [
          givenCourseGroupJson(id: 1, title: 'Fall 2025'),
          givenCourseGroupJson(id: 2, title: 'Spring 2026'),
        ];
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(courseGroupsJson));

        // WHEN
        final result = await dataSource.getCourseGroups();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].title, equals('Fall 2025'));
        expect(result[1].id, equals(2));
        expect(result[1].title, equals('Spring 2026'));
      });

      test('returns empty list when API returns empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.getCourseGroups();

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
          () => dataSource.getCourseGroups(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(
          () => dataSource.getCourseGroups(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getCourseGroups(),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });

    group('getCourseGroup', () {
      test('returns CourseGroupModel on successful response', () async {
        // GIVEN
        final json = givenCourseGroupJson(id: 1, title: 'Fall 2025');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getCourseGroup(1);

        // THEN
        verifyCourseGroupMatchesJson(result, json);
      });

      test('throws ServerException on non-200 response', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse({}, statusCode: 404));

        // WHEN/THEN
        expect(
          () => dataSource.getCourseGroup(999),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('createCourseGroup', () {
      test('returns created CourseGroupModel on 201 response', () async {
        // GIVEN
        final json = givenCourseGroupJson(id: 1, title: 'New Semester');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = CourseGroupRequestModel(
          title: 'New Semester',
          startDate: '2025-08-25',
          endDate: '2025-12-15',
          shownOnCalendar: true,
        );

        // WHEN
        final result = await dataSource.createCourseGroup(request);

        // THEN
        expect(result.id, equals(1));
        expect(result.title, equals('New Semester'));
      });

      test('throws ValidationException on 400 response', () async {
        // GIVEN
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          givenValidationException({
            'title': ['This field is required'],
          }),
        );

        final request = CourseGroupRequestModel(
          title: '',
          startDate: '2025-08-25',
          endDate: '2025-12-15',
          shownOnCalendar: true,
        );

        // WHEN/THEN
        expect(
          () => dataSource.createCourseGroup(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('updateCourseGroup', () {
      test('returns updated CourseGroupModel on 200 response', () async {
        // GIVEN
        final json = givenCourseGroupJson(id: 1, title: 'Updated Semester');
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = CourseGroupRequestModel(
          title: 'Updated Semester',
          startDate: '2025-08-25',
          endDate: '2025-12-15',
          shownOnCalendar: true,
        );

        // WHEN
        final result = await dataSource.updateCourseGroup(1, request);

        // THEN
        expect(result.title, equals('Updated Semester'));
      });
    });

    group('deleteCourseGroup', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteCourseGroup(1), completes);
      });

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deleteCourseGroup(1),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getCourses', () {
      test('returns list of CourseModel on successful response', () async {
        // GIVEN
        final coursesJson = [
          givenCourseJson(id: 1, title: 'Intro to CS'),
          givenCourseJson(id: 2, title: 'Calculus I'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(coursesJson));

        // WHEN
        final result = await dataSource.getCourses();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('Intro to CS'));
        expect(result[1].title, equals('Calculus I'));
      });

      test('filters by groupId when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getCourses(groupId: 5);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'course_group': 5}),
        ).called(1);
      });

      test('filters by shownOnCalendar when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getCourses(shownOnCalendar: true);

        // THEN
        verify(
          () =>
              mockDio.get(any(), queryParameters: {'shown_on_calendar': true}),
        ).called(1);
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
        final result = await dataSource.getCourses();

        // THEN
        expect(result, isEmpty);
      });
    });

    group('getCourse', () {
      test('returns CourseModel on successful response', () async {
        // GIVEN
        final json = givenCourseJson(id: 1, title: 'Intro to CS');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getCourse(1, 1);

        // THEN
        expect(result.id, equals(1));
        expect(result.title, equals('Intro to CS'));
      });

      test('parses nested schedules correctly', () async {
        // GIVEN
        final scheduleJson = givenCourseScheduleJson(
          id: 1,
          daysOfWeek: '1010100',
          monStartTime: '09:00:00',
          monEndTime: '10:30:00',
        );
        final json = givenCourseJson(id: 1, schedules: [scheduleJson]);
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getCourse(1, 1);

        // THEN
        expect(result.schedules.length, equals(1));
        expect(result.schedules[0].daysOfWeek, equals('1010100'));
        expect(result.schedules[0].monStartTime, equals(HeliumTime.parse('09:00:00')));
      });
    });

    group('createCourse', () {
      test('returns created CourseModel on 201 response', () async {
        // GIVEN
        final json = givenCourseJson(id: 1, title: 'New Course');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = CourseRequestModel(
          title: 'New Course',
          startDate: '2025-08-25',
          endDate: '2025-12-15',
          room: 'Room 101',
          credits: '3.0',
          color: '#4CAF50',
          website: '',
          isOnline: false,
          teacherName: 'Dr. Smith',
          teacherEmail: 'smith@test.edu',
          courseGroup: 1,
        );

        // WHEN
        final result = await dataSource.createCourse(1, request);

        // THEN
        expect(result.title, equals('New Course'));
      });
    });

    group('updateCourse', () {
      test('returns updated CourseModel on 200 response', () async {
        // GIVEN
        final json = givenCourseJson(id: 1, title: 'Updated Course');
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = CourseRequestModel(
          title: 'Updated Course',
          startDate: '2025-08-25',
          endDate: '2025-12-15',
          room: 'Room 102',
          credits: '4.0',
          color: '#FF5722',
          website: '',
          isOnline: true,
          teacherName: 'Dr. Johnson',
          teacherEmail: 'johnson@test.edu',
          courseGroup: 1,
        );

        // WHEN
        final result = await dataSource.updateCourse(1, 1, request);

        // THEN
        expect(result.title, equals('Updated Course'));
      });
    });

    group('deleteCourse', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteCourse(1, 1), completes);
      });
    });

    group('error handling', () {
      test('throws ServerException on 500 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenServerException());

        // WHEN/THEN
        expect(
          () => dataSource.getCourseGroups(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on no internet connection', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(
          givenDioException(
            type: DioExceptionType.unknown,
            message: 'SocketException: Connection refused',
          ),
        );

        // WHEN/THEN
        expect(
          () => dataSource.getCourseGroups(),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
