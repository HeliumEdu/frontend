// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockSecureStorage;
  late MockSharedPreferencesWithCache mockSharedStorage;
  late PrefService prefService;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockSharedStorage = MockSharedPreferencesWithCache();

    prefService = PrefService.forTesting(
      secureStorage: mockSecureStorage,
      sharedStorage: mockSharedStorage,
    );
  });

  tearDown(() {
    PrefService.resetForTesting();
  });

  group('PrefService', () {
    group('initialization', () {
      test('forTesting constructor sets isInitialized to true', () {
        expect(prefService.isInitialized, isTrue);
      });

      test('resetForTesting resets the instance', () {
        // GIVEN
        PrefService.setInstanceForTesting(prefService);
        expect(PrefService().isInitialized, isTrue);

        // WHEN
        PrefService.resetForTesting();

        // THEN
        expect(PrefService().isInitialized, isFalse);
      });
    });

    group('SharedPreferences operations via PrefService', () {
      test('getString delegates to SharedPreferencesWithCache', () {
        // GIVEN
        when(() => mockSharedStorage.getString('test_key')).thenReturn('value');

        // WHEN
        final result = prefService.getString('test_key');

        // THEN
        expect(result, equals('value'));
        verify(() => mockSharedStorage.getString('test_key')).called(1);
      });

      test('getString returns null for missing key', () {
        // GIVEN
        when(() => mockSharedStorage.getString('missing')).thenReturn(null);

        // WHEN
        final result = prefService.getString('missing');

        // THEN
        expect(result, isNull);
      });

      test('getInt delegates to SharedPreferencesWithCache', () {
        // GIVEN
        when(() => mockSharedStorage.getInt('int_key')).thenReturn(42);

        // WHEN
        final result = prefService.getInt('int_key');

        // THEN
        expect(result, equals(42));
        verify(() => mockSharedStorage.getInt('int_key')).called(1);
      });

      test('getBool delegates to SharedPreferencesWithCache', () {
        // GIVEN
        when(() => mockSharedStorage.getBool('bool_key')).thenReturn(true);

        // WHEN
        final result = prefService.getBool('bool_key');

        // THEN
        expect(result, isTrue);
        verify(() => mockSharedStorage.getBool('bool_key')).called(1);
      });

      test('getStringList delegates to SharedPreferencesWithCache', () {
        // GIVEN
        when(
          () => mockSharedStorage.getStringList('list_key'),
        ).thenReturn(['a', 'b', 'c']);

        // WHEN
        final result = prefService.getStringList('list_key');

        // THEN
        expect(result, equals(['a', 'b', 'c']));
        verify(() => mockSharedStorage.getStringList('list_key')).called(1);
      });

      test('setString delegates to SharedPreferencesWithCache', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setString('key', 'value'),
        ).thenAnswer((_) async {});

        // WHEN
        await prefService.setString('key', 'value');

        // THEN
        verify(() => mockSharedStorage.setString('key', 'value')).called(1);
      });

      test('setInt delegates to SharedPreferencesWithCache', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setInt('key', 123),
        ).thenAnswer((_) async {});

        // WHEN
        await prefService.setInt('key', 123);

        // THEN
        verify(() => mockSharedStorage.setInt('key', 123)).called(1);
      });

      test('setBool delegates to SharedPreferencesWithCache', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setBool('key', true),
        ).thenAnswer((_) async {});

        // WHEN
        await prefService.setBool('key', true);

        // THEN
        verify(() => mockSharedStorage.setBool('key', true)).called(1);
      });

      test('setStringList delegates to SharedPreferencesWithCache', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setStringList('key', ['x', 'y']),
        ).thenAnswer((_) async {});

        // WHEN
        await prefService.setStringList('key', ['x', 'y']);

        // THEN
        verify(
          () => mockSharedStorage.setStringList('key', ['x', 'y']),
        ).called(1);
      });
    });

    group('FlutterSecureStorage operations via PrefService', () {
      test('getSecure delegates to FlutterSecureStorage', () async {
        // GIVEN
        when(
          () => mockSecureStorage.read(key: 'secure_key'),
        ).thenAnswer((_) async => 'secure_value');

        // WHEN
        final result = await prefService.getSecure('secure_key');

        // THEN
        expect(result, equals('secure_value'));
        verify(() => mockSecureStorage.read(key: 'secure_key')).called(1);
      });

      test('getSecure returns null for missing key', () async {
        // GIVEN
        when(
          () => mockSecureStorage.read(key: 'missing'),
        ).thenAnswer((_) async => null);

        // WHEN
        final result = await prefService.getSecure('missing');

        // THEN
        expect(result, isNull);
      });

      test('setSecure delegates to FlutterSecureStorage', () async {
        // GIVEN
        when(
          () => mockSecureStorage.write(key: 'key', value: 'secret'),
        ).thenAnswer((_) async {});

        // WHEN
        await prefService.setSecure('key', 'secret');

        // THEN
        verify(
          () => mockSecureStorage.write(key: 'key', value: 'secret'),
        ).called(1);
      });

      test('deleteSecure delegates to FlutterSecureStorage', () async {
        // GIVEN
        when(
          () => mockSecureStorage.delete(key: 'key'),
        ).thenAnswer((_) async {});

        // WHEN
        await prefService.deleteSecure('key');

        // THEN
        verify(() => mockSecureStorage.delete(key: 'key')).called(1);
      });
    });

    group('clear operation', () {
      test('clear clears both SharedPreferences and SecureStorage', () async {
        // GIVEN
        when(() => mockSharedStorage.clear()).thenAnswer((_) async => true);
        when(() => mockSecureStorage.deleteAll()).thenAnswer((_) async {});

        // WHEN
        await prefService.clear();

        // THEN
        verify(() => mockSharedStorage.clear()).called(1);
        verify(() => mockSecureStorage.deleteAll()).called(1);
      });
    });

    group('token operations', () {
      test('access_token can be stored and retrieved', () async {
        // GIVEN
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test';
        when(
          () => mockSecureStorage.write(key: 'access_token', value: token),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => token);

        // WHEN
        await prefService.setSecure('access_token', token);
        final result = await prefService.getSecure('access_token');

        // THEN
        expect(result, equals(token));
        verify(
          () => mockSecureStorage.write(key: 'access_token', value: token),
        ).called(1);
        verify(() => mockSecureStorage.read(key: 'access_token')).called(1);
      });

      test('refresh_token can be stored and retrieved', () async {
        // GIVEN
        const token = 'refresh_token_value';
        when(
          () => mockSecureStorage.write(key: 'refresh_token', value: token),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorage.read(key: 'refresh_token'),
        ).thenAnswer((_) async => token);

        // WHEN
        await prefService.setSecure('refresh_token', token);
        final result = await prefService.getSecure('refresh_token');

        // THEN
        expect(result, equals(token));
      });
    });
  });
}
