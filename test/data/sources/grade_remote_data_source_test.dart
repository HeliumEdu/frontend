import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/needed_grade_model.dart';
import 'package:heliumapp/data/sources/grade_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late GradeRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = GradeRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('GradeRemoteDataSource', () {
    group('getGrades', () {
      test(
        'returns list of GradeCourseGroupModel on successful response',
        () async {
          // GIVEN
          final gradesJson = {
            'course_groups': [
              givenGradeCourseGroupJson(id: 1, title: 'Fall 2025'),
              givenGradeCourseGroupJson(id: 2, title: 'Spring 2026'),
            ],
          };
          when(
            () => mockDio.get(any()),
          ).thenAnswer((_) async => givenSuccessResponse(gradesJson));

          // WHEN
          final result = await dataSource.getGrades();

          // THEN
          expect(result.length, equals(2));
          expect(result[0].title, equals('Fall 2025'));
          expect(result[1].title, equals('Spring 2026'));
        },
      );

      test('returns empty list when course_groups is empty', () async {
        // GIVEN
        final gradesJson = {'course_groups': []};
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(gradesJson));

        // WHEN
        final result = await dataSource.getGrades();

        // THEN
        expect(result, isEmpty);
      });

      test('parses grade with overall grade', () async {
        // GIVEN
        final gradesJson = {
          'course_groups': [
            givenGradeCourseGroupJson(id: 1, overallGrade: 92.5),
          ],
        };
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(gradesJson));

        // WHEN
        final result = await dataSource.getGrades();

        // THEN
        expect(result[0].overallGrade, equals(92.5));
      });

      test('parses homework counts', () async {
        // GIVEN
        final gradesJson = {
          'course_groups': [
            givenGradeCourseGroupJson(
              id: 1,
              numHomework: 30,
              numHomeworkCompleted: 25,
              numHomeworkGraded: 20,
            ),
          ],
        };
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(gradesJson));

        // WHEN
        final result = await dataSource.getGrades();

        // THEN
        expect(result[0].numHomework, equals(30));
        expect(result[0].numHomeworkCompleted, equals(25));
        expect(result[0].numHomeworkGraded, equals(20));
      });

      test('throws HeliumException when course_groups key missing', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse({'other_key': []}));

        // WHEN/THEN
        expect(() => dataSource.getGrades(), throwsA(isA<HeliumException>()));
      });

      test('throws HeliumException on non-map response', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN/THEN
        expect(() => dataSource.getGrades(), throwsA(isA<HeliumException>()));
      });
    });

    group('getNeededGrade', () {
      test('asks for the needed grade and parses the result', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => givenSuccessResponse({
            'state': 'achievable',
            'needed_grade': 76.25,
            'weighted': true,
            'category': {'id': 2, 'title': 'Exams'},
            'assignment': {
              'id': 9,
              'title': 'Final',
              'points_possible': 100.0,
              'needed_points': 76.25,
            },
            'total_weight_accounted_for': null,
          }),
        );

        // WHEN
        final result = await dataSource.getNeededGrade(
          courseId: 1,
          targetId: 2,
          desiredGrade: 85,
        );

        // THEN
        verify(
          () => mockDio.get(
            ApiUrl.plannerGradesNeededUrl,
            queryParameters: {'course': 1, 'target': 2, 'desired_grade': 85.0},
          ),
        ).called(1);
        expect(result.state, NeededGradeState.achievable);
        expect(result.neededGrade, 76.25);
        expect(result.weighted, isTrue);
        expect(result.assignment!.title, 'Final');
        expect(result.assignment!.neededPoints, 76.25);
        expect(result.totalWeightAccountedFor, isNull);
      });

      test('parses a weight error with no assignment', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => givenSuccessResponse({
            'state': 'invalid_total_weight',
            'needed_grade': 0,
            'weighted': true,
            'category': {'id': 2, 'title': 'Exams'},
            'assignment': null,
            'total_weight_accounted_for': 80.0,
          }),
        );

        // WHEN
        final result = await dataSource.getNeededGrade(
          courseId: 1,
          targetId: 2,
          desiredGrade: 85,
        );

        // THEN
        expect(result.state, NeededGradeState.invalidTotalWeight);
        expect(result.isAchievable, isFalse);
        expect(result.assignment, isNull);
        expect(result.totalWeightAccountedFor, 80.0);
      });

      test('throws ServerException on 500 response', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(givenServerException());

        // WHEN/THEN
        expect(
          () => dataSource.getNeededGrade(
            courseId: 1,
            targetId: 2,
            desiredGrade: 85,
          ),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(() => dataSource.getGrades(), throwsA(isA<NetworkException>()));
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getGrades(),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('throws ServerException on 500 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenServerException());

        // WHEN/THEN
        expect(() => dataSource.getGrades(), throwsA(isA<ServerException>()));
      });
    });
  });
}
