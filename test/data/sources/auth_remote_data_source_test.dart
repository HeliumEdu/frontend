// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/auth/request/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/request/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../helpers/auth_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class _FakeUserSettingsModel extends Fake implements UserSettingsModel {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(Uri());
    registerFallbackValue(_FakeUserSettingsModel());
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    when(() => mockDioClient.saveTokens(any(), any())).thenAnswer((_) async {});
    when(
      () => mockDioClient.saveSettings(any()),
    ).thenAnswer((_) async => <void>[]);
    when(() => mockDioClient.clearStorage()).thenAnswer((_) async => <void>[]);
    when(() => mockDioClient.getRefreshToken()).thenAnswer((_) async => null);
    dataSource = AuthRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('AuthRemoteDataSource', () {
    group('register', () {
      test('returns NoContentResponseModel on 201 response', () async {
        // GIVEN
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse({}, statusCode: 201));

        final request = RegisterRequestModel(
          email: 'newuser@test.com',
          password: 'password123',
          timezone: 'America/New_York',
        );

        // WHEN
        final result = await dataSource.register(request);

        // THEN
        expect(result.message, contains('account registered'));
      });

      test('throws ValidationException on 400 response', () async {
        // GIVEN
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          givenValidationException({
            'email': ['This email is already taken'],
          }),
        );

        final request = RegisterRequestModel(
          email: 'existing@test.com',
          password: 'password123',
          timezone: 'America/New_York',
        );

        // WHEN/THEN
        expect(
          () => dataSource.register(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('refreshToken', () {
      test('returns TokenResponseModel on 200 response', () async {
        // GIVEN
        final json = givenTokenResponseJson(
          access: 'new_access_token',
          refresh: 'new_refresh_token',
        );
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = RefreshTokenRequestModel(refresh: 'old_refresh_token');

        // WHEN
        final result = await dataSource.refreshToken(request);

        // THEN
        verifyTokenResponseMatchesJson(result, json);
        verify(
          () =>
              mockDioClient.saveTokens('new_access_token', 'new_refresh_token'),
        ).called(1);
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
          givenUnauthorizedException(message: 'Token is blacklisted'),
        );

        final request = RefreshTokenRequestModel(refresh: 'invalid_token');

        // WHEN/THEN
        expect(
          () => dataSource.refreshToken(request),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });

    group('getUser', () {
      test('returns UserModel on 200 response', () async {
        // GIVEN
        final json = givenUserJson(id: 1, email: 'test@heliumedu.com');
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getUser();

        // THEN
        verifyUserMatchesJson(result, json);
      });

      test('parses nested settings correctly', () async {
        // GIVEN
        final settingsJson = givenUserSettingsJson(
          timeZone: 'Europe/London',
          colorByCategory: true,
        );
        final json = givenUserJson(settings: settingsJson);
        when(
          () => mockDio.get(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.getUser();

        // THEN
        expect(result.settings, isNotNull);
        expect(result.settings.timeZone.name, equals('Europe/London'));
        expect(result.settings.colorByCategory, isTrue);
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getUser(),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });

    group('logout', () {
      test('clears storage on logout', () async {
        // GIVEN
        when(
          () => mockDioClient.getRefreshToken(),
        ).thenAnswer((_) async => null);

        // WHEN
        await dataSource.logout();

        // THEN
        verify(() => mockDioClient.clearStorage()).called(1);
      });

      test('blacklists refresh token if available', () async {
        // GIVEN
        when(
          () => mockDioClient.getRefreshToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockDio.post(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse({}));

        // WHEN
        await dataSource.logout();

        // THEN
        verify(() => mockDioClient.clearStorage()).called(1);
        verify(
          () => mockDio.post(any(), data: {'refresh': 'valid_token'}),
        ).called(1);
      });
    });

    group('enablePrivateFeeds', () {
      test('returns PrivateFeedModel on 200 response', () async {
        // GIVEN
        final json = givenPrivateFeedJson();
        when(
          () => mockDio.put(any()),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        // WHEN
        final result = await dataSource.enablePrivateFeeds();

        // THEN
        verifyPrivateFeedMatchesJson(result, json);
      });
    });

    group('disablePrivateFeeds', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.put(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.disablePrivateFeeds(), completes);
      });
    });

    group('deleteAccount', () {
      test(
        'returns NoContentResponseModel and clears storage on 204',
        () async {
          // GIVEN
          when(
            () => mockDio.delete(any(), data: any(named: 'data')),
          ).thenAnswer(
            (_) async => givenSuccessResponse(null, statusCode: 204),
          );

          final request = DeleteAccountRequestModel(password: 'password123');

          // WHEN
          final result = await dataSource.deleteAccount(request);

          // THEN
          expect(result.message, contains('deleted'));
          verify(() => mockDioClient.clearStorage()).called(1);
        },
      );
    });

    group('changePassword', () {
      test('returns UserModel on 200 response', () async {
        // GIVEN
        final json = givenUserJson();
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse(json));

        final request = ChangePasswordRequestModel(
          oldPassword: 'old_password',
          password: 'new_password',
        );

        // WHEN
        final result = await dataSource.changePassword(request);

        // THEN
        verifyUserMatchesJson(result, json);
      });

      test('throws ValidationException on wrong current password', () async {
        // GIVEN
        when(() => mockDio.put(any(), data: any(named: 'data'))).thenThrow(
          givenValidationException({
            'current_password': ['Current password is incorrect'],
          }),
        );

        final request = ChangePasswordRequestModel(
          oldPassword: 'wrong_password',
          password: 'new_password',
        );

        // WHEN/THEN
        expect(
          () => dataSource.changePassword(request),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('forgotPassword', () {
      test('returns NoContentResponseModel on 202 response', () async {
        // GIVEN
        when(
          () => mockDio.put(any(), data: any(named: 'data')),
        ).thenAnswer((_) async => givenSuccessResponse({}, statusCode: 202));

        final request = ForgotPasswordRequestModel(email: 'user@test.com');

        // WHEN
        final result = await dataSource.forgotPassword(request);

        // THEN
        expect(result.message, contains('email sent'));
      });
    });

    group('error handling', () {
      test('throws ServerException on 500 response', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenServerException());

        // WHEN/THEN
        expect(() => dataSource.getUser(), throwsA(isA<ServerException>()));
      });

      test('throws NetworkException on timeout', () async {
        // GIVEN
        when(() => mockDio.get(any())).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(() => dataSource.getUser(), throwsA(isA<NetworkException>()));
      });
    });
  });
}
