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
import 'package:heliumapp/data/models/planner/request/resource_group_request_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_request_model.dart';
import 'package:heliumapp/data/sources/resource_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late ResourceRemoteDataSourceImpl dataSource;
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
    dataSource = ResourceRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('ResourceRemoteDataSource', () {
    group('getResourceGroups', () {
      test(
        'returns list of ResourceGroupModel on successful response',
        () async {
          // GIVEN
          final groupsJson = [
            givenResourceGroupJson(id: 1, title: 'Textbooks'),
            givenResourceGroupJson(id: 2, title: 'Supplies'),
          ];
          when(
            () => mockDio.get(any()),
          ).thenAnswer((_) async => givenSuccessResponse(groupsJson));

          // WHEN
          final result = await dataSource.getResourceGroups();

          // THEN
          expect(result.length, equals(2));
          expect(result[0].title, equals('Textbooks'));
          expect(result[1].title, equals('Supplies'));
        },
      );

      test('returns empty list when API returns empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.getResourceGroups();

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
          () => dataSource.getResourceGroups(),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getResourceGroupById', () {
      test('returns ResourceGroupModel on successful response', () async {
        // GIVEN
        final json = givenResourceGroupJson(id: 1, title: 'Textbooks');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getResourceGroupById(1);

        // THEN
        verifyResourceGroupMatchesJson(result, json);
      });
    });

    group('createResourceGroup', () {
      test('returns created ResourceGroupModel on 201 response', () async {
        // GIVEN
        final json = givenResourceGroupJson(id: 1, title: 'New Group');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = ResourceGroupRequestModel(
          title: 'New Group',
          shownOnCalendar: true,
        );

        // WHEN
        final result = await dataSource.createResourceGroup(request);

        // THEN
        expect(result.title, equals('New Group'));
      });
    });

    group('updateResourceGroup', () {
      test('returns updated ResourceGroupModel on 200 response', () async {
        // GIVEN
        final json = givenResourceGroupJson(id: 1, title: 'Updated Group');
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = ResourceGroupRequestModel(
          title: 'Updated Group',
          shownOnCalendar: false,
        );

        // WHEN
        final result = await dataSource.updateResourceGroup(1, request);

        // THEN
        expect(result.title, equals('Updated Group'));
      });
    });

    group('deleteResourceGroup', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteResourceGroup(1), completes);
      });
    });

    group('getResource', () {
      test('returns list of ResourceModel on successful response', () async {
        // GIVEN
        final resourcesJson = [
          givenResourceJson(id: 1, title: 'Textbook'),
          givenResourceJson(id: 2, title: 'Calculator'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(resourcesJson));

        // WHEN
        final result = await dataSource.getResources();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('Textbook'));
        expect(result[1].title, equals('Calculator'));
      });

      test('filters by groupId when provided', () async {
        // GIVEN - API returns resources from multiple groups
        final resourcesJson = [
          givenResourceJson(id: 1, title: 'Material A', resourceGroup: 5),
          givenResourceJson(id: 2, title: 'Material B', resourceGroup: 3),
          givenResourceJson(id: 3, title: 'Material C', resourceGroup: 5),
        ];
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(resourcesJson));

        // WHEN - filter by groupId 5
        final result = await dataSource.getResources(groupId: 5);

        // THEN - only resources from group 5 are returned
        expect(result.length, equals(2));
        expect(result[0].title, equals('Material A'));
        expect(result[1].title, equals('Material C'));
      });

      test('parses resource with courses correctly', () async {
        // GIVEN
        final resourcesJson = [
          givenResourceJson(id: 1, courses: [1, 2, 3]),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(resourcesJson));

        // WHEN
        final result = await dataSource.getResources();

        // THEN
        expect(result[0].courses, equals([1, 2, 3]));
      });

      test('parses resource status and condition', () async {
        // GIVEN
        final resourcesJson = [
          givenResourceJson(id: 1, status: 1, condition: 2),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(resourcesJson));

        // WHEN
        final result = await dataSource.getResources();

        // THEN
        expect(result[0].status, equals(1));
        expect(result[0].condition, equals(2));
      });
    });

    group('getResourceById', () {
      test('returns ResourceModel on successful response', () async {
        // GIVEN
        final json = givenResourceJson(id: 1, title: 'Textbook');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getResourceById(1, 1);

        // THEN
        verifyResourceMatchesJson(result, json);
      });
    });

    group('createResource', () {
      test('returns created ResourceModel on 201 response', () async {
        // GIVEN
        final json = givenResourceJson(id: 1, title: 'New Material');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = ResourceRequestModel(
          title: 'New Material',
          status: 0,
          condition: 0,
          website: '',
          price: '',
          details: '',
          courses: [1],
          resourceGroup: 1,
        );

        // WHEN
        final result = await dataSource.createResource(1, request);

        // THEN
        expect(result.title, equals('New Material'));
      });
    });

    group('updateResource', () {
      test('returns updated ResourceModel on 200 response', () async {
        // GIVEN
        final json = givenResourceJson(id: 1, title: 'Updated Material');
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = ResourceRequestModel(
          title: 'Updated Material',
          status: 1,
          condition: 1,
          website: '',
          price: '',
          details: '',
          courses: [1, 2],
          resourceGroup: 1,
        );

        // WHEN
        final result = await dataSource.updateResource(1, 1, request);

        // THEN
        expect(result.title, equals('Updated Material'));
      });
    });

    group('deleteResource', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteResource(1, 1), completes);
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(
          () => dataSource.getResourceGroups(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws ServerException on 500 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenServerException());

        // WHEN/THEN
        expect(
          () => dataSource.getResourceGroupById(1),
          throwsA(isA<ServerException>()),
        );
      });
    });
  });
}
