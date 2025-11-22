// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/data/models/auth/update_settings_request_model.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/data/repositories/auth_repository_impl.dart';
import 'package:helium_mobile/presentation/bloc/preferenceBloc/preference_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_list.dart';
import 'preference_event.dart';

class PreferenceBloc extends Bloc<PreferenceEvent, PreferenceState> {
  final AuthRepositoryImpl authRepository;

  PreferenceBloc({required this.authRepository}) : super(PreferenceState()) {
    on<IncrementOffsetEvent>(_onIncrementOffset);
    on<DecrementOffsetEvent>(_onDecrementOffset);
    on<UpdateOffsetEvent>(_onUpdateOffset);
    on<ResetOffsetEvent>(_onResetOffset);
    on<SubmitPreferencesEvent>(_onSubmitPreferences);
    on<FetchPreferencesEvent>(_onFetchPreferences);
  }

  void _onIncrementOffset(
    IncrementOffsetEvent event,
    Emitter<PreferenceState> emit,
  ) {
    emit(state.copyWith(offsetValue: state.reminderOffset + 1));
  }

  Future<void> _onFetchPreferences(
    FetchPreferencesEvent event,
    Emitter<PreferenceState> emit,
  ) async {
    try {
      final UserProfileModel profile = await authRepository.getProfile();
      final settings = profile.settings;
      if (settings == null) return;

      // Map server fields to UI state
      final defaultView = settings.defaultView;
      final timeZone = settings.timeZone;
      final eventsColor = settings.eventsColor.toLowerCase();
      final defaultReminderOffset = settings.defaultReminderOffset;
      final defaultReminderOffsetType = settings.defaultReminderOffsetType;

      final normalized = _normalizeHex(eventsColor);
      await _cacheEventColor(normalized);
      await _cacheTimeZone(timeZone);

      emit(
        state.copyWith(
          selectedDefaultView: mobileViews[defaultView],
          selectedTimeZone: timeZone,
          selectedReminderOffsetUnit:
              reminderOffsetUnits[defaultReminderOffsetType],
          selectedEventsColor: parseColor(normalized),
          offsetValue: defaultReminderOffset,
        ),
      );
    } catch (_) {
      // Ignore fetch errors for now; screen can show defaults
    }
  }

  String _mapDefaultViewIndexToName(int index) {
    switch (index) {
      case 0:
        return 'Month';
      case 1:
        return 'Week';
      case 2:
        return 'Day';
      default:
        return 'Todos';
    }
  }

  String _mapReminderOffsetTypeIndexToName(int index) {
    switch (index) {
      case 0:
        return 'Minutes';
      case 1:
        return 'Hours';
      case 2:
        return 'Days';
      default:
        return 'Weeks';
    }
  }

  void _onDecrementOffset(
    DecrementOffsetEvent event,
    Emitter<PreferenceState> emit,
  ) {
    if (state.reminderOffset > 0) {
      emit(state.copyWith(offsetValue: state.reminderOffset - 1));
    }
  }

  void _onUpdateOffset(UpdateOffsetEvent event, Emitter<PreferenceState> emit) {
    if (event.value >= 0) {
      emit(state.copyWith(offsetValue: event.value));
    }
  }

  void _onResetOffset(ResetOffsetEvent event, Emitter<PreferenceState> emit) {
    emit(state.copyWith(offsetValue: 0));
  }

  Future<void> _onSubmitPreferences(
    SubmitPreferencesEvent event,
    Emitter<PreferenceState> emit,
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
      await _cacheEventColor(event.eventsColor);
      await _cacheTimeZone(request.timeZone);

      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: true,
          selectedDefaultView: mobileViews[event.defaultView],
          selectedTimeZone: event.timeZone,
          selectedReminderOffsetUnit:
              reminderOffsetUnits[event.defaultReminderOffsetType],
          selectedEventsColor: parseColor(event.eventsColor),
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

  Future<void> _cacheEventColor(String hex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventColorPrefsKey, _normalizeHex(hex));
  }

  Future<void> _cacheTimeZone(String timeZone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTimeZonePrefsKey, timeZone);
  }

  static const String _eventColorPrefsKey = 'user_events_color';
  static const String _userTimeZonePrefsKey = 'user_time_zone';
}
