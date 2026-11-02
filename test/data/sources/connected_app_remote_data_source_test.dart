import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/connected_app_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late ConnectedAppRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late MockCacheService mockCacheService;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    mockCacheService = MockCacheService();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    when(() => mockDioClient.cacheService).thenReturn(mockCacheService);
    dataSource = ConnectedAppRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('ConnectedAppRemoteDataSource', () {
    group('getConnectedApps', () {
      test('returns the connected apps on 200 response', () async {
        // GIVEN
        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenAnswer(
          (_) async => givenSuccessResponse([
            {
              'id': 7,
              'name': 'Claude',
              'scopes': [
                {'scope': 'planner:read', 'description': 'Read your planner'},
              ],
              'last_used_at': '2026-11-01T15:30:00Z',
            },
            {'id': 8, 'name': 'Other', 'scopes': [], 'last_used_at': null},
          ]),
        );

        // WHEN
        final result = await dataSource.getConnectedApps();

        // THEN
        expect(result.map((app) => app.id), [7, 8]);
        expect(result.first.name, 'Claude');
        expect(result.first.scopes.single.scope, 'planner:read');
        expect(result.first.lastUsedAt, DateTime.utc(2026, 11, 1, 15, 30));
        expect(result.last.lastUsedAt, isNull);
      });

      test('throws NetworkException on a connection error', () async {
        // GIVEN
        when(
          () => mockDio.get(any(), options: any(named: 'options')),
        ).thenThrow(
          givenDioException(type: DioExceptionType.connectionError),
        );

        // WHEN/THEN
        expect(
          dataSource.getConnectedApps(),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('revokeConnectedApp', () {
      test('deletes the connected app on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN
        await dataSource.revokeConnectedApp(connectedAppId: 7);

        // THEN
        verify(() => mockDio.delete('/auth/user/connectedapps/7/')).called(1);
      });
    });
  });
}
