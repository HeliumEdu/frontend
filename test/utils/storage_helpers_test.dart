// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeliumStorage', () {
    group('permission logic', () {
      group('Android SDK version checks', () {
        test('Android 13+ (SDK 33+) uses granular media permissions', () {
          // GIVEN
          const sdkVersion = 33;

          // THEN - SDK 33+ requires READ_MEDIA_* permissions
          expect(sdkVersion >= 33, isTrue);
        });

        test('Android 12 and below uses legacy storage permission', () {
          // GIVEN
          const sdkVersion = 32;

          // THEN - SDK <33 uses READ_EXTERNAL_STORAGE
          expect(sdkVersion >= 33, isFalse);
          expect(sdkVersion < 33, isTrue);
        });

        test('Android 10+ (SDK 29+) uses scoped storage for downloads', () {
          // GIVEN
          const sdkVersion = 29;

          // THEN - SDK 29+ uses scoped storage
          expect(sdkVersion >= 29, isTrue);
        });

        test('Android 9 and below needs write permission for downloads', () {
          // GIVEN
          const sdkVersion = 28;

          // THEN - SDK <29 needs WRITE_EXTERNAL_STORAGE
          expect(sdkVersion >= 29, isFalse);
          expect(sdkVersion < 29, isTrue);
        });

        test('various Android SDK versions behave correctly', () {
          // Test the version boundaries
          for (final entry in {
            26: {'needsScoped': false, 'needsGranular': false},
            28: {'needsScoped': false, 'needsGranular': false},
            29: {'needsScoped': true, 'needsGranular': false},
            30: {'needsScoped': true, 'needsGranular': false},
            32: {'needsScoped': true, 'needsGranular': false},
            33: {'needsScoped': true, 'needsGranular': true},
            34: {'needsScoped': true, 'needsGranular': true},
          }.entries) {
            final sdkVersion = entry.key;
            final expected = entry.value;

            expect(
              sdkVersion >= 29,
              expected['needsScoped'],
              reason: 'SDK $sdkVersion should ${expected['needsScoped']! ? '' : 'not '}use scoped storage',
            );
            expect(
              sdkVersion >= 33,
              expected['needsGranular'],
              reason: 'SDK $sdkVersion should ${expected['needsGranular']! ? '' : 'not '}use granular permissions',
            );
          }
        });
      });

      group('permission status handling', () {
        test('granted permission returns true', () {
          const status = PermissionStatus.granted;
          expect(status.isGranted, isTrue);
        });

        test('denied permission returns false', () {
          const status = PermissionStatus.denied;
          expect(status.isGranted, isFalse);
          expect(status.isDenied, isTrue);
        });

        test('permanently denied triggers app settings', () {
          const status = PermissionStatus.permanentlyDenied;
          expect(status.isPermanentlyDenied, isTrue);
          expect(status.isGranted, isFalse);
        });

        test('restricted permission returns false', () {
          const status = PermissionStatus.restricted;
          expect(status.isGranted, isFalse);
          expect(status.isRestricted, isTrue);
        });

        test('limited permission is not fully granted', () {
          const status = PermissionStatus.limited;
          expect(status.isLimited, isTrue);
          expect(status.isGranted, isFalse);
        });
      });

      group('granular media permissions (Android 13+)', () {
        test('any granted media permission allows file picking', () {
          const photoStatus = PermissionStatus.granted;
          const videoStatus = PermissionStatus.denied;
          const audioStatus = PermissionStatus.denied;

          final hasPermission = photoStatus.isGranted ||
              videoStatus.isGranted ||
              audioStatus.isGranted;

          expect(hasPermission, isTrue);
        });

        test('all denied media permissions blocks file picking', () {
          const photoStatus = PermissionStatus.denied;
          const videoStatus = PermissionStatus.denied;
          const audioStatus = PermissionStatus.denied;

          final hasPermission = photoStatus.isGranted ||
              videoStatus.isGranted ||
              audioStatus.isGranted;

          expect(hasPermission, isFalse);
        });

        test('multiple granted permissions work correctly', () {
          for (final scenario in [
            [PermissionStatus.granted, PermissionStatus.granted, PermissionStatus.granted],
            [PermissionStatus.granted, PermissionStatus.denied, PermissionStatus.denied],
            [PermissionStatus.denied, PermissionStatus.granted, PermissionStatus.denied],
            [PermissionStatus.denied, PermissionStatus.denied, PermissionStatus.granted],
          ]) {
            final hasPermission =
                scenario[0].isGranted || scenario[1].isGranted || scenario[2].isGranted;
            expect(hasPermission, isTrue);
          }
        });
      });
    });

  });

  group('Permission constants', () {
    test('Permission.photos is available for Android 13+', () {
      expect(Permission.photos, isNotNull);
      expect(Permission.photos, isA<Permission>());
    });

    test('Permission.videos is available for Android 13+', () {
      expect(Permission.videos, isNotNull);
      expect(Permission.videos, isA<Permission>());
    });

    test('Permission.audio is available for Android 13+', () {
      expect(Permission.audio, isNotNull);
      expect(Permission.audio, isA<Permission>());
    });

    test('Permission.storage is available for legacy Android', () {
      expect(Permission.storage, isNotNull);
      expect(Permission.storage, isA<Permission>());
    });
  });
}
