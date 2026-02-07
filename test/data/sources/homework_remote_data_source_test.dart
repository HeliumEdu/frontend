// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/homework_request_model.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late HomeworkRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = HomeworkRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('HomeworkRemoteDataSource', () {
    group('getHomeworks', () {
      test('returns list of HomeworkModel on successful response', () async {
        // GIVEN
        final homeworksJson = [
          givenHomeworkJson(id: 1, title: 'Assignment 1'),
          givenHomeworkJson(id: 2, title: 'Assignment 2'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(homeworksJson));

        // WHEN
        final result = await dataSource.getHomeworks(
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 12, 31),
        );

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('Assignment 1'));
        expect(result[1].title, equals('Assignment 2'));
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
        final result = await dataSource.getHomeworks(
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 12, 31),
        );

        // THEN
        expect(result, isEmpty);
      });

      test('parses completed homework correctly', () async {
        // GIVEN
        final homeworksJson = [givenHomeworkJson(id: 1, completed: true)];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(homeworksJson));

        // WHEN
        final result = await dataSource.getHomeworks(
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 12, 31),
        );

        // THEN
        expect(result[0].completed, isTrue);
      });

      test('parses homework with current grade', () async {
        // GIVEN
        final homeworksJson = [givenHomeworkJson(id: 1, currentGrade: '95')];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(homeworksJson));

        // WHEN
        final result = await dataSource.getHomeworks(
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 12, 31),
        );

        // THEN
        expect(result[0].currentGrade, equals('95'));
      });

      test('filters by category titles when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getHomeworks(
          from: DateTime(2025, 8, 1),
          to: DateTime(2025, 12, 31),
          categoryTitles: ['Homework', 'Quizzes'],
        );

        // THEN
        final captured =
            verify(
                  () => mockDio.get(
                    any(),
                    queryParameters: captureAny(named: 'queryParameters'),
                  ),
                ).captured.first
                as Map<String, dynamic>;
        expect(captured['category__title_in'], equals('Homework,Quizzes'));
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
          () => dataSource.getHomeworks(
            from: DateTime(2025, 8, 1),
            to: DateTime(2025, 12, 31),
          ),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getHomework', () {
      test('returns HomeworkModel on successful response', () async {
        // GIVEN
        final json = givenHomeworkJson(id: 1, title: 'Assignment 1');
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([json]));

        // WHEN
        final result = await dataSource.getHomework(id: 1);

        // THEN
        verifyHomeworkMatchesJson(result, json);
      });

      test('throws NotFoundException when homework not found', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN/THEN
        expect(
          () => dataSource.getHomework(id: 999),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('parses nested attachments correctly', () async {
        // GIVEN
        final attachmentJson = givenAttachmentJson(id: 1, homework: 1);
        final json = givenHomeworkJson(id: 1, attachments: [attachmentJson]);
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([json]));

        // WHEN
        final result = await dataSource.getHomework(id: 1);

        // THEN
        expect(result.attachments.length, equals(1));
      });
    });

    group('createHomework', () {
      test('returns created HomeworkModel on 201 response', () async {
        // GIVEN
        final json = givenHomeworkJson(id: 1, title: 'New Homework');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = HomeworkRequestModel(
          title: 'New Homework',
          allDay: false,
          showEndTime: true,
          start: '2025-09-01T23:59:00Z',
          end: '2025-09-02T23:59:00Z',
          priority: 75,
          comments: '',
          completed: false,
          currentGrade: '',
          category: null,
          course: 1,
          materials: [],
        );

        // WHEN
        final result = await dataSource.createHomework(
          groupId: 1,
          courseId: 1,
          request: request,
        );

        // THEN
        expect(result.title, equals('New Homework'));
      });

      test('throws ValidationException on 400 response', () async {
        // GIVEN
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          givenValidationException({
            'title': ['This field is required'],
          }),
        );

        final request = HomeworkRequestModel(
          title: '',
          allDay: false,
          showEndTime: true,
          start: '2025-09-01T23:59:00Z',
          end: '2025-09-02T23:59:00Z',
          priority: 75,
          comments: '',
          completed: false,
          currentGrade: '',
          category: null,
          course: 1,
          materials: [],
        );

        // WHEN/THEN
        expect(
          () => dataSource.createHomework(
            groupId: 1,
            courseId: 1,
            request: request,
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('updateHomework', () {
      test('returns updated HomeworkModel on 200 response', () async {
        // GIVEN
        final json = givenHomeworkJson(
          id: 1,
          title: 'Updated Homework',
          completed: true,
        );
        when(
          () => mockDio.patch(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = HomeworkRequestModel(course: 1, completed: true);

        // WHEN
        final result = await dataSource.updateHomework(
          groupId: 1,
          courseId: 1,
          homeworkId: 1,
          request: request,
        );

        // THEN
        expect(result.completed, isTrue);
      });
    });

    group('deleteHomework', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(
          dataSource.deleteHomework(groupId: 1, courseId: 1, homeworkId: 1),
          completes,
        );
      });

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () =>
              dataSource.deleteHomework(groupId: 1, courseId: 1, homeworkId: 1),
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
          () => dataSource.getHomeworks(
            from: DateTime(2025, 8, 1),
            to: DateTime(2025, 12, 31),
          ),
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
          () => dataSource.getHomework(id: 1),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
