// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/sources/attachment_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/planner_helper.dart';
import '../../mocks/mock_dio.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late AttachmentRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = AttachmentRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('AttachmentRemoteDataSource', () {
    group('getAttachments', () {
      test('returns list of AttachmentModel on successful response', () async {
        // GIVEN
        final attachmentsJson = [
          givenAttachmentJson(id: 1, title: 'document.pdf'),
          givenAttachmentJson(id: 2, title: 'image.png'),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(attachmentsJson));

        // WHEN
        final result = await dataSource.getAttachments();

        // THEN
        expect(result.length, equals(2));
        expect(result[0].title, equals('document.pdf'));
        expect(result[1].title, equals('image.png'));
      });

      test('returns empty list when API returns empty array', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        final result = await dataSource.getAttachments();

        // THEN
        expect(result, isEmpty);
      });

      test('filters by eventId when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getAttachments(eventId: 5);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'event': 5}),
        ).called(1);
      });

      test('filters by homeworkId when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getAttachments(homeworkId: 10);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'homework': 10}),
        ).called(1);
      });

      test('filters by courseId when provided', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse([]));

        // WHEN
        await dataSource.getAttachments(courseId: 3);

        // THEN
        verify(
          () => mockDio.get(any(), queryParameters: {'course': 3}),
        ).called(1);
      });

      test('parses attachment with all associations', () async {
        // GIVEN
        final attachmentsJson = [
          givenAttachmentJson(id: 1, course: 1, event: 2, homework: 3),
        ];
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async => givenSuccessResponse(attachmentsJson));

        // WHEN
        final result = await dataSource.getAttachments();

        // THEN
        expect(result[0].course, equals(1));
        expect(result[0].event, equals(2));
        expect(result[0].homework, equals(3));
      });
    });

    group('deleteAttachment', () {
      test('completes successfully on 204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 204));

        // WHEN/THEN
        expect(dataSource.deleteAttachment(1), completes);
      });

      test('throws ServerException on non-204 response', () async {
        // GIVEN
        when(
          () => mockDio.delete(any()),
        ).thenAnswer((_) async => givenSuccessResponse(null, statusCode: 500));

        // WHEN/THEN
        expect(
          () => dataSource.deleteAttachment(1),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('error handling', () {
      test('throws NetworkException on connection timeout', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(givenNetworkException());

        // WHEN/THEN
        expect(
          () => dataSource.getAttachments(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws UnauthorizedException on 401 response', () async {
        // GIVEN
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(givenUnauthorizedException());

        // WHEN/THEN
        expect(
          () => dataSource.getAttachments(),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
