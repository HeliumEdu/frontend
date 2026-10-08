import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/data/sources/note_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/note_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late NoteRemoteDataSourceImpl dataSource;
  late MockDio mockDio;

  setUp(() {
    final mockDioClient = MockDioClient();
    final mockCacheService = MockCacheService();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    when(() => mockDioClient.cacheService).thenReturn(mockCacheService);
    when(() => mockCacheService.invalidateAll()).thenAnswer((_) async {});
    dataSource = NoteRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('NoteRemoteDataSource.updateNote', () {
    test('sends the version as If-Match and returns the new version', () async {
      // GIVEN
      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => givenSuccessResponse(
          givenNoteJson(updatedAt: '2026-10-07T12:00:05.000001Z'),
        ),
      );

      // WHEN
      final result = await dataSource.updateNote(
        noteId: 1,
        request: NoteRequestModel(title: 'Note'),
        version: '2026-10-07T12:00:00.123456Z',
      );

      // THEN
      final options = verify(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured.single as Options;
      expect(options.headers?['If-Match'], '2026-10-07T12:00:00.123456Z');
      expect(
        result?.version,
        '2026-10-07T12:00:05.000001Z',
        reason: 'The raw string is kept so microseconds survive a round trip',
      );
    });

    test('sends no If-Match without a version', () async {
      // GIVEN
      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => givenSuccessResponse(givenNoteJson()));

      // WHEN
      await dataSource.updateNote(
        noteId: 1,
        request: NoteRequestModel(title: 'Note'),
      );

      // THEN
      final options = verify(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured.single;
      expect(options, isNull);
    });

    test('throws ConflictException with the latest note on 412', () async {
      // GIVEN
      final latest = givenNoteJson(title: 'Changed elsewhere');
      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(givenDioException(statusCode: 412, responseData: latest));

      // WHEN
      final call = dataSource.updateNote(
        noteId: 1,
        request: NoteRequestModel(title: 'Mine'),
        version: '2026-10-07T12:00:00.123456Z',
      );

      // THEN
      await expectLater(
        call,
        throwsA(
          isA<ConflictException>().having(
            (e) => e.latest['title'],
            'latest title',
            'Changed elsewhere',
          ),
        ),
      );
    });
  });
}
