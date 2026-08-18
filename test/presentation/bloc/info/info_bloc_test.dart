// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/info_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_repositories.dart';

void main() {
  late MockInfoRepository mockInfoRepository;
  late InfoBloc infoBloc;

  setUp(() {
    mockInfoRepository = MockInfoRepository();
    infoBloc = InfoBloc(infoRepository: mockInfoRepository);
  });

  tearDown(() {
    infoBloc.close();
  });

  group('InfoBloc', () {
    test('initial state is InfoInitial', () {
      expect(infoBloc.state, isA<InfoInitial>());
    });

    group('LoadInfoEvent', () {
      blocTest<InfoBloc, InfoState>(
        'emits [InfoLoading, InfoLoaded] when fetch succeeds',
        build: () {
          when(() => mockInfoRepository.getInfo()).thenAnswer(
            (_) async => InfoModel(
              maxUploadSize: 10485760,
              importFileTypes: const ['json'],
            ),
          );
          return infoBloc;
        },
        act: (bloc) => bloc.add(LoadInfoEvent()),
        expect: () => [
          isA<InfoLoading>(),
          isA<InfoLoaded>().having(
            (s) => s.info.maxUploadSize,
            'maxUploadSize',
            10485760,
          ),
        ],
      );

      blocTest<InfoBloc, InfoState>(
        'emits [InfoLoading, InfoLoadFailed] when fetch throws HeliumException',
        build: () {
          when(() => mockInfoRepository.getInfo())
              .thenThrow(ServerException(message: 'boom'));
          return infoBloc;
        },
        act: (bloc) => bloc.add(LoadInfoEvent()),
        expect: () => [
          isA<InfoLoading>(),
          isA<InfoLoadFailed>(),
        ],
      );
    });
  });
}
