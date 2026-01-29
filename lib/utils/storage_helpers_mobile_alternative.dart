// Alternative Android implementation using external storage directory
// More reliable across different Android versions and emulators

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final log = Logger('HeliumLogger');

/// Android: Download to external storage directory with Downloads subfolder
/// This is more reliable than getDownloadsDirectory() on some devices
Future<bool> downloadFileAndroidAlternative(String url, String filename) async {
  try {
    // Get external storage directory (always available on Android)
    final Directory? externalDir = await getExternalStorageDirectory();

    if (externalDir == null) {
      log.warning('Could not access external storage');
      return false;
    }

    // Navigate up to the external storage root and create Downloads folder
    // Typical path: /storage/emulated/0/Android/data/com.app/files
    // We want: /storage/emulated/0/Download
    final externalRoot = Directory('/storage/emulated/0');
    final downloadsDir = Directory('${externalRoot.path}/Download');

    log.info('External storage root: ${externalRoot.path}');
    log.info('Target downloads path: ${downloadsDir.path}');

    // Create Downloads directory if it doesn't exist
    if (!await downloadsDir.exists()) {
      log.info('Creating Downloads directory...');
      try {
        await downloadsDir.create(recursive: true);
      } catch (e) {
        log.warning('Could not create Downloads directory: $e');
        // Fallback to external storage directory
        return await _downloadToExternalStorage(url, filename, externalDir);
      }
    }

    final filePath = '${downloadsDir.path}/$filename';
    log.info('Downloading to: $filePath');

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

    // Trigger media scanner to index the file
    if (exists) {
      await _scanFile(filePath);
    }

    return exists;
  } catch (e) {
    log.severe('Android download failed: $e');
    return false;
  }
}

/// Fallback: Download to external storage directory (always accessible)
Future<bool> _downloadToExternalStorage(
  String url,
  String filename,
  Directory externalDir,
) async {
  final filePath = '${externalDir.path}/$filename';
  log.info('Fallback: Downloading to external storage: $filePath');

  final response = await Dio().download(url, filePath);

  if (response.statusCode != 200) {
    return false;
  }

  final file = File(filePath);
  return await file.exists();
}

/// Trigger Android Media Scanner to index the downloaded file
/// This makes it appear in Downloads folder/gallery
Future<void> _scanFile(String filePath) async {
  try {
    // Note: This requires platform channel implementation
    // For now, just log that we should scan
    log.info('File should be scanned by media scanner: $filePath');

    // TODO: Add platform channel to call:
    // MediaScannerConnection.scanFile(context, arrayOf(filePath), null, null)
  } catch (e) {
    log.warning('Media scanner error: $e');
  }
}
