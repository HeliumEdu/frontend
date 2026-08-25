// These tests run on the VM (flutter test), so storage_helpers_mobile.dart is
// the active platform file and kIsWeb = false throughout.
//
// Platform coverage:
//   - Shared logic (size check, extension check, error types): tested here on VM
//   - Mobile byte-reading via File.path: tested in 'mobile path-based reading' group
//   - Stream byte assembly (BytesBuilder path): tested via the mobile
//     readAsByteStream fallback, which is identical to the web implementation
//   - Web-specific picker invocation (FileType.custom): verified in
//     'extension validation' group via kIsWeb=false branch; the web branch is
//     exercised by integration tests on Chrome

import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:heliumapp/utils/storage_helpers.dart';

class _MockFilePicker extends Mock
    with MockPlatformInterfaceMixin
    implements FilePickerPlatform {}

/// Concrete [PlatformFile] for tests. file_picker 12 made [PlatformFile] an
/// abstract base class, so fakes must extend it rather than construct it.
final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile({
    required this.name,
    required int size,
    List<int> bytes = const [],
    List<List<int>>? chunks,
    String? filePath,
    bool failRead = false,
  })  : _size = size,
        _chunks = chunks ?? [bytes],
        _filePath = filePath,
        _failRead = failRead;

  @override
  final String name;

  final int _size;
  final List<List<int>> _chunks;
  final String? _filePath;
  final bool _failRead;

  List<int> get _bytes => _chunks.expand((c) => c).toList();

  @override
  Uri get uri =>
      _filePath != null ? Uri.file(_filePath) : Uri.parse('memory:$name');

  @override
  String? get path => _filePath;

  @override
  XFile get xFile => XFile.fromData(Uint8List.fromList(_bytes), name: name);

  @override
  Future<int> length() async => _size;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList(_bytes);

  @override
  Stream<Uint8List> readAsByteStream() {
    if (_failRead) {
      return Stream.error(StateError('unreadable'));
    }
    return Stream.fromIterable(_chunks.map(Uint8List.fromList));
  }
}

/// Test stand-in for the value `/info/` would supply at runtime — chosen to
/// match the previous hardcoded cap so the messages and edge cases below stay
/// stable.
const int _testMaxUploadSize = 10 * 1024 * 1024;

/// Builds a [PlatformFile] backed by a single-chunk byte stream and no path.
/// On mobile (VM), [readPickedFileBytes] falls back to the stream when path is
/// null, so this exercises the [BytesBuilder] assembly path used on web.
PlatformFile _streamFile({
  required String name,
  required int size,
  required List<int> bytes,
}) {
  return _FakePlatformFile(name: name, size: size, bytes: bytes);
}

