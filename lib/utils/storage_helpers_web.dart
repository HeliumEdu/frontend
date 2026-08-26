import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:heliumapp/utils/storage_helpers.dart';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

final _log = Logger('utils');

/// Reads bytes from a picked file on web by consuming [PlatformFile.readStream]
/// in 1 MB chunks. The stream is created lazily by the file_picker plugin using
/// the browser File API (file.slice), so bytes are only allocated here, after
/// the size check in [HeliumStorage.pickFiles] has already passed.
Future<Uint8List?> readPickedFileBytes(PlatformFile platFile) async {
  if (platFile.readStream == null) {
    return null;
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in platFile.readStream!) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

/// Hands the signed URL to the browser to download.
///
/// Signed URLs carry a download disposition, so the browser saves rather than
/// navigates and names the file from the object key.
Future<DownloadStatus> downloadFilePlatform(String url, String filename) async {
  try {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = filename
      ..target = '_blank'
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();

    _log.info('Web download handed to the browser');
    return DownloadStatus.saved;
  } catch (e) {
    _log.severe('Web download failed', e);
    return DownloadStatus.failed;
  }
}

/// Downloads bytes directly to a file on web (creates blob and triggers download)
Future<DownloadStatus> downloadBytesPlatform(Uint8List bytes, String filename) async {
  try {
    final jsUint8Array = bytes.toJS;
    final blob = web.Blob(
      [jsUint8Array].toJS,
      web.BlobPropertyBag(type: 'application/octet-stream'),
    );
    final blobUrl = web.URL.createObjectURL(blob);

    // Create anchor element and trigger download
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = blobUrl
      ..download = filename
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();

    anchor.remove();
    web.URL.revokeObjectURL(blobUrl);

    _log.info('Web download triggered');
    return DownloadStatus.saved;
  } catch (e) {
    _log.severe('Web bytes download failed', e);
    return DownloadStatus.failed;
  }
}
