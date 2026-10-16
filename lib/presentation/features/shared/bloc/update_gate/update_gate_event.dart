import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';

abstract class UpdateGateEvent {}

class UpdateGateInfoChangedEvent extends UpdateGateEvent {
  final InfoState info;

  UpdateGateInfoChangedEvent(this.info);
}

/// The user tapped, moved a pointer, scrolled or pressed a key.
class UpdateGateUserActiveEvent extends UpdateGateEvent {}

/// A periodic look, while waiting, at whether the current screen could lose
/// work if the update screen replaced it.
class UpdateGateCheckEvent extends UpdateGateEvent {
  final bool isPageSafe;

  UpdateGateCheckEvent({required this.isPageSafe});
}

class UpdateGateCheckFailedEvent extends UpdateGateEvent {
  final Object error;
  final StackTrace stackTrace;

  UpdateGateCheckFailedEvent(this.error, this.stackTrace);
}
