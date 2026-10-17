import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/info_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/update_gate/update_gate_state.dart';

InfoLoaded _infoRequiring(String minimumSupportedVersion) => InfoLoaded(
  info: InfoModel(
    maxUploadSize: 1,
    importFileTypes: const [],
    minimumSupportedVersion: minimumSupportedVersion,
  ),
);

UpdateGateBloc _gate({
  String? appVersion = '3.0.0',
  Duration idle = Duration.zero,
}) => UpdateGateBloc(appVersion: appVersion, idle: idle);

void _requireAfterUserIsActive(UpdateGateBloc gate) => gate
  ..add(UpdateGateUserActiveEvent())
  ..add(UpdateGateInfoChangedEvent(_infoRequiring('3.1.0')));

void main() {
  group('UpdateGateBloc', () {
    test('starts hidden', () async {
      // GIVEN
      final gate = _gate();

      // THEN
      expect(gate.state, isA<UpdateGateHidden>());
      await gate.close();
    });

    blocTest<UpdateGateBloc, UpdateGateState>(
      'shows immediately on a cold launch the user has not touched',
      build: _gate,
      act: (gate) =>
          gate.add(UpdateGateInfoChangedEvent(_infoRequiring('3.1.0'))),
      expect: () => [isA<UpdateGateShown>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'stays hidden when the running version meets the minimum',
      build: _gate,
      act: (gate) =>
          gate.add(UpdateGateInfoChangedEvent(_infoRequiring('3.0.0'))),
      expect: () => <UpdateGateState>[],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'stays hidden until info has loaded',
      build: _gate,
      act: (gate) => gate
        ..add(UpdateGateInfoChangedEvent(InfoLoading()))
        ..add(UpdateGateInfoChangedEvent(InfoLoadFailed())),
      expect: () => <UpdateGateState>[],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'stays hidden when the app version is unknown',
      build: () => _gate(appVersion: null),
      act: (gate) =>
          gate.add(UpdateGateInfoChangedEvent(_infoRequiring('3.1.0'))),
      expect: () => <UpdateGateState>[],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'after the user has been active, waits instead of showing',
      build: _gate,
      act: _requireAfterUserIsActive,
      expect: () => [isA<UpdateGateWaiting>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'shows once the user is idle on a page with nothing to save',
      build: _gate,
      act: (gate) {
        _requireAfterUserIsActive(gate);
        gate.add(UpdateGateCheckEvent(isPageSafe: true));
      },
      expect: () => [isA<UpdateGateWaiting>(), isA<UpdateGateShown>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'never shows over a page with unsaved work',
      build: _gate,
      act: (gate) {
        _requireAfterUserIsActive(gate);
        gate.add(UpdateGateCheckEvent(isPageSafe: false));
      },
      expect: () => [isA<UpdateGateWaiting>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'waits while the user keeps interacting',
      build: () => _gate(idle: const Duration(minutes: 1)),
      act: (gate) {
        _requireAfterUserIsActive(gate);
        gate
          ..add(UpdateGateUserActiveEvent())
          ..add(UpdateGateCheckEvent(isPageSafe: true));
      },
      expect: () => [isA<UpdateGateWaiting>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'ignores checks when no update is required',
      build: _gate,
      act: (gate) => gate.add(UpdateGateCheckEvent(isPageSafe: true)),
      expect: () => <UpdateGateState>[],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'fails open for the session when the page check fails',
      build: _gate,
      act: (gate) {
        _requireAfterUserIsActive(gate);
        gate
          ..add(UpdateGateCheckFailedEvent(StateError('boom'), StackTrace.empty))
          ..add(UpdateGateInfoChangedEvent(_infoRequiring('3.2.0')))
          ..add(UpdateGateCheckEvent(isPageSafe: true));
      },
      expect: () => [isA<UpdateGateWaiting>(), isA<UpdateGateHidden>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'hides again when the minimum drops back below the running version',
      build: _gate,
      act: (gate) => gate
        ..add(UpdateGateInfoChangedEvent(_infoRequiring('3.1.0')))
        ..add(UpdateGateInfoChangedEvent(_infoRequiring('2.0.0'))),
      expect: () => [isA<UpdateGateShown>(), isA<UpdateGateHidden>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'stops waiting when the requirement is lifted',
      build: _gate,
      act: (gate) {
        _requireAfterUserIsActive(gate);
        gate.add(UpdateGateInfoChangedEvent(_infoRequiring('2.0.0')));
      },
      expect: () => [isA<UpdateGateWaiting>(), isA<UpdateGateHidden>()],
    );

    blocTest<UpdateGateBloc, UpdateGateState>(
      'a later requirement is not treated as a cold launch',
      build: _gate,
      act: (gate) => gate
        ..add(UpdateGateInfoChangedEvent(_infoRequiring('3.0.0')))
        ..add(UpdateGateInfoChangedEvent(_infoRequiring('3.1.0'))),
      expect: () => [isA<UpdateGateWaiting>()],
    );
  });
}
