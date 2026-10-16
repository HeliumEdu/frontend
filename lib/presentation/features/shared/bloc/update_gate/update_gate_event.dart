import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';

abstract class UpdateGateEvent {}

class UpdateGateInfoChanged extends UpdateGateEvent {
  final InfoState info;

  UpdateGateInfoChanged(this.info);
}

class UpdateGateChecked extends UpdateGateEvent {}
