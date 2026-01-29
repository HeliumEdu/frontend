// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
// Conditional import - uses web implementation on web, mobile on native platforms
import 'package:heliumapp/utils/storage_helpers_mobile.dart'
    if (dart.library.js_interop) 'package:heliumapp/utils/storage_helpers_web.dart';

final log = Logger('HeliumLogger');

class HeliumStorage {
  /// - Android 13+: Requests READ_MEDIA_* permissions for accessing gallery files
  /// - Android <13: Requests READ_EXTERNAL_STORAGE for accessing files
  /// - iOS/Web: No permissions needed
  static Future<bool> requestStoragePermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      final DeviceInfoPlugin plugin = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await plugin.androidInfo;
      final int sdkVersion = androidInfo.version.sdkInt;

      if (sdkVersion >= 33) {
        // Android 13+ uses granular media permissions for file picking
        final photoStatus = await Permission.photos.request();
        final videoStatus = await Permission.videos.request();
        final audioStatus = await Permission.audio.request();

        return photoStatus.isGranted ||
            videoStatus.isGranted ||
            audioStatus.isGranted;
      } else {
        // Android <13 uses legacy storage permission for file picking
        final status = await Permission.storage.request();
        if (status.isGranted) {
          log.info('Storage permission granted for older Android');
          return true;
        } else if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return status.isGranted;
      }
    } else {
      // iOS and web don't need additional permissions
      return true;
    }
  }

  static Future<bool> requestDownloadPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      final DeviceInfoPlugin plugin = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await plugin.androidInfo;
      final int sdkVersion = androidInfo.version.sdkInt;

      // Android 10+ uses scoped storage, no permission needed
      if (sdkVersion >= 29) {
        return true;
      }

      // Android < 10 needs WRITE_EXTERNAL_STORAGE
      final status = await Permission.storage.request();
      if (status.isGranted) {
        log.info('Write permission granted for downloads');
        return true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return status.isGranted;
    } else {
      // iOS and web don't need download permissions
      return true;
    }
  }

  static Future<bool> downloadFile(
    String url,
    String filename,
  ) async {
    try {
      return await downloadFilePlatform(url, filename);
    } catch (e) {
      log.severe('An error occurred during file download: $e');
      return false;
    }
  }
}
