// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/info_model.dart';
import 'package:heliumapp/data/repositories/info_repository_impl.dart';
import 'package:heliumapp/data/sources/info_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockInfoRemoteDataSource extends Mock implements InfoRemoteDataSource {}

void main() {
  late InfoRepositoryImpl repository;
  late MockInfoRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockInfoRemoteDataSource();
    repository = InfoRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  InfoModel givenInfo({int maxUploadSize = 10485760}) => InfoModel(
        maxUploadSize: maxUploadSize,
        importFileTypes: const ['json'],
      );

  group('InfoRepositoryImpl', () {
    test('caches result of first successful fetch', () async {
      // GIVEN
      when(() => mockRemoteDataSource.getInfo())
          .thenAnswer((_) async => givenInfo());

      // WHEN
      await repository.getInfo();
      await repository.getInfo();

      // THEN
      verify(() => mockRemoteDataSource.getInfo()).called(1);
    });

    test('re-fetches when forceRefresh is true', () async {
      // GIVEN
      when(() => mockRemoteDataSource.getInfo())
          .thenAnswer((_) async => givenInfo());

      // WHEN
      await repository.getInfo();
      await repository.getInfo(forceRefresh: true);

      // THEN
      verify(() => mockRemoteDataSource.getInfo()).called(2);
    });

    test('does not cache a failed fetch', () async {
      // GIVEN
      when(() => mockRemoteDataSource.getInfo()).thenThrow(Exception('boom'));

      // WHEN
      await expectLater(repository.getInfo(), throwsException);

      when(() => mockRemoteDataSource.getInfo())
          .thenAnswer((_) async => givenInfo());
      final second = await repository.getInfo();

      // THEN
      expect(second.maxUploadSize, equals(10485760));
      verify(() => mockRemoteDataSource.getInfo()).called(2);
    });
  });
}
