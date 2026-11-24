import 'package:flutter/services.dart';
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
    group('isSecureStorageLocked', () {
      test('the keychain refusing reads while the device is locked counts as locked', () async {
        // GIVEN
        when(() => mockSecureStorage.read(key: 'access_token')).thenThrow(
          PlatformException(code: 'Unexpected security result code', message: 'Code: -25308'),
        );

        // WHEN
        final locked = await prefService.isSecureStorageLocked();

        // THEN
        expect(locked, isTrue);
      });

      test('a readable keychain with no token is not locked', () async {
        // GIVEN
        when(() => mockSecureStorage.read(key: 'access_token')).thenAnswer((_) async => null);

        // WHEN
        final locked = await prefService.isSecureStorageLocked();

        // THEN
        expect(locked, isFalse);
      });

      test('other keychain errors are not mistaken for a locked device', () async {
        // GIVEN
        when(() => mockSecureStorage.read(key: 'access_token')).thenThrow(
          PlatformException(code: 'Unexpected security result code', message: 'Code: -34018'),
        );

        // WHEN
        final locked = await prefService.isSecureStorageLocked();

        // THEN
        expect(locked, isFalse);
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
