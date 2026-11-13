import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late HomeworkRemoteDataSourceImpl dataSource;
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

      test('throws HeliumException on invalid response format', () async {
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
          throwsA(isA<HeliumException>()),
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

      test('throws HeliumException when homework not found', () async {
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
          throwsA(isA<HeliumException>()),
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
          completed: false,
          currentGrade: '',
          category: null,
          course: 1,
          resources: [],
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
          completed: false,
          currentGrade: '',
          category: null,
          course: 1,
          resources: [],
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

      test('throws HeliumException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () =>
              dataSource.deleteHomework(groupId: 1, courseId: 1, homeworkId: 1),
          throwsA(isA<HeliumException>()),
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

    group('occurrences of a repeating assignment', () {
      final occurrenceStart = DateTime.utc(2026, 9, 14, 21, 59);

      test('updateHomework asks the API to change only the occurrence when told to', () async {
        // GIVEN
        when(
          () => mockDio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(givenHomeworkJson(id: 33, completed: true)));

        // WHEN
        final result = await dataSource.updateHomework(
          groupId: 1,
          courseId: 2,
          homeworkId: 9,
          request: HomeworkRequestModel(completed: true),
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
        expect(captured[0], '/planner/coursegroups/1/courses/2/homework/9/');
        expect(captured[1], {'completed': true});
        expect(captured[2], {'scope': 'this', 'occurrence_start': '2026-09-14T21:59:00.000Z'});
        expect(result.id, 33, reason: 'the response is the new standalone assignment');
        expect(result.completed, isTrue);
      });

      test('updateHomework moves the whole series from an occurrence without a scope', () async {
        // GIVEN
        when(
          () => mockDio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(givenHomeworkJson(id: 9)));

        // WHEN
        await dataSource.updateHomework(
          groupId: 1,
          courseId: 2,
          homeworkId: 9,
          request: HomeworkRequestModel(start: '2026-09-15T21:59:00Z'),
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
        expect(query, {'occurrence_start': '2026-09-14T21:59:00.000Z'});
      });

      test('deleteHomework with an occurrence deletes only that occurrence', () async {
        // GIVEN
        when(
          () => mockDio.delete(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN
        await dataSource.deleteHomework(groupId: 1, courseId: 2, homeworkId: 9, occurrenceStart: occurrenceStart);

        // THEN
        final captured = verify(
          () => mockDio.delete(captureAny(), queryParameters: captureAny(named: 'queryParameters')),
        ).captured;
        expect(captured[0], '/planner/coursegroups/1/courses/2/homework/9/');
        expect(captured[1], {'scope': 'this', 'occurrence_start': '2026-09-14T21:59:00.000Z'});
      });

      test('deleteHomework without an occurrence deletes the whole series', () async {
        // GIVEN
        when(
          () => mockDio.delete(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN
        await dataSource.deleteHomework(groupId: 1, courseId: 2, homeworkId: 9);

        // THEN
        final query = verify(
          () => mockDio.delete(any(), queryParameters: captureAny(named: 'queryParameters')),
        ).captured.single;
        expect(query, isNull);
      });

      test('cloneHomework from an occurrence sends its occurrence_start', () async {
        // GIVEN
        when(
          () => mockDio.post(any(), queryParameters: any(named: 'queryParameters')),
        ).thenAnswer((_) async => givenSuccessResponse(givenHomeworkJson(id: 40), statusCode: 201));

        // WHEN
        final clone = await dataSource.cloneHomework(
          groupId: 1,
          courseId: 2,
          homeworkId: 9,
          occurrenceStart: occurrenceStart,
        );

        // THEN
        final captured = verify(
          () => mockDio.post(captureAny(), queryParameters: captureAny(named: 'queryParameters')),
        ).captured;
        expect(captured[0], '/planner/coursegroups/1/courses/2/homework/9/clone/');
        expect(captured[1], {'occurrence_start': '2026-09-14T21:59:00.000Z'});
        expect(clone.id, 40);
      });
    });
  });
}
