import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/connected_app_repository.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_event.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

class ConnectedAppBloc extends Bloc<ConnectedAppEvent, ConnectedAppState> {
  final ConnectedAppRepository connectedAppRepository;

  ConnectedAppBloc({required this.connectedAppRepository})
    : super(ConnectedAppInitial(origin: EventOrigin.bloc)) {
    on<FetchConnectedAppsEvent>(_onFetchConnectedApps);
    on<RevokeConnectedAppEvent>(_onRevokeConnectedApp);
    on<ResetConnectedAppsEvent>(
      (event, emit) => emit(ConnectedAppInitial(origin: EventOrigin.bloc)),
    );
  }

  Future<void> _onFetchConnectedApps(
    FetchConnectedAppsEvent event,
    Emitter<ConnectedAppState> emit,
  ) async {
    emit(ConnectedAppsLoading(origin: event.origin));
    try {
      final connectedApps = await connectedAppRepository.getConnectedApps(
        forceRefresh: event.forceRefresh,
      );
      emit(
        ConnectedAppsFetched(
          origin: event.origin,
          connectedApps: connectedApps,
        ),
      );
    } on HeliumException catch (e) {
      emit(ConnectedAppsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ConnectedAppsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onRevokeConnectedApp(
    RevokeConnectedAppEvent event,
    Emitter<ConnectedAppState> emit,
  ) async {
    emit(ConnectedAppsLoading(origin: event.origin));
    try {
      await connectedAppRepository.revokeConnectedApp(
        connectedAppId: event.id,
      );
      emit(ConnectedAppRevoked(origin: event.origin, id: event.id));
    } on HeliumException catch (e) {
      emit(ConnectedAppsError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        ConnectedAppsError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }
}
