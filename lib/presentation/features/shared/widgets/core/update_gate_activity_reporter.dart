import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_state.dart';

/// Tells [UpdateGateBloc] when the user is active, and, while it waits, whether
/// the current screen could lose work if the update screen replaced it.
class UpdateGateActivityReporter extends StatefulWidget {
  final Widget child;

  const UpdateGateActivityReporter({super.key, required this.child});

  @override
  State<UpdateGateActivityReporter> createState() =>
      _UpdateGateActivityReporterState();
}

class _UpdateGateActivityReporterState
    extends State<UpdateGateActivityReporter> {
  static const _checkEvery = Duration(seconds: 2);

  /// Pointer moves arrive many times a second; the gate only needs to know the
  /// user is still there.
  static const _reportActivityEvery = Duration(seconds: 1);

  static const _pagesWithNothingToSave = {
    AppRoute.plannerScreen,
    AppRoute.coursesScreen,
    AppRoute.resourcesScreen,
    AppRoute.gradesScreen,
    AppRoute.landingScreen,
    AppRoute.signinScreen,
  };

  final Stopwatch _sinceActivityReported = Stopwatch();
  Timer? _check;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (context.read<UpdateGateBloc>().state is UpdateGateWaiting) {
      _startChecking();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _stopChecking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdateGateBloc, UpdateGateState>(
      listener: _onGateChanged,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointer,
        onPointerMove: _onPointer,
        onPointerHover: _onPointer,
        onPointerSignal: _onPointer,
        child: widget.child,
      ),
    );
  }

  void _onGateChanged(BuildContext context, UpdateGateState state) {
    if (state is UpdateGateWaiting) {
      _startChecking();
    } else {
      _stopChecking();
    }
  }

  void _startChecking() {
    _check ??= Timer.periodic(_checkEvery, _onCheckTimer);
  }

  void _stopChecking() {
    _check?.cancel();
    _check = null;
  }

  void _onCheckTimer(Timer timer) {
    if (!mounted) return;
    final gate = context.read<UpdateGateBloc>();
    try {
      gate.add(UpdateGateCheckEvent(isPageSafe: _currentPageHasNothingToSave()));
    } catch (e, s) {
      _stopChecking();
      gate.add(UpdateGateCheckFailedEvent(e, s));
    }
  }

  void _onPointer(PointerEvent event) => _reportActivity();

  bool _onKey(KeyEvent event) {
    _reportActivity();
    return false;
  }

  void _reportActivity() {
    if (!mounted) return;
    if (_sinceActivityReported.isRunning &&
        _sinceActivityReported.elapsed < _reportActivityEvery) {
      return;
    }
    _sinceActivityReported
      ..reset()
      ..start();
    context.read<UpdateGateBloc>().add(UpdateGateUserActiveEvent());
  }

  static bool _currentPageHasNothingToSave() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final somethingOnTop = rootNavigatorKey.currentState?.canPop() ?? true;
    return _pagesWithNothingToSave.contains(path) &&
        !somethingOnTop &&
        !_isEditingText();
  }

  /// On-screen keyboards type without key events, so a focused text field is
  /// what shows the user is typing.
  static bool _isEditingText() {
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused?.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}
