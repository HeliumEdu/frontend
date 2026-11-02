import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class ConnectedAppEvent extends BaseEvent {
  ConnectedAppEvent({required super.origin});
}

class ResetConnectedAppsEvent extends ConnectedAppEvent {
  ResetConnectedAppsEvent() : super(origin: EventOrigin.bloc);
}

class FetchConnectedAppsEvent extends ConnectedAppEvent {
  final bool forceRefresh;

  FetchConnectedAppsEvent({required super.origin, this.forceRefresh = false});
}

class RevokeConnectedAppEvent extends ConnectedAppEvent {
  final int id;

  RevokeConnectedAppEvent({required super.origin, required this.id});
}
