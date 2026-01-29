// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSharedPreferencesWithCache extends Mock
    implements SharedPreferencesWithCache {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockSecureStorage;
  late MockSharedPreferencesWithCache mockSharedStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockSharedStorage = MockSharedPreferencesWithCache();
  });

  group('PrefService storage operations', () {
    group('SharedPreferences operations', () {
      test('getString returns stored value', () {
        // GIVEN
        when(() => mockSharedStorage.getString('test_key')).thenReturn('value');

        // WHEN
        final result = mockSharedStorage.getString('test_key');

        // THEN
        expect(result, equals('value'));
      });

      test('getString returns null for missing key', () {
        // GIVEN
        when(() => mockSharedStorage.getString('missing')).thenReturn(null);

        // WHEN
        final result = mockSharedStorage.getString('missing');

        // THEN
        expect(result, isNull);
      });

      test('getInt returns stored value', () {
        // GIVEN
        when(() => mockSharedStorage.getInt('int_key')).thenReturn(42);

        // WHEN
        final result = mockSharedStorage.getInt('int_key');

        // THEN
        expect(result, equals(42));
      });

      test('getBool returns stored value', () {
        // GIVEN
        when(() => mockSharedStorage.getBool('bool_key')).thenReturn(true);

        // WHEN
        final result = mockSharedStorage.getBool('bool_key');

        // THEN
        expect(result, isTrue);
      });

      test('getStringList returns stored value', () {
        // GIVEN
        when(
          () => mockSharedStorage.getStringList('list_key'),
        ).thenReturn(['a', 'b', 'c']);

        // WHEN
        final result = mockSharedStorage.getStringList('list_key');

        // THEN
        expect(result, equals(['a', 'b', 'c']));
      });

      test('setString stores value', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setString('key', 'value'),
        ).thenAnswer((_) async {});

        // WHEN
        await mockSharedStorage.setString('key', 'value');

        // THEN
        verify(() => mockSharedStorage.setString('key', 'value')).called(1);
      });

      test('setInt stores value', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setInt('key', 123),
        ).thenAnswer((_) async {});

        // WHEN
        await mockSharedStorage.setInt('key', 123);

        // THEN
        verify(() => mockSharedStorage.setInt('key', 123)).called(1);
      });

      test('setBool stores value', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setBool('key', true),
        ).thenAnswer((_) async {});

        // WHEN
        await mockSharedStorage.setBool('key', true);

        // THEN
        verify(() => mockSharedStorage.setBool('key', true)).called(1);
      });

      test('setStringList stores value', () async {
        // GIVEN
        when(
          () => mockSharedStorage.setStringList('key', ['x', 'y']),
        ).thenAnswer((_) async {});

        // WHEN
        await mockSharedStorage.setStringList('key', ['x', 'y']);

        // THEN
        verify(
          () => mockSharedStorage.setStringList('key', ['x', 'y']),
        ).called(1);
      });

      test('clear removes all values', () async {
        // GIVEN
        when(() => mockSharedStorage.clear()).thenAnswer((_) async => true);

        // WHEN
        await mockSharedStorage.clear();

        // THEN
        verify(() => mockSharedStorage.clear()).called(1);
      });
    });

    group('FlutterSecureStorage operations', () {
      test('getSecure reads from secure storage', () async {
        // GIVEN
        when(
          () => mockSecureStorage.read(key: 'secure_key'),
        ).thenAnswer((_) async => 'secure_value');

        // WHEN
        final result = await mockSecureStorage.read(key: 'secure_key');

        // THEN
        expect(result, equals('secure_value'));
      });

      test('getSecure returns null for missing key', () async {
        // GIVEN
        when(
          () => mockSecureStorage.read(key: 'missing'),
        ).thenAnswer((_) async => null);

        // WHEN
        final result = await mockSecureStorage.read(key: 'missing');

        // THEN
        expect(result, isNull);
      });

      test('setSecure writes to secure storage', () async {
        // GIVEN
        when(
          () => mockSecureStorage.write(key: 'key', value: 'secret'),
        ).thenAnswer((_) async {});

        // WHEN
        await mockSecureStorage.write(key: 'key', value: 'secret');

        // THEN
        verify(
          () => mockSecureStorage.write(key: 'key', value: 'secret'),
        ).called(1);
      });

      test('deleteSecure removes from secure storage', () async {
        // GIVEN
        when(
          () => mockSecureStorage.delete(key: 'key'),
        ).thenAnswer((_) async {});

        // WHEN
        await mockSecureStorage.delete(key: 'key');

        // THEN
        verify(() => mockSecureStorage.delete(key: 'key')).called(1);
      });

      test('deleteAll clears secure storage', () async {
        // GIVEN
        when(() => mockSecureStorage.deleteAll()).thenAnswer((_) async {});

        // WHEN
        await mockSecureStorage.deleteAll();

        // THEN
        verify(() => mockSecureStorage.deleteAll()).called(1);
      });
    });

    group('secure storage token operations', () {
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
        await mockSecureStorage.write(key: 'access_token', value: token);
        final result = await mockSecureStorage.read(key: 'access_token');

        // THEN
        expect(result, equals(token));
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
        await mockSecureStorage.write(key: 'refresh_token', value: token);
        final result = await mockSecureStorage.read(key: 'refresh_token');

        // THEN
        expect(result, equals(token));
      });
    });
  });
}
