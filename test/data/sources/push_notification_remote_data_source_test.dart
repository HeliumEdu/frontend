// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/push_notification_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/notification_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late PushTokenRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = PushTokenRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('PushNotificationRemoteDataSource', () {
    group('registerPushToken', () {
      test('returns PushTokenModel on 201 response', () async {
        // GIVEN
        final json = givenPushTokenJson(id: 1, deviceId: 'device_123');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json, statusCode: 201));

        final request = givenPushTokenRequestModel();

        // WHEN
        final result = await dataSource.registerPushToken(request);

        // THEN
        verifyPushTokenMatchesJson(result, json);
      });

      test('throws ServerException on non-201 response', () async {
        // GIVEN
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse({}, statusCode: 400));

        final request = givenPushTokenRequestModel();

        // WHEN/THEN
        expect(
          () => dataSource.registerPushToken(request),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('retrievePushTokens', () {
      test(
        'returns list of PushTokenModel on successful list response',
        () async {
          // GIVEN
          final tokensJson = [
            givenPushTokenJson(id: 1, deviceId: 'device_1'),
            givenPushTokenJson(id: 2, deviceId: 'device_2'),
          ];
          when(
            () => mockDio.get(any()),
          ).thenAnswer((_) async => givenSuccessResponse(tokensJson));

          // WHEN
          final result = await dataSource.retrievePushTokens();

          // THEN
          expect(result.length, equals(2));
          expect(result[0].deviceId, equals('device_1'));
          expect(result[1].deviceId, equals('device_2'));
        },
      );

      test('returns empty list when response is empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.retrievePushTokens();

        // THEN
        expect(result, isEmpty);
      });
    });

    group('deletePushToken', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deletePushToken(1), completes);
      });

      test('throws HeliumException on non-204 response', () async {
        // GIVEN
        when(() => mockDio.delete(any())).thenAnswer(
          (_) async => givenSuccessResponse({
            'detail': 'Token not found',
          }, statusCode: 404),
        );

        // WHEN/THEN
        expect(
          () => dataSource.deletePushToken(1),
          throwsA(isA<HeliumException>()),
        );
      });
    });

    group('deletePushTokenById', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deletePushTokenById(1), completes);
      });

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deletePushTokenById(1),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenThrow(givenNetworkException());

        final request = givenPushTokenRequestModel();

        // WHEN/THEN
        expect(
          () => dataSource.registerPushToken(request),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.retrievePushTokens(),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
