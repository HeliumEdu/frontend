import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heliumapp/utils/storage_helpers.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger('utils');

/// Reads bytes from a picked file on mobile.
///
/// Prefers [PlatformFile.path] (the locally cached file path that file_picker
/// always provides on iOS/Android) for a direct [File.readAsBytes] call.
/// Falls back to consuming [PlatformFile.readStream] if path is unexpectedly
/// absent, which also exercises the same stream path used by the web
/// implementation for test parity.
Future<Uint8List?> readPickedFileBytes(PlatformFile platFile) async {
  if (platFile.path != null) {
    return await File(platFile.path!).readAsBytes();
  }
  if (platFile.readStream != null) {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in platFile.readStream!) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
  return null;
}

/// Saves [bytes] to a location the user chooses, via the system document
/// creator, which needs no storage permission on any API level.
Future<DownloadStatus> _saveBytesToChosenLocation(
  Uint8List bytes,
  String filename,
) async {
  final savedPath = await FilePicker.platform.saveFile(
    fileName: filename,
    bytes: bytes,
  );

  if (savedPath == null) {
    _log.info('Save location not chosen');
    return DownloadStatus.cancelled;
  }

  _log.info('Saved ${bytes.length} bytes via the document creator');
  return DownloadStatus.saved;
}

/// Mobile download with platform-specific behavior:
/// - Android: Prompts for a save location and writes there
/// - iOS: Saves to app Documents directory and opens share sheet (iOS doesn't have public Downloads)
Future<DownloadStatus> downloadFilePlatform(String url, String filename) async {
  try {
    if (Platform.isAndroid) {
      return await _downloadFileAndroid(url, filename);
    } else if (Platform.isIOS) {
      return await _downloadFileIOS(url, filename);
    } else {
      _log.warning('Unsupported platform for download');
      return DownloadStatus.failed;
    }
  } catch (e) {
    _log.severe('Mobile download failed', e);
    return DownloadStatus.failed;
  }
}

Future<DownloadStatus> _downloadFileAndroid(String url, String filename) async {
  try {
    final response = await Dio().get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          _log.info(
            'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
          );
        }
      },
    );

    if (response.statusCode != 200 || response.data == null) {
      _log.warning('Download failed with status: ${response.statusCode}');
      return DownloadStatus.failed;
    }

    return await _saveBytesToChosenLocation(response.data!, filename);
  } on DioException {
    rethrow;
  } catch (e) {
    _log.severe('Android download failed', e);
    return DownloadStatus.failed;
  }
}

/// iOS: Download to app Documents and open share sheet
/// (iOS doesn't have a user-accessible Downloads folder)
Future<DownloadStatus> _downloadFileIOS(String url, String filename) async {
  try {
    // Download to app's Documents directory (accessible via Files app)
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDocDir.path}/$filename';

    _log.info('Downloading to app documents: ${appDocDir.path}');

    final response = await Dio().download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          _log.info(
            'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
          );
        }
      },
    );

    if (response.statusCode != 200) {
      _log.warning('Download failed with status: ${response.statusCode}');
      return DownloadStatus.failed;
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

    _log.info('iOS share sheet result: ${result.status}');
    return result.status == ShareResultStatus.dismissed
        ? DownloadStatus.cancelled
        : DownloadStatus.saved;
  } on DioException {
    rethrow;
  } catch (e) {
    _log.severe('iOS download failed', e);
    return DownloadStatus.failed;
  }
}

/// Downloads bytes directly to a file on mobile.
/// - Android: Saves to Downloads folder
/// - iOS: Saves to app Documents and opens share sheet
Future<DownloadStatus> downloadBytesPlatform(Uint8List bytes, String filename) async {
  try {
    if (Platform.isAndroid) {
      return await _downloadBytesAndroid(bytes, filename);
    } else if (Platform.isIOS) {
      return await _downloadBytesIOS(bytes, filename);
    } else {
      _log.warning('Unsupported platform for bytes download');
      return DownloadStatus.failed;
    }
  } catch (e) {
    _log.severe('Mobile bytes download failed', e);
    return DownloadStatus.failed;
  }
}

Future<DownloadStatus> _downloadBytesAndroid(Uint8List bytes, String filename) async {
  try {
    return await _saveBytesToChosenLocation(bytes, filename);
  } catch (e) {
    _log.severe('Android bytes download failed', e);
    return DownloadStatus.failed;
  }
}

Future<DownloadStatus> _downloadBytesIOS(Uint8List bytes, String filename) async {
  try {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDocDir.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    _log.info('Bytes saved to: ${appDocDir.path}');

    // On iOS, open share sheet so user can save to Files or share
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Save $filename',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      ),
    );

    _log.info('iOS share sheet result: ${result.status}');
    return result.status == ShareResultStatus.dismissed
        ? DownloadStatus.cancelled
        : DownloadStatus.saved;
  } catch (e) {
    _log.severe('iOS bytes download failed', e);
    return DownloadStatus.failed;
  }
}
