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
import 'package:heliumapp/data/models/planner/request/category_request_model.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late CategoryRemoteDataSourceImpl dataSource;
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
    dataSource = CategoryRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('CategoryRemoteDataSource', () {
    group('getCategories', () {
      test('returns list of CategoryModel on successful response', () async {
        // GIVEN
        final categoriesJson = [
          givenCategoryJson(id: 1, title: 'Homework'),
          givenCategoryJson(id: 2, title: 'Exams'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(categoriesJson));

        // WHEN
        final result = await dataSource.getCategories();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('Homework'));
        expect(result[1].title, equals('Exams'));
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
        final result = await dataSource.getCategories();

        // THEN
        expect(result, isEmpty);
      });

      test('filters by courseId when provided', () async {
        // GIVEN - API returns categories from multiple courses
        final categoriesJson = [
          givenCategoryJson(id: 1, title: 'Homework', course: 5),
          givenCategoryJson(id: 2, title: 'Exams', course: 3),
          givenCategoryJson(id: 3, title: 'Projects', course: 5),
        ];
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(categoriesJson));

        // WHEN - filter by courseId 5
        final result = await dataSource.getCategories(courseId: 5);

        // THEN - only categories from course 5 are returned
        expect(result.length, equals(2));
        expect(result[0].title, equals('Homework'));
        expect(result[1].title, equals('Projects'));
      });

      test('filters by title when provided', () async {
        // GIVEN - API returns categories with different titles
        final categoriesJson = [
          givenCategoryJson(id: 1, title: 'Homework'),
          givenCategoryJson(id: 2, title: 'Exams'),
          givenCategoryJson(id: 3, title: 'Homework'),
        ];
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(categoriesJson));

        // WHEN - filter by title 'Homework'
        final result = await dataSource.getCategories(title: 'Homework');

        // THEN - only categories with title 'Homework' are returned
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[1].id, equals(3));
      });

      test('parses category with weight and grades', () async {
        // GIVEN
        final categoriesJson = [
          givenCategoryJson(
            id: 1,
            weight: 30.0,
            overallGrade: 92.5,
            gradeByWeight: 27.75,
          ),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(categoriesJson));

        // WHEN
        final result = await dataSource.getCategories();

        // THEN
        expect(result[0].weight, equals(30.0));
        expect(result[0].overallGrade, equals(92.5));
        expect(result[0].gradeByWeight, equals(27.75));
      });

      test('parses category color correctly', () async {
        // GIVEN
        final categoriesJson = [givenCategoryJson(id: 1, color: '#E21D55')];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(categoriesJson));

        // WHEN
        final result = await dataSource.getCategories();

        // THEN
        expect(result[0].color, isNotNull);
      });
    });

    group('createCategory', () {
      test('returns created CategoryModel on 201 response', () async {
        // GIVEN
        final json = givenCategoryJson(id: 1, title: 'New Category');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = CategoryRequestModel(
          title: 'New Category',
          color: '#4CAF50',
          weight: '25.0',
        );

        // WHEN
        final result = await dataSource.createCategory(1, 1, request);

        // THEN
        expect(result.title, equals('New Category'));
      });

      test('throws ValidationException on 400 response', () async {
        // GIVEN
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          givenValidationException({
            'title': ['This field is required'],
          }),
        );

        final request = CategoryRequestModel(
          title: '',
          color: '#4CAF50',
          weight: '25.0',
        );

        // WHEN/THEN
        expect(
          () => dataSource.createCategory(1, 1, request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('updateCategory', () {
      test('returns updated CategoryModel on 200 response', () async {
        // GIVEN
        final json = givenCategoryJson(
          id: 1,
          title: 'Updated Category',
          weight: 35.0,
        );
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = CategoryRequestModel(
          title: 'Updated Category',
          color: '#FF5722',
          weight: '35.0',
        );

        // WHEN
        final result = await dataSource.updateCategory(1, 1, 1, request);

        // THEN
        expect(result.title, equals('Updated Category'));
        expect(result.weight, equals(35.0));
      });
    });

    group('deleteCategory', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteCategory(1, 1, 1), completes);
      });

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deleteCategory(1, 1, 1),
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
          () => dataSource.getCategories(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenThrow(givenUnauthorizedException());

        final request = CategoryRequestModel(
          title: 'Test',
          color: '#4CAF50',
          weight: '25.0',
        );

        // WHEN/THEN
        expect(
          () => dataSource.createCategory(1, 1, request),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
