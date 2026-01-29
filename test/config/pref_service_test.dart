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

    });
  });
}
