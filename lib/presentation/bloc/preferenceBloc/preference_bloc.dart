import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/preferenceBloc/preference_states.dart';
import 'package:helium_student_flutter/data/models/auth/update_settings_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/user_profile_model.dart';
import 'package:helium_student_flutter/data/repositories/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    emit(state.copyWith(offsetValue: state.offsetValue + 1));
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
      final defaultReminderType = settings.defaultReminderType;

      final normalized = _normalizeHex(eventsColor);
      await _cacheEventColor(normalized);

      emit(
        state.copyWith(
          selectedDefaultPreference: _mapDefaultViewIndexToName(defaultView),
          selectedTimezonePreference: timeZone,
          selectedReminderTypePreference: _mapReminderOffsetTypeIndexToName(
            defaultReminderOffsetType,
          ),
          selectedReminderPreference: _mapReminderTypeIndexToName(
            defaultReminderType,
          ),
          selectedColor: _parseColor(normalized),
          offsetValue: defaultReminderOffset,
        ),
      );
    } catch (_) {
      // Ignore fetch errors for now; screen can show defaults
    }
  }

  String _mapDefaultViewIndexToName(int index) {
    // 0=list,1=month,2=week,3=day
    switch (index) {
      case 1:
        return 'Month';
      case 2:
        return 'Week';
      case 3:
        return 'Day';
      default:
        return 'List';
    }
  }

  String _mapReminderOffsetTypeIndexToName(int index) {
    // Map to remainderTypePreferences: [Hour, Mints, Day, Week]
    switch (index) {
      case 1:
        return 'Mints';
      case 2:
        return 'Day';
      case 3:
        return 'Week';
      default:
        return 'Hour';
    }
  }

  String _mapReminderTypeIndexToName(int index) {
    // Map to remainderPreferences: [Popup, Email, Text]
    switch (index) {
      case 1:
        return 'Email';
      case 2:
        return 'Text';
      default:
        return 'Popup';
    }
  }

  Color _parseColor(String hex) {
    String h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 3) {
      h = h.split('').map((c) => '$c$c').join();
    }
    return Color(int.parse('ff$h', radix: 16));
  }

  void _onDecrementOffset(
    DecrementOffsetEvent event,
    Emitter<PreferenceState> emit,
  ) {
    if (state.offsetValue > 0) {
      emit(state.copyWith(offsetValue: state.offsetValue - 1));
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
      final sanitizedColor = _selectAllowedColor(event.eventsColor);

      final request = UpdateSettingsRequestModel(
        timeZone: event.timeZone,
        defaultView: event.defaultView,
        weekStartsOn: 0,
        showGettingStarted: true,
        eventsColor: sanitizedColor,
        defaultReminderOffset: event.defaultReminderOffset,
        calendarEventLimit: true,
        defaultReminderOffsetType: event.defaultReminderOffsetType,
        defaultReminderType: event.defaultReminderType,
        receiveEmailsFromAdmin: true,
      );

      await authRepository.updateUserSettings(request);
      await _cacheEventColor(sanitizedColor);

      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: true,
          selectedDefaultPreference:
              _mapDefaultViewIndexToName(event.defaultView),
          selectedTimezonePreference: event.timeZone,
          selectedReminderPreference:
              _mapReminderTypeIndexToName(event.defaultReminderType),
          selectedReminderTypePreference: _mapReminderOffsetTypeIndexToName(
            event.defaultReminderOffsetType,
          ),
          selectedColor: _parseColor(sanitizedColor),
          offsetValue: event.defaultReminderOffset,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }

  // Allowed colors enforced by API (HeliumEdu palette)
  static const List<String> _allowedColors = [
    '#ac725e',
    '#d06b64',
    '#f83a22',
    '#fa573c',
    '#ff7537',
    '#ffad46',
    '#42d692',
    '#16a765',
    '#7bd148',
    '#b3dc6c',
    '#fbe983',
    '#fad165',
    '#92e1c0',
    '#9fe1e7',
    '#9fc6e7',
    '#4986e7',
    '#9a9cff',
    '#b99aff',
    '#c2c2c2',
    '#cabdbf',
    '#cca6ac',
    '#f691b2',
    '#cd74e6',
    '#a47ae2',
  ];

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

  String _selectAllowedColor(String hex) {
    final normalized = _normalizeHex(hex);
    if (_allowedColors.contains(normalized)) return normalized;
    // map to nearest allowed by RGB distance
    List<int> _rgb(String h) {
      final s = h.substring(1);
      return [
        int.parse(s.substring(0, 2), radix: 16),
        int.parse(s.substring(2, 4), radix: 16),
        int.parse(s.substring(4, 6), radix: 16),
      ];
    }

    final target = _rgb(normalized);
    double bestDist = double.infinity;
    String best = _allowedColors.first;
    for (final c in _allowedColors) {
      final rgb = _rgb(c);
      final dr = (rgb[0] - target[0]).toDouble();
      final dg = (rgb[1] - target[1]).toDouble();
      final db = (rgb[2] - target[2]).toDouble();
      final d = dr * dr + dg * dg + db * db;
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best;
  }

  Future<void> _cacheEventColor(String hex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventColorPrefsKey, _normalizeHex(hex));
  }

  static const String _eventColorPrefsKey = 'user_events_color';
}
