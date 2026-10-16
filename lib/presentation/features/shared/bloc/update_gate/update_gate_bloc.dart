import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_bloc.dart';
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
/// The update screen replaces the whole app and is only surfaced on screens
/// where active work can't be / isn't being done. It fails open everywhere
/// so that it can't block the app from loading, in the event the gate itself
/// has some failure.
class UpdateGateBloc extends Bloc<UpdateGateEvent, UpdateGateState> {
  static const _idleBeforeGate = Duration(seconds: 10);
  static const _checkEvery = Duration(seconds: 2);

  static const _pagesWithNothingToSave = {
    AppRoute.plannerScreen,
    AppRoute.coursesScreen,
    AppRoute.resourcesScreen,
    AppRoute.gradesScreen,
    AppRoute.landingScreen,
    AppRoute.signinScreen,
  };

  final String? _appVersion;
  final bool Function() _onPageWithNothingToSave;
  final Duration _idle;
  late final StreamSubscription<InfoState> _infoSub;
  final Stopwatch _sinceInput = Stopwatch();
  Timer? _check;
  bool _required = false;
  bool _failedOpen = false;

  UpdateGateBloc({
    required InfoBloc infoBloc,
    required String? appVersion,
    @visibleForTesting bool Function()? onPageWithNothingToSave,
    @visibleForTesting Duration idle = _idleBeforeGate,
  })  : _appVersion = appVersion,
        _onPageWithNothingToSave =
            onPageWithNothingToSave ?? _currentPageHasNothingToSave,
        _idle = idle,
        super(UpdateGateHidden()) {
    on<UpdateGateInfoChanged>(_onInfoChanged);
    on<UpdateGateChecked>(_onChecked);
    _infoSub = infoBloc.stream.listen(_addInfoChanged);
    add(UpdateGateInfoChanged(infoBloc.state));
  }

  static bool _currentPageHasNothingToSave() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final somethingOnTop = rootNavigatorKey.currentState?.canPop() ?? true;
    return _pagesWithNothingToSave.contains(path) && !somethingOnTop;
  }

  void _addInfoChanged(InfoState info) => add(UpdateGateInfoChanged(info));

  void _onInfoChanged(
    UpdateGateInfoChanged event,
    Emitter<UpdateGateState> emit,
  ) {
    final info = event.info;
    if (info is! InfoLoaded || _failedOpen) return;
    final version = _appVersion;
    try {
      _required = version != null &&
          VersionHelpers.isBelow(version, info.info.minimumSupportedVersion);
    } catch (e, s) {
      _failOpen(e, s);
      return;
    }
    if (_required && state is UpdateGateHidden) {
      _waitForASafeMoment();
    } else if (!_required) {
      _stopWaiting();
      if (state is UpdateGateShown) emit(UpdateGateHidden());
    }
  }

  void _onChecked(UpdateGateChecked event, Emitter<UpdateGateState> emit) {
    if (!_required || state is UpdateGateShown) return;
    if (_sinceInput.elapsed < _idle) return;
    try {
      if (!_onPageWithNothingToSave()) return;
    } catch (e, s) {
      _failOpen(e, s);
      return;
    }
    _stopWaiting();
    emit(UpdateGateShown());
  }

  void _waitForASafeMoment() {
    if (_check != null) return;
    _restartIdleClock();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    HardwareKeyboard.instance.addHandler(_onKey);
    _check = Timer.periodic(_checkEvery, _onCheckTimer);
  }

  void _stopWaiting() {
    final check = _check;
    if (check == null) return;
    check.cancel();
    _check = null;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
  }

  void _onCheckTimer(Timer timer) => add(UpdateGateChecked());

  void _restartIdleClock() => _sinceInput
    ..reset()
    ..start();

  void _onPointer(PointerEvent event) => _restartIdleClock();

  bool _onKey(KeyEvent event) {
    _restartIdleClock();
    return false;
  }

  void _failOpen(Object error, StackTrace stackTrace) {
    _failedOpen = true;
    _required = false;
    _stopWaiting();
    _log.severe('Update gate disabled after an unexpected error', error, stackTrace);
  }

  @override
  Future<void> close() async {
    _stopWaiting();
    await _infoSub.cancel();
    return super.close();
  }
}
