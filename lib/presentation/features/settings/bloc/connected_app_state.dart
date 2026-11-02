import 'package:heliumapp/data/models/auth/connected_app_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class ConnectedAppState extends BaseState {
  ConnectedAppState({required super.origin, super.message});
}

class ConnectedAppInitial extends ConnectedAppState {
  ConnectedAppInitial({required super.origin});
}

class ConnectedAppsLoading extends ConnectedAppState {
  ConnectedAppsLoading({required super.origin});
}

class ConnectedAppsError extends ConnectedAppState {
  ConnectedAppsError({required super.origin, required super.message});
}

class ConnectedAppsFetched extends ConnectedAppState {
  final List<ConnectedAppModel> connectedApps;

  ConnectedAppsFetched({required super.origin, required this.connectedApps});
}

class ConnectedAppRevoked extends ConnectedAppState {
  final int id;

  ConnectedAppRevoked({required super.origin, required this.id});
}
