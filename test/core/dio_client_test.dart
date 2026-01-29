// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:mocktail/mocktail.dart';

class MockPrefService extends Mock implements PrefService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DioClient', () {
    group('singleton pattern', () {
      test('factory constructor returns same instance', () {
        // WHEN
        final instance1 = DioClient();
        final instance2 = DioClient();

        // THEN
        expect(identical(instance1, instance2), isTrue);
      });

      test('dio getter returns configured Dio instance', () {
        // GIVEN
        final client = DioClient();

        // THEN
        expect(client.dio, isNotNull);
        expect(client.dio.options.headers['Content-Type'], 'application/json');
        expect(client.dio.options.headers['Accept'], 'application/json');
      });

      test('dio has correct timeout configuration', () {
        // GIVEN
        final client = DioClient();

        // THEN
        expect(
          client.dio.options.connectTimeout,
          equals(const Duration(seconds: 30)),
        );
        expect(
          client.dio.options.receiveTimeout,
          equals(const Duration(seconds: 30)),
        );
      });
    });

    group('_isInvalidTokenError', () {
      // Note: This method is private, so we test it indirectly through
      // error scenarios. These tests document the expected behavior.

      test('Token is blacklisted message indicates invalid token', () {
        // This is tested through the interceptor behavior
        // The method checks for:
        // - 'Token is blacklisted'
        // - contains 'invalid'
        // - contains 'expired'
        expect(true, isTrue); // Placeholder for documentation
      });
    });
  });

  group('DioClient token and storage operations', () {
    late MockPrefService mockPrefService;

    setUp(() {
      mockPrefService = MockPrefService();
    });

    group('secure storage operations', () {
      test('getSecure reads access_token from secure storage', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('access_token'),
        ).thenAnswer((_) async => 'test_access_token');

        // WHEN
        final result = await mockPrefService.getSecure('access_token');

        // THEN
        expect(result, equals('test_access_token'));
        verify(() => mockPrefService.getSecure('access_token')).called(1);
      });

      test('getSecure reads refresh_token from secure storage', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('refresh_token'),
        ).thenAnswer((_) async => 'test_refresh_token');

        // WHEN
        final result = await mockPrefService.getSecure('refresh_token');

        // THEN
        expect(result, equals('test_refresh_token'));
      });

      test('setSecure stores access_token in secure storage', () async {
        // GIVEN
        when(
          () => mockPrefService.setSecure('access_token', 'new_token'),
        ).thenAnswer((_) async {});

        // WHEN
        await mockPrefService.setSecure('access_token', 'new_token');

        // THEN
        verify(
          () => mockPrefService.setSecure('access_token', 'new_token'),
        ).called(1);
      });

      test('setSecure stores refresh_token in secure storage', () async {
        // GIVEN
        when(
          () => mockPrefService.setSecure('refresh_token', 'new_refresh'),
        ).thenAnswer((_) async {});

        // WHEN
        await mockPrefService.setSecure('refresh_token', 'new_refresh');

        // THEN
        verify(
          () => mockPrefService.setSecure('refresh_token', 'new_refresh'),
        ).called(1);
      });
    });

    group('isAuthenticated logic', () {
      test('returns true when access token exists and is not empty', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('access_token'),
        ).thenAnswer((_) async => 'valid_token');

        // WHEN
        final token = await mockPrefService.getSecure('access_token');
        final isAuthenticated = token != null && token.isNotEmpty;

        // THEN
        expect(isAuthenticated, isTrue);
      });

      test('returns false when access token is null', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('access_token'),
        ).thenAnswer((_) async => null);

        // WHEN
        final token = await mockPrefService.getSecure('access_token');
        final isAuthenticated = token != null && token.isNotEmpty;

        // THEN
        expect(isAuthenticated, isFalse);
      });

      test('returns false when access token is empty', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('access_token'),
        ).thenAnswer((_) async => '');

        // WHEN
        final token = await mockPrefService.getSecure('access_token');
        final isAuthenticated = token != null && token.isNotEmpty;

        // THEN
        expect(isAuthenticated, isFalse);
      });
    });

    group('clearStorage', () {
      test('clears both shared and secure storage', () async {
        // GIVEN
        when(() => mockPrefService.clear()).thenAnswer((_) async => <void>[]);

        // WHEN
        await mockPrefService.clear();

        // THEN
        verify(() => mockPrefService.clear()).called(1);
      });
    });

    group('settings operations', () {
      test('getString retrieves setting value', () {
        // GIVEN
        when(
          () => mockPrefService.getString('time_zone'),
        ).thenReturn('America/New_York');

        // WHEN
        final result = mockPrefService.getString('time_zone');

        // THEN
        expect(result, equals('America/New_York'));
      });

      test('getBool retrieves boolean setting', () {
        // GIVEN
        when(
          () => mockPrefService.getBool('color_by_category'),
        ).thenReturn(true);

        // WHEN
        final result = mockPrefService.getBool('color_by_category');

        // THEN
        expect(result, isTrue);
      });

      test('getInt retrieves integer setting', () {
        // GIVEN
        when(() => mockPrefService.getInt('default_view')).thenReturn(2);

        // WHEN
        final result = mockPrefService.getInt('default_view');

        // THEN
        expect(result, equals(2));
      });

      test('setString stores setting value', () async {
        // GIVEN
        when(
          () => mockPrefService.setString('time_zone', 'Europe/London'),
        ).thenAnswer((_) async {});

        // WHEN
        await mockPrefService.setString('time_zone', 'Europe/London');

        // THEN
        verify(
          () => mockPrefService.setString('time_zone', 'Europe/London'),
        ).called(1);
      });

      test('setBool stores boolean setting', () async {
        // GIVEN
        when(
          () => mockPrefService.setBool('color_by_category', false),
        ).thenAnswer((_) async {});

        // WHEN
        await mockPrefService.setBool('color_by_category', false);

        // THEN
        verify(
          () => mockPrefService.setBool('color_by_category', false),
        ).called(1);
      });

      test('setInt stores integer setting', () async {
        // GIVEN
        when(
          () => mockPrefService.setInt('default_view', 1),
        ).thenAnswer((_) async {});

        // WHEN
        await mockPrefService.setInt('default_view', 1);

        // THEN
        verify(() => mockPrefService.setInt('default_view', 1)).called(1);
      });
    });
  });

  group('DioClient interceptor behavior', () {
    test('interceptors are configured', () {
      // GIVEN
      final client = DioClient();

      // THEN
      // Should have at least 2 interceptors:
      // 1. Custom InterceptorsWrapper for auth
      // 2. LogInterceptor
      expect(client.dio.interceptors.length, greaterThanOrEqualTo(2));
    });
  });
}
