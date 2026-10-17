import 'package:bloc/bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_state.dart';
import 'package:heliumapp/utils/version_helpers.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _log = Logger('presentation.bloc');

/// Whether the update screen replaces the app because the running version is
/// below `/info/`'s minimum supported version.
///
/// The update screen replaces the whole app, so it is shown right away only on
/// a cold launch the user hasn't touched yet; otherwise it waits until the user
/// is idle on a screen where no work can be lost. It fails open everywhere so
/// that it can't block the app from loading, in the event the gate itself has
/// some failure.
class UpdateGateBloc extends Bloc<UpdateGateEvent, UpdateGateState> {
  static const _idleBeforeGate = Duration(seconds: 10);

  final String? _appVersion;
  final Duration _idle;
  final Stopwatch _sinceUserActive = Stopwatch()..start();
  bool _isColdLaunch = true;
  bool _failedOpen = false;

  UpdateGateBloc({
    required String? appVersion,
    @visibleForTesting Duration idle = _idleBeforeGate,
  })  : _appVersion = appVersion,
        _idle = idle,
        super(UpdateGateHidden()) {
    on<UpdateGateInfoChangedEvent>(_onInfoChanged);
    on<UpdateGateUserActiveEvent>(_onUserActive);
    on<UpdateGateCheckEvent>(_onCheck);
    on<UpdateGateCheckFailedEvent>(_onCheckFailed);
  }

  void _onInfoChanged(
    UpdateGateInfoChangedEvent event,
    Emitter<UpdateGateState> emit,
  ) {
    final info = event.info;
    if (info is! InfoLoaded || _failedOpen) return;

    final wasColdLaunch = _isColdLaunch;
    _isColdLaunch = false;

    final version = _appVersion;
    final bool required;
    try {
      required = version != null &&
          VersionHelpers.isBelow(version, info.info.minimumSupportedVersion);
    } catch (e, s) {
      _failOpen(e, s, emit);
      return;
    }

    if (!required) {
      if (state is! UpdateGateHidden) emit(UpdateGateHidden());
    } else if (state is UpdateGateHidden) {
      if (wasColdLaunch) {
        emit(UpdateGateShown());
      } else {
        _sinceUserActive
          ..reset()
          ..start();
        emit(UpdateGateWaiting());
      }
    }
  }

  void _onUserActive(
    UpdateGateUserActiveEvent event,
    Emitter<UpdateGateState> emit,
  ) {
    _isColdLaunch = false;
    _sinceUserActive
      ..reset()
      ..start();
  }

  void _onCheck(UpdateGateCheckEvent event, Emitter<UpdateGateState> emit) {
    if (state is! UpdateGateWaiting) return;
    if (_sinceUserActive.elapsed < _idle || !event.isPageSafe) return;
    emit(UpdateGateShown());
  }

  void _onCheckFailed(
    UpdateGateCheckFailedEvent event,
    Emitter<UpdateGateState> emit,
  ) => _failOpen(event.error, event.stackTrace, emit);

  void _failOpen(
    Object error,
    StackTrace stackTrace,
    Emitter<UpdateGateState> emit,
  ) {
    _failedOpen = true;
    if (state is! UpdateGateHidden) emit(UpdateGateHidden());
    _log.severe(
      'Update gate disabled after an unexpected error',
      error,
      stackTrace,
    );
  }
}
