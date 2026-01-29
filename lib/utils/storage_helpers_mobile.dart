// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

final log = Logger('HeliumLogger');

/// Mobile download with platform-specific behavior:
/// - Android: Saves to Downloads folder (accessible to user)
/// - iOS: Saves to app Documents directory and opens share sheet (iOS doesn't have public Downloads)
Future<bool> downloadFilePlatform(String url, String filename) async {
  try {
    if (Platform.isAndroid) {
      return await _downloadFileAndroid(url, filename);
    } else if (Platform.isIOS) {
      return await _downloadFileIOS(url, filename);
    } else {
      log.warning('Unsupported platform for download');
      return false;
    }
  } catch (e) {
    log.severe('Mobile download failed: $e');
    return false;
  }
}

/// Android: Download directly to public Downloads folder
Future<bool> _downloadFileAndroid(String url, String filename) async {
  try {
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await plugin.androidInfo;
    final int sdkVersion = androidInfo.version.sdkInt;

    log.info('Android SDK version: $sdkVersion');

    // Request permission for older Android versions
    if (sdkVersion < 29) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        log.warning('Storage permission denied for downloads');
        return false;
      }
    }

    // Use the PUBLIC Downloads directory
    // Works on all Android versions with requestLegacyExternalStorage flag
    final downloadsDir = Directory('/storage/emulated/0/Download');
    log.info('Public Downloads directory: ${downloadsDir.path}');

    // Create Downloads directory if it doesn't exist
    if (!await downloadsDir.exists()) {
      log.info('Public Downloads directory does not exist, creating...');
      try {
        await downloadsDir.create(recursive: true);
      } catch (e) {
        log.warning('Could not create public Downloads directory: $e');
        log.warning('This may require storage permissions');
        return false;
      }
    }

    final filePath = '${downloadsDir.path}/$filename';
    log.info('Attempting download to PUBLIC Downloads: $filePath');

    final response = await Dio().download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          log.info(
            'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
          );
        }
      },
    );

    if (response.statusCode != 200) {
      log.warning('Download failed with status: ${response.statusCode}');
      return false;
    }

    // Verify the file was created
    final file = File(filePath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;

    log.info('Download complete:');
    log.info('  Path: $filePath');
    log.info('  File exists: $exists');
    log.info('  File size: $size bytes');

    return exists;
  } catch (e) {
    log.severe('Android download failed: $e');
    return false;
  }
}

/// iOS: Download to app Documents and open share sheet
/// (iOS doesn't have a user-accessible Downloads folder)
Future<bool> _downloadFileIOS(String url, String filename) async {
  try {
    // Download to app's Documents directory (accessible via Files app)
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDocDir.path}/$filename';

    log.info('Downloading to app documents: $filePath');

    final response = await Dio().download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          log.info(
            'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
          );
        }
      },
    );

    if (response.statusCode != 200) {
      log.warning('Download failed with status: ${response.statusCode}');
      return false;
    }

    // On iOS, open share sheet so user can save to Files or share
    // Provide a default center position for iPad popover (required on iOS)
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Save $filename',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      ),
    );

    log.info('iOS share sheet result: ${result.status}');
    return true;
  } catch (e) {
    log.severe('iOS download failed: $e');
    return false;
  }
}
