import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/auth/connected_app_model.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_bloc.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_event.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_repositories.dart';

void main() {
  late MockConnectedAppRepository mockConnectedAppRepository;
  late ConnectedAppBloc connectedAppBloc;

  setUp(() {
    mockConnectedAppRepository = MockConnectedAppRepository();
    connectedAppBloc = ConnectedAppBloc(
      connectedAppRepository: mockConnectedAppRepository,
    );
  });

  tearDown(() {
    connectedAppBloc.close();
  });

  group('ConnectedAppBloc', () {
    test('initial state is ConnectedAppInitial', () {
      expect(connectedAppBloc.state, isA<ConnectedAppInitial>());
    });

    group('FetchConnectedAppsEvent', () {
      blocTest<ConnectedAppBloc, ConnectedAppState>(
        'emits [ConnectedAppsLoading, ConnectedAppsFetched] when fetch succeeds',
        build: () {
          when(
            () => mockConnectedAppRepository.getConnectedApps(
              forceRefresh: true,
            ),
          ).thenAnswer(
            (_) async => [
              ConnectedAppModel(id: 7, name: 'Claude', scopes: const []),
            ],
          );
          return connectedAppBloc;
        },
        act: (bloc) => bloc.add(
          FetchConnectedAppsEvent(
            origin: EventOrigin.screen,
            forceRefresh: true,
          ),
        ),
        expect: () => [
          isA<ConnectedAppsLoading>(),
          isA<ConnectedAppsFetched>().having(
            (state) => state.connectedApps.single.id,
            'id',
            7,
          ),
        ],
      );

      blocTest<ConnectedAppBloc, ConnectedAppState>(
        'emits [ConnectedAppsLoading, ConnectedAppsError] when fetch fails',
        build: () {
          when(
            () => mockConnectedAppRepository.getConnectedApps(),
          ).thenThrow(ServerException(message: 'Server error'));
          return connectedAppBloc;
        },
        act: (bloc) =>
            bloc.add(FetchConnectedAppsEvent(origin: EventOrigin.screen)),
        expect: () => [isA<ConnectedAppsLoading>(), isA<ConnectedAppsError>()],
      );
    });

    group('RevokeConnectedAppEvent', () {
      blocTest<ConnectedAppBloc, ConnectedAppState>(
        'emits [ConnectedAppsLoading, ConnectedAppRevoked] when revoke succeeds',
        build: () {
          when(
            () => mockConnectedAppRepository.revokeConnectedApp(
              connectedAppId: 7,
            ),
          ).thenAnswer((_) async {});
          return connectedAppBloc;
        },
        act: (bloc) => bloc.add(
          RevokeConnectedAppEvent(origin: EventOrigin.subScreen, id: 7),
        ),
        expect: () => [
          isA<ConnectedAppsLoading>(),
          isA<ConnectedAppRevoked>().having((state) => state.id, 'id', 7),
        ],
      );

      blocTest<ConnectedAppBloc, ConnectedAppState>(
        'emits [ConnectedAppsLoading, ConnectedAppsError] when revoke fails',
        build: () {
          when(
            () => mockConnectedAppRepository.revokeConnectedApp(
              connectedAppId: 7,
            ),
          ).thenThrow(ServerException(message: 'Server error'));
          return connectedAppBloc;
        },
        act: (bloc) => bloc.add(
          RevokeConnectedAppEvent(origin: EventOrigin.subScreen, id: 7),
        ),
        expect: () => [isA<ConnectedAppsLoading>(), isA<ConnectedAppsError>()],
      );
    });

    group('ResetConnectedAppsEvent', () {
      blocTest<ConnectedAppBloc, ConnectedAppState>(
        'returns to ConnectedAppInitial',
        build: () => connectedAppBloc,
        act: (bloc) => bloc.add(ResetConnectedAppsEvent()),
        expect: () => [isA<ConnectedAppInitial>()],
      );
    });
  });
}
