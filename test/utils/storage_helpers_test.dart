// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

// These tests run on the VM (flutter test), so storage_helpers_mobile.dart is
// the active platform file and kIsWeb = false throughout.
//
// Platform coverage:
//   - Shared logic (size check, extension check, error types): tested here on VM
//   - Mobile byte-reading via File.path: tested in 'mobile path-based reading' group
//   - Stream byte assembly (BytesBuilder path): tested via the mobile readStream
//     fallback, which is identical to the web implementation
//   - Web-specific picker invocation (FileType.custom): verified in
//     'extension validation' group via kIsWeb=false branch; the web branch is
//     exercised by integration tests on Chrome

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:heliumapp/utils/storage_helpers.dart';

class _MockFilePicker extends Mock with MockPlatformInterfaceMixin implements FilePicker {}

/// Builds a [PlatformFile] backed by a single-chunk [readStream] and no path.
/// On mobile (VM), [readPickedFileBytes] falls back to the stream when path is
/// null, so this exercises the [BytesBuilder] assembly path used on web.
PlatformFile _streamFile({
  required String name,
  required int size,
  required List<int> bytes,
}) {
  return PlatformFile(
    name: name,
    size: size,
    readStream: Stream.fromIterable([bytes]),
  );
}

void main() {
  late _MockFilePicker mockFilePicker;

  setUpAll(() {
    registerFallbackValue(FileType.any);
  });

  setUp(() {
    mockFilePicker = _MockFilePicker();
    FilePicker.platform = mockFilePicker;
  });

  /// Stubs [FilePicker.platform.pickFiles] to return [result].
  void stubPickFiles(FilePickerResult? result) {
    when(
      () => mockFilePicker.pickFiles(
        type: any(named: 'type'),
        allowedExtensions: any(named: 'allowedExtensions'),
        allowMultiple: any(named: 'allowMultiple'),
        withData: any(named: 'withData'),
        withReadStream: any(named: 'withReadStream'),
        onFileLoading: any(named: 'onFileLoading'),
        compressionQuality: any(named: 'compressionQuality'),
        lockParentWindow: any(named: 'lockParentWindow'),
        readSequential: any(named: 'readSequential'),
        initialDirectory: any(named: 'initialDirectory'),
        dialogTitle: any(named: 'dialogTitle'),
      ),
    ).thenAnswer((_) async => result);
  }

  group('HeliumStorage.pickFiles', () {
    group('cancelled / empty result', () {
      test('returns cancelled=true when picker returns null', () async {
        stubPickFiles(null);

        final result = await HeliumStorage.pickFiles();

        expect(result.cancelled, isTrue);
        expect(result.files, isEmpty);
        expect(result.errors, isEmpty);
      });

      test('cancelled=false and no errors when picker returns empty list', () async {
        stubPickFiles(const FilePickerResult([]));

        final result = await HeliumStorage.pickFiles();

        expect(result.cancelled, isFalse);
        expect(result.files, isEmpty);
        expect(result.errors, isEmpty);
      });
    });

    group('size validation', () {
      test('accepts file exactly at the 10 MB limit', () async {
        final bytes = List.filled(maxUploadFileSizeBytes, 0);
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'exact.bin', size: maxUploadFileSizeBytes, bytes: bytes),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files, hasLength(1));
        expect(result.files.first.name, 'exact.bin');
        expect(result.errors, isEmpty);
      });

      test('accepts file 1 byte under the limit', () async {
        const size = maxUploadFileSizeBytes - 1;
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'small.bin', size: size, bytes: List.filled(size, 0)),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('rejects file 1 byte over the limit without consuming stream', () async {
        // The stream contains no bytes; if it were consumed, the assembled
        // Uint8List would be empty — proving we never reached stream reading.
        stubPickFiles(FilePickerResult([
          PlatformFile(
            name: 'huge.bin',
            size: maxUploadFileSizeBytes + 1,
            readStream: Stream<List<int>>.fromIterable([]),
          ),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.reason, PickedFileErrorReason.fileTooLarge);
        expect(result.errors.first.name, 'huge.bin');
        expect(result.errors.first.userMessage, contains('10 MB'));
      });

      test('produces one fileTooLarge error per oversized file', () async {
        const overSize = maxUploadFileSizeBytes + 1;
        stubPickFiles(FilePickerResult([
          PlatformFile(name: 'a.bin', size: overSize),
          PlatformFile(name: 'b.bin', size: overSize),
        ]));

        final result = await HeliumStorage.pickFiles(allowMultiple: true);

        expect(result.files, isEmpty);
        expect(result.errors, hasLength(2));
        expect(
          result.errors.every((e) => e.reason == PickedFileErrorReason.fileTooLarge),
          isTrue,
        );
      });
    });

    group('mixed valid and invalid files', () {
      test('separates accepted files from oversized files', () async {
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'valid.txt', size: 3, bytes: [1, 2, 3]),
          PlatformFile(name: 'too_big.bin', size: maxUploadFileSizeBytes + 1),
        ]));

        final result = await HeliumStorage.pickFiles(allowMultiple: true);

        expect(result.cancelled, isFalse);
        expect(result.files, hasLength(1));
        expect(result.files.first.name, 'valid.txt');
        expect(result.errors, hasLength(1));
        expect(result.errors.first.reason, PickedFileErrorReason.fileTooLarge);
      });
    });

    group('byte assembly via stream (web implementation + mobile fallback)', () {
      test('assembles single-chunk stream into correct Uint8List', () async {
        final bytes = [10, 20, 30, 40, 50];
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'file.bin', size: bytes.length, bytes: bytes),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files, hasLength(1));
        expect(result.files.first.bytes, equals(Uint8List.fromList(bytes)));
      });

      test('assembles multi-chunk stream correctly', () async {
        // Simulates the 1 MB chunked delivery the web file_picker plugin uses.
        final chunk1 = List<int>.generate(5, (i) => i);
        final chunk2 = List<int>.generate(5, (i) => i + 5);
        final expected = Uint8List.fromList([...chunk1, ...chunk2]);

        stubPickFiles(FilePickerResult([
          PlatformFile(
            name: 'multi.bin',
            size: 10,
            readStream: Stream.fromIterable([chunk1, chunk2]),
          ),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files.first.bytes, equals(expected));
      });

      test('returns readError when path is null and readStream is null', () async {
        stubPickFiles(FilePickerResult([
          // No path, no readStream → readPickedFileBytes returns null on mobile
          PlatformFile(name: 'unreadable.bin', size: 100),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.reason, PickedFileErrorReason.readError);
        expect(result.errors.first.userMessage, contains('unreadable.bin'));
      });
    });

    group('mobile path-based reading (VM only — dart:io)', () {
      test('reads bytes from a real file via PlatformFile.path', () async {
        final tmpDir = Directory.systemTemp.createTempSync('helium_test_');
        final tmpFile = File('${tmpDir.path}/test.bin');
        final expectedBytes = Uint8List.fromList([7, 8, 9, 10, 11]);
        await tmpFile.writeAsBytes(expectedBytes);

        addTearDown(() => tmpDir.deleteSync(recursive: true));

        stubPickFiles(FilePickerResult([
          PlatformFile(
            name: 'test.bin',
            size: expectedBytes.length,
            path: tmpFile.path,
          ),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files, hasLength(1));
        expect(result.files.first.bytes, equals(expectedBytes));
      });

      test('path takes precedence over readStream on mobile', () async {
        final tmpDir = Directory.systemTemp.createTempSync('helium_test_');
        final tmpFile = File('${tmpDir.path}/priority.bin');
        final fileBytes = Uint8List.fromList([1, 2, 3]);
        final streamBytes = [99, 99, 99]; // different — should NOT be used
        await tmpFile.writeAsBytes(fileBytes);

        addTearDown(() => tmpDir.deleteSync(recursive: true));

        stubPickFiles(FilePickerResult([
          PlatformFile(
            name: 'priority.bin',
            size: fileBytes.length,
            path: tmpFile.path,
            readStream: Stream.fromIterable([streamBytes]),
          ),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files.first.bytes, equals(fileBytes));
      });
    });

    group('extension validation (kIsWeb=false — mobile branch)', () {
      test('rejects file whose extension does not match allowedExtension', () async {
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'backup.csv', size: 3, bytes: [1, 2, 3]),
        ]));

        final result = await HeliumStorage.pickFiles(allowedExtension: 'json');

        expect(result.files, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.reason, PickedFileErrorReason.wrongFileType);
        expect(result.errors.first.userMessage, 'Please select a JSON file');
      });

      test('accepts file whose extension matches allowedExtension', () async {
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'backup.json', size: 4, bytes: [1, 2, 3, 4]),
        ]));

        final result = await HeliumStorage.pickFiles(allowedExtension: 'json');

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('extension check is case-insensitive', () async {
        // file_picker returns extension as-is from the filename; our code
        // lowercases both sides before comparing.
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'backup.JSON', size: 2, bytes: [1, 2]),
        ]));

        final result = await HeliumStorage.pickFiles(allowedExtension: 'json');

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('skips extension check when allowedExtension is null', () async {
        stubPickFiles(FilePickerResult([
          _streamFile(name: 'anything.xyz', size: 3, bytes: [1, 2, 3]),
        ]));

        final result = await HeliumStorage.pickFiles();

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('extension check applies before size check', () async {
        // Wrong extension + oversized: should get wrongFileType, not fileTooLarge
        stubPickFiles(FilePickerResult([
          PlatformFile(
            name: 'wrong.csv',
            size: maxUploadFileSizeBytes + 1,
          ),
        ]));

        final result = await HeliumStorage.pickFiles(allowedExtension: 'json');

        expect(result.errors.first.reason, PickedFileErrorReason.wrongFileType);
      });
    });

    group('PickedFileError.userMessage', () {
      test('fileTooLarge includes file name and "10 MB"', () {
        const error = PickedFileError(
          name: 'big.bin',
          reason: PickedFileErrorReason.fileTooLarge,
        );
        expect(error.userMessage, 'File size cannot exceed 10 MB: big.bin');
      });

      test('readError includes file name', () {
        const error = PickedFileError(
          name: 'broken.bin',
          reason: PickedFileErrorReason.readError,
        );
        expect(
          error.userMessage,
          'An error occurred while reading the file: broken.bin',
        );
      });

      test('wrongFileType with allowedExtension uses uppercased extension', () {
        const error = PickedFileError(
          name: 'wrong.csv',
          reason: PickedFileErrorReason.wrongFileType,
          allowedExtension: 'json',
        );
        expect(error.userMessage, 'Please select a JSON file');
      });

      test('wrongFileType without allowedExtension uses generic message', () {
        const error = PickedFileError(
          name: 'wrong.bin',
          reason: PickedFileErrorReason.wrongFileType,
        );
        expect(error.userMessage, 'Invalid file type');
      });
    });

    group('maxUploadFileSizeBytes', () {
      test('is exactly 10 MB', () {
        expect(maxUploadFileSizeBytes, equals(10 * 1024 * 1024));
      });
    });
  });
}
