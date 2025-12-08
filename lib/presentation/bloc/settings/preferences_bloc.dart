// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/data/models/auth/update_settings_request_model.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/data/repositories/auth_repository_impl.dart';
import 'package:helium_mobile/presentation/bloc/settings/preferences_event.dart';
import 'package:helium_mobile/presentation/bloc/settings/preferences_states.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_enums.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final AuthRepositoryImpl authRepository;

  PreferencesBloc({required this.authRepository}) : super(PreferencesState()) {
    on<IncrementOffsetEvent>(_onIncrementOffset);
    on<DecrementOffsetEvent>(_onDecrementOffset);
    on<UpdateOffsetEvent>(_onUpdateOffset);
    on<ResetOffsetEvent>(_onResetOffset);
    on<SubmitPreferencesEvent>(_onSubmitPreferences);
    on<FetchPreferencesEvent>(_onFetchPreferences);
  }

  void _onIncrementOffset(
    IncrementOffsetEvent event,
    Emitter<PreferencesState> emit,
  ) {
    emit(state.copyWith(offsetValue: state.reminderOffset + 1));
  }

  Future<void> _onFetchPreferences(
    FetchPreferencesEvent event,
    Emitter<PreferencesState> emit,
  ) async {
    try {
      final UserProfileModel profile = await authRepository.getProfile();
      final settings = profile.settings;
      if (settings == null) return;

      // Map server fields to UI state
      final defaultView = settings.defaultView;
      final timeZone = settings.timeZone;
      final eventsColor = settings.eventsColor.toLowerCase();
      final materialsColor = settings.materialsColor.toLowerCase();
      final gradesColor = settings.gradesColor.toLowerCase();
      final defaultReminderOffset = settings.defaultReminderOffset;
      final defaultReminderOffsetType = settings.defaultReminderOffsetType;

      final normalizedEventsColor = _normalizeHex(eventsColor);
      final normalizedMaterialsColor = _normalizeHex(materialsColor);
      final normalizedGradesColor = _normalizeHex(gradesColor);

      emit(
        state.copyWith(
          selectedDefaultView: mobileViews[defaultView],
          selectedTimeZone: timeZone,
          selectedReminderOffsetUnit:
              reminderOffsetUnits[defaultReminderOffsetType],
          selectedEventsColor: hexToColor(normalizedEventsColor),
          selectedMaterialsColor: hexToColor(normalizedMaterialsColor),
          selectedGradesColor: hexToColor(normalizedGradesColor),
          offsetValue: defaultReminderOffset,
        ),
      );
    } catch (_) {
      // Ignore fetch errors for now; screen can show defaults
    }
  }

  void _onDecrementOffset(
    DecrementOffsetEvent event,
    Emitter<PreferencesState> emit,
  ) {
    if (state.reminderOffset > 0) {
      emit(state.copyWith(offsetValue: state.reminderOffset - 1));
    }
  }

  void _onUpdateOffset(UpdateOffsetEvent event, Emitter<PreferencesState> emit) {
    if (event.value >= 0) {
      emit(state.copyWith(offsetValue: event.value));
    }
  }

  void _onResetOffset(ResetOffsetEvent event, Emitter<PreferencesState> emit) {
    emit(state.copyWith(offsetValue: 0));
  }

  Future<void> _onSubmitPreferences(
    SubmitPreferencesEvent event,
    Emitter<PreferencesState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        submitError: null,
        submitSuccess: false,
      ),
    );

    try {
      final request = UpdateSettingsRequestModel(
        timeZone: event.timeZone,
        defaultView: event.defaultView,
        weekStartsOn: 0,
        showGettingStarted: true,
        eventsColor: event.eventsColor,
        defaultReminderOffset: event.defaultReminderOffset,
        calendarEventLimit: true,
        defaultReminderOffsetType: event.defaultReminderOffsetType,
        receiveEmailsFromAdmin: true,
      );

      await authRepository.updateUserSettings(request);

      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: true,
          selectedDefaultView: mobileViews[event.defaultView],
          selectedTimeZone: event.timeZone,
          selectedReminderOffsetUnit:
              reminderOffsetUnits[event.defaultReminderOffsetType],
          selectedEventsColor: hexToColor(event.eventsColor),
          selectedMaterialsColor: hexToColor(event.materialsColor),
          selectedGradesColor: hexToColor(event.gradesColor),
          offsetValue: event.defaultReminderOffset,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }

  String _normalizeHex(String hex) {
    if (hex.isEmpty) return '#ac725e';
    String h = hex.trim().toLowerCase();
    if (!h.startsWith('#')) h = '#$h';
    // Convert #argb or #aarrggbb to #rrggbb if needed
    if (h.length == 9) {
      // strip alpha
      h = '#${h.substring(3)}';
    } else if (h.length == 5) {
      // #argb shorthand -> expand then strip alpha (rare for our input)
      final a = h[1], r = h[2], g = h[3], b = h[4];
      final expanded = '#$a$a$r$r$g$g$b$b';
      h = '#${expanded.substring(3)}';
    }
    return h;
  }
}
