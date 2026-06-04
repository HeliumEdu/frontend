// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:logging/logging.dart';
// Conditional import - uses web implementation on web, mobile on native platforms
import 'package:heliumapp/utils/storage_helpers_mobile.dart'
    if (dart.library.js_interop) 'package:heliumapp/utils/storage_helpers_web.dart';

final _log = Logger('utils');

/// A file that was successfully picked and validated by [HeliumStorage.pickFiles].
class PickedFile {
  final String name;
  final Uint8List bytes;

  const PickedFile({required this.name, required this.bytes});
}

enum PickedFileErrorReason { fileTooLarge, readError, wrongFileType }

/// A file that failed validation or could not be read during [HeliumStorage.pickFiles].
class PickedFileError {
  final String name;
  final PickedFileErrorReason reason;
  final String? _allowedExtension;
  final int? _maxUploadSize;

  const PickedFileError({
    required this.name,
    required this.reason,
    String? allowedExtension,
    int? maxUploadSize,
  }) : _allowedExtension = allowedExtension,
       _maxUploadSize = maxUploadSize;

  String get userMessage => switch (reason) {
    PickedFileErrorReason.fileTooLarge => _maxUploadSize != null
        ? 'File size cannot exceed ${_maxUploadSize.inMegabytes} MB: $name'
        : 'File size exceeded the allowed limit: $name',
    PickedFileErrorReason.readError =>
      'An error occurred while reading the file: $name',
    PickedFileErrorReason.wrongFileType => _allowedExtension != null
        ? 'Please select a ${_allowedExtension.toUpperCase()} file'
        : 'Invalid file type',
  };
}

/// The result of a [HeliumStorage.pickFiles] call.
class PickFilesResult {
  final List<PickedFile> files;
  final List<PickedFileError> errors;

  /// True when the user dismissed the picker without selecting anything.
  final bool cancelled;

  const PickFilesResult({
    required this.files,
    this.errors = const [],
    this.cancelled = false,
  });
}

class HeliumStorage {
  /// Presents the OS file picker and returns validated files.
  ///
  /// [maxUploadSize] is required (in bytes) and sourced from `GET /info/` via
  /// [InfoBloc] — never hardcoded — so the cap stays in sync with the backend.
  ///
  /// Size is checked via OS/browser metadata ([PlatformFile.size]) before any
  /// bytes are read, so oversized files are rejected without loading them into
  /// memory. Bytes are read lazily after the size check passes.
  ///
  /// On web the picker enforces [allowedExtension] natively (FileType.custom).
  /// On mobile [FileType.any] is used and the extension is validated manually
  /// after selection, matching iOS behaviour where custom UTI mapping is flaky.
  ///
  /// Returns a [PickFilesResult] with:
  /// - [PickFilesResult.cancelled] — user dismissed the picker
  /// - [PickFilesResult.errors] — per-file validation/read failures
  /// - [PickFilesResult.files] — successfully validated files with bytes
  static Future<PickFilesResult> pickFiles({
    required int maxUploadSize,
    bool allowMultiple = true,
    String? allowedExtension,
  }) async {
    // Web uses FileType.custom so the browser enforces the extension filter in
    // the native picker UI. Mobile uses FileType.any because iOS UTI mapping
    // for custom extensions is unreliable; we validate the extension manually.
    final bool useCustomType = kIsWeb && allowedExtension != null;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: useCustomType ? FileType.custom : FileType.any,
        allowedExtensions: useCustomType ? [allowedExtension] : null,
        allowMultiple: allowMultiple,
        withData: false,
        withReadStream: true,
      );
    } catch (e) {
      _log.severe('Error during file picking', e);
      return const PickFilesResult(files: []);
    }

    if (result == null) {
      return const PickFilesResult(files: [], cancelled: true);
    }

    final files = <PickedFile>[];
    final errors = <PickedFileError>[];

    for (final platFile in result.files) {
      // Extension check on mobile (web enforces this via FileType.custom above)
      if (allowedExtension != null && !kIsWeb) {
        if (platFile.extension?.toLowerCase() != allowedExtension.toLowerCase()) {
          errors.add(PickedFileError(
            name: platFile.name,
            reason: PickedFileErrorReason.wrongFileType,
            allowedExtension: allowedExtension,
          ));
          continue;
        }
      }

      // Size check via OS/browser metadata — no bytes loaded at this point
      if (platFile.size > maxUploadSize) {
        errors.add(PickedFileError(
          name: platFile.name,
          reason: PickedFileErrorReason.fileTooLarge,
          maxUploadSize: maxUploadSize,
        ));
        continue;
      }

      try {
        final bytes = await readPickedFileBytes(platFile);
        if (bytes == null) {
          errors.add(PickedFileError(
            name: platFile.name,
            reason: PickedFileErrorReason.readError,
          ));
          continue;
        }
        files.add(PickedFile(name: platFile.name, bytes: bytes));
      } catch (e) {
        _log.warning('Failed to read picked file: ${platFile.name}', e);
        errors.add(PickedFileError(
          name: platFile.name,
          reason: PickedFileErrorReason.readError,
        ));
      }
    }

    return PickFilesResult(files: files, errors: errors);
  }

  /// Downloads a remote file. Returns null on success or an error message string on failure.
  static Future<String?> downloadFile(String url, String filename) async {
    try {
      final success = await downloadFilePlatform(url, filename);
      return success ? null : 'Failed to download "$filename".';
    } on DioException catch (e) {
      _log.severe('An error occurred during file download', e);
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('details')) return data['details'].toString();
        if (data.containsKey('detail')) return data['detail'].toString();
      }
      return 'Failed to download "$filename".';
    } catch (e) {
      _log.severe('An error occurred during file download', e);
      return 'Failed to download "$filename".';
    }
  }

  /// Downloads bytes directly to a file (for in-memory data like API responses)
  static Future<bool> downloadBytes(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      return await downloadBytesPlatform(bytes, filename);
    } catch (e) {
      _log.severe('An error occurred during bytes download', e);
      return false;
    }
  }
}