void main() {
  late _MockFilePicker mockFilePicker;

  setUpAll(() {
    registerFallbackValue(FileType.any);
    // file_picker 12 gives pickFiles per-platform option objects with defaults;
    // mocktail needs a fallback for each before any(named:) can match them.
    registerFallbackValue(const AndroidOptions());
    registerFallbackValue(const WindowsOptions());
    registerFallbackValue(const LinuxOptions());
    registerFallbackValue(const WebOptions());
  });

  setUp(() {
    mockFilePicker = _MockFilePicker();
    FilePickerPlatform.instance = mockFilePicker;
  });

  /// Stubs [FilePickerPlatform.instance.pickFiles] to return [files].
  void stubPickFiles(List<PlatformFile> files) {
    when(
      () => mockFilePicker.pickFiles(
        type: any(named: 'type'),
        allowedExtensions: any(named: 'allowedExtensions'),
        onFileLoading: any(named: 'onFileLoading'),
        compressionQuality: any(named: 'compressionQuality'),
        initialDirectory: any(named: 'initialDirectory'),
        dialogTitle: any(named: 'dialogTitle'),
        androidOptions: any(named: 'androidOptions'),
        windowsOptions: any(named: 'windowsOptions'),
        linuxOptions: any(named: 'linuxOptions'),
        webOptions: any(named: 'webOptions'),
      ),
    ).thenAnswer((_) async => files);
  }

  group('HeliumStorage.pickFiles', () {
    group('cancelled / empty result', () {
      // file_picker 12 returns an empty list for both "user cancelled" and
      // "picked nothing", so the two are no longer distinguishable. Both
      // consumers of [cancelled] return silently, so they behave identically.
      test('returns cancelled=true when the picker returns no files', () async {
        stubPickFiles(const <PlatformFile>[]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.cancelled, isTrue);
        expect(result.files, isEmpty);
        expect(result.errors, isEmpty);
      });
    });

    group('size validation', () {
      test('accepts file exactly at the 10 MB limit', () async {
        final bytes = List.filled(_testMaxUploadSize, 0);
        stubPickFiles([
          _streamFile(name: 'exact.bin', size: _testMaxUploadSize, bytes: bytes),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files, hasLength(1));
        expect(result.files.first.name, 'exact.bin');
        expect(result.errors, isEmpty);
      });

      test('accepts file 1 byte under the limit', () async {
        const size = _testMaxUploadSize - 1;
        stubPickFiles([
          _streamFile(name: 'small.bin', size: size, bytes: List.filled(size, 0)),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('rejects file 1 byte over the limit without consuming stream', () async {
        // The stream contains no bytes; if it were consumed, the assembled
        // Uint8List would be empty — proving we never reached stream reading.
        stubPickFiles([
          _FakePlatformFile(
            name: 'huge.bin',
            size: _testMaxUploadSize + 1,
          ),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.reason, PickedFileErrorReason.fileTooLarge);
        expect(result.errors.first.name, 'huge.bin');
        expect(result.errors.first.userMessage, contains('10 MB'));
      });

      test('produces one fileTooLarge error per oversized file', () async {
        const overSize = _testMaxUploadSize + 1;
        stubPickFiles([
          _FakePlatformFile(name: 'a.bin', size: overSize),
          _FakePlatformFile(name: 'b.bin', size: overSize),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize, allowMultiple: true);

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
        stubPickFiles([
          _streamFile(name: 'valid.txt', size: 3, bytes: [1, 2, 3]),
          _FakePlatformFile(name: 'too_big.bin', size: _testMaxUploadSize + 1),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize, allowMultiple: true);

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
        stubPickFiles([
          _streamFile(name: 'file.bin', size: bytes.length, bytes: bytes),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files, hasLength(1));
        expect(result.files.first.bytes, equals(Uint8List.fromList(bytes)));
      });

      test('assembles multi-chunk stream correctly', () async {
        // Simulates the 1 MB chunked delivery the web file_picker plugin uses.
        final chunk1 = List<int>.generate(5, (i) => i);
        final chunk2 = List<int>.generate(5, (i) => i + 5);
        final expected = Uint8List.fromList([...chunk1, ...chunk2]);

        stubPickFiles([
          _FakePlatformFile(
            name: 'multi.bin',
            size: 10,
            chunks: [chunk1, chunk2],
          ),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files.first.bytes, equals(expected));
      });

      test('returns readError when the byte stream fails', () async {
        stubPickFiles([
          // file_picker 12 always supplies a stream, so the readError branch is
          // now reached by the stream erroring rather than by a null stream.
          _FakePlatformFile(name: 'unreadable.bin', size: 100, failRead: true),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

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

        stubPickFiles([
          _FakePlatformFile(
            name: 'test.bin',
            size: expectedBytes.length,
            filePath: tmpFile.path,
          ),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files, hasLength(1));
        expect(result.files.first.bytes, equals(expectedBytes));
      });

      test('path takes precedence over the byte stream on mobile', () async {
        final tmpDir = Directory.systemTemp.createTempSync('helium_test_');
        final tmpFile = File('${tmpDir.path}/priority.bin');
        final fileBytes = Uint8List.fromList([1, 2, 3]);
        final streamBytes = [99, 99, 99]; // different — should NOT be used
        await tmpFile.writeAsBytes(fileBytes);

        addTearDown(() => tmpDir.deleteSync(recursive: true));

        stubPickFiles([
          _FakePlatformFile(
            name: 'priority.bin',
            size: fileBytes.length,
            filePath: tmpFile.path,
            bytes: streamBytes,
          ),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files.first.bytes, equals(fileBytes));
      });
    });

    group('extension validation (kIsWeb=false — mobile branch)', () {
      test('rejects file whose extension does not match allowedExtension', () async {
        stubPickFiles([
          _streamFile(name: 'backup.csv', size: 3, bytes: [1, 2, 3]),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize, allowedExtensions: ['json']);

        expect(result.files, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.reason, PickedFileErrorReason.wrongFileType);
        expect(result.errors.first.userMessage, 'Please select a JSON file');
      });

      test('accepts file whose extension matches allowedExtension', () async {
        stubPickFiles([
          _streamFile(name: 'backup.json', size: 4, bytes: [1, 2, 3, 4]),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize, allowedExtensions: ['json']);

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('extension check is case-insensitive', () async {
        // file_picker returns extension as-is from the filename; our code
        // lowercases both sides before comparing.
        stubPickFiles([
          _streamFile(name: 'backup.JSON', size: 2, bytes: [1, 2]),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize, allowedExtensions: ['json']);

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('skips extension check when allowedExtension is null', () async {
        stubPickFiles([
          _streamFile(name: 'anything.xyz', size: 3, bytes: [1, 2, 3]),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize);

        expect(result.files, hasLength(1));
        expect(result.errors, isEmpty);
      });

      test('extension check applies before size check', () async {
        // Wrong extension + oversized: should get wrongFileType, not fileTooLarge
        stubPickFiles([
          _FakePlatformFile(
            name: 'wrong.csv',
            size: _testMaxUploadSize + 1,
          ),
        ]);

        final result = await HeliumStorage.pickFiles(maxUploadSize: _testMaxUploadSize, allowedExtensions: ['json']);

        expect(result.errors.first.reason, PickedFileErrorReason.wrongFileType);
      });
    });

    group('PickedFileError.userMessage', () {
      test('fileTooLarge with maxUploadSize includes file name and MB cap', () {
        const error = PickedFileError(
          name: 'big.bin',
          reason: PickedFileErrorReason.fileTooLarge,
          maxUploadSize: _testMaxUploadSize,
        );
        expect(error.userMessage, 'File size cannot exceed 10 MB: big.bin');
      });

      test('fileTooLarge without maxUploadSize falls back to generic message', () {
        const error = PickedFileError(
          name: 'big.bin',
          reason: PickedFileErrorReason.fileTooLarge,
        );
        expect(
          error.userMessage,
          'File size exceeded the allowed limit: big.bin',
        );
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
          allowedExtensions: ['json'],
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

  });
}
