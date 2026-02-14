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
import 'package:heliumapp/data/models/planner/request/material_group_request_model.dart';
import 'package:heliumapp/data/models/planner/request/material_request_model.dart';
import 'package:heliumapp/data/sources/material_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late MaterialRemoteDataSourceImpl dataSource;
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
    dataSource = MaterialRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('MaterialRemoteDataSource', () {
    group('getMaterialGroups', () {
      test(
        'returns list of MaterialGroupModel on successful response',
        () async {
          // GIVEN
          final groupsJson = [
            givenMaterialGroupJson(id: 1, title: 'Textbooks'),
            givenMaterialGroupJson(id: 2, title: 'Supplies'),
          ];
          when(
            () => mockDio.get(any()),
          ).thenAnswer((_) async => givenSuccessResponse(groupsJson));

          // WHEN
          final result = await dataSource.getMaterialGroups();

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
        final result = await dataSource.getMaterialGroups();

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
          () => dataSource.getMaterialGroups(),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getMaterialGroupById', () {
      test('returns MaterialGroupModel on successful response', () async {
        // GIVEN
        final json = givenMaterialGroupJson(id: 1, title: 'Textbooks');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getMaterialGroupById(1);

        // THEN
        verifyMaterialGroupMatchesJson(result, json);
      });
    });

    group('createMaterialGroup', () {
      test('returns created MaterialGroupModel on 201 response', () async {
        // GIVEN
        final json = givenMaterialGroupJson(id: 1, title: 'New Group');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = MaterialGroupRequestModel(
          title: 'New Group',
          shownOnCalendar: true,
        );

        // WHEN
        final result = await dataSource.createMaterialGroup(request);

        // THEN
        expect(result.title, equals('New Group'));
      });
    });

    group('updateMaterialGroup', () {
      test('returns updated MaterialGroupModel on 200 response', () async {
        // GIVEN
        final json = givenMaterialGroupJson(id: 1, title: 'Updated Group');
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = MaterialGroupRequestModel(
          title: 'Updated Group',
          shownOnCalendar: false,
        );

        // WHEN
        final result = await dataSource.updateMaterialGroup(1, request);

        // THEN
        expect(result.title, equals('Updated Group'));
      });
    });

    group('deleteMaterialGroup', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteMaterialGroup(1), completes);
      });
    });

    group('getMaterials', () {
      test('returns list of MaterialModel on successful response', () async {
        // GIVEN
        final materialsJson = [
          givenMaterialJson(id: 1, title: 'Textbook'),
          givenMaterialJson(id: 2, title: 'Calculator'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(materialsJson));

        // WHEN
        final result = await dataSource.getMaterials();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('Textbook'));
        expect(result[1].title, equals('Calculator'));
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
        await dataSource.getMaterials(groupId: 5);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'material_group': 5}),
        ).called(1);
      });

      test('parses material with courses correctly', () async {
        // GIVEN
        final materialsJson = [
          givenMaterialJson(id: 1, courses: [1, 2, 3]),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(materialsJson));

        // WHEN
        final result = await dataSource.getMaterials();

        // THEN
        expect(result[0].courses, equals([1, 2, 3]));
      });

      test('parses material status and condition', () async {
        // GIVEN
        final materialsJson = [
          givenMaterialJson(id: 1, status: 1, condition: 2),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(materialsJson));

        // WHEN
        final result = await dataSource.getMaterials();

        // THEN
        expect(result[0].status, equals(1));
        expect(result[0].condition, equals(2));
      });
    });

    group('getMaterialById', () {
      test('returns MaterialModel on successful response', () async {
        // GIVEN
        final json = givenMaterialJson(id: 1, title: 'Textbook');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getMaterialById(1, 1);

        // THEN
        verifyMaterialMatchesJson(result, json);
      });
    });

    group('createMaterial', () {
      test('returns created MaterialModel on 201 response', () async {
        // GIVEN
        final json = givenMaterialJson(id: 1, title: 'New Material');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = MaterialRequestModel(
          title: 'New Material',
          status: 0,
          condition: 0,
          website: '',
          price: '',
          details: '',
          courses: [1],
          materialGroup: 1,
        );

        // WHEN
        final result = await dataSource.createMaterial(1, request);

        // THEN
        expect(result.title, equals('New Material'));
      });
    });

    group('updateMaterial', () {
      test('returns updated MaterialModel on 200 response', () async {
        // GIVEN
        final json = givenMaterialJson(id: 1, title: 'Updated Material');
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = MaterialRequestModel(
          title: 'Updated Material',
          status: 1,
          condition: 1,
          website: '',
          price: '',
          details: '',
          courses: [1, 2],
          materialGroup: 1,
        );

        // WHEN
        final result = await dataSource.updateMaterial(1, 1, request);

        // THEN
        expect(result.title, equals('Updated Material'));
      });
    });

    group('deleteMaterial', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteMaterial(1, 1), completes);
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(
          () => dataSource.getMaterialGroups(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws ServerException on 500 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenServerException());

        // WHEN/THEN
        expect(
          () => dataSource.getMaterialGroupById(1),
          throwsA(isA<ServerException>()),
        );
      });
    });
  });
}
