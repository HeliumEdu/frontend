// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/info_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late InfoRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = InfoRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('InfoRemoteDataSource', () {
    group('getInfo', () {
      test('returns InfoModel on 200 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenAnswer(
          (_) async => givenSuccessResponse(<String, dynamic>{
            'name': 'helium-platform',
            'version': '3.5.20',
            'max_upload_size': 20971520,
            'access_token_lifetime_minutes': 60,
            'refresh_token_lifetime_days': 14,
            'oauth_providers': ['google', 'apple'],
            'import_file_types': ['json'],
          }),
        );

        // WHEN
        final result = await dataSource.getInfo();

        // THEN
        expect(result.maxUploadSize, equals(20971520));
        expect(result.importFileTypes, equals(['json']));
      });

      test('throws ServerException on 500 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenServerException());

        // WHEN/THEN
        expect(
          () => dataSource.getInfo(),
          throwsA(isA<ServerException>()),
        );
      });
    });
  });
}
