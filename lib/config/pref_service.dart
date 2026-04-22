// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('config');

/// SharedPreferences keys for cached user settings.
enum SettingsPrefKey {
  timeZone('time_zone'),
  colorByCategory('color_by_category'),
  defaultView('default_view'),
  colorSchemeTheme('color_scheme_theme'),
  weekStartsOn('week_starts_on'),
  whatsNewVersionSeen('whats_new_version_seen'),
  showGettingStarted('show_getting_started'),
  eventsColor('events_color'),
  resourceColor('material_color'),
  gradeColor('grade_color'),
  defaultReminderType('default_reminder_type'),
  defaultReminderOffset('default_reminder_offset'),
  defaultReminderOffsetType('default_reminder_offset_type'),
  calendarUseCategoryColors('calendar_use_category_colors'),
  showPlannerTooltips('show_planner_tooltips'),
  rememberFilterState('remember_filter_state'),
  dragAndDropOnMobile('drag_and_drop_on_mobile'),
  isSetupComplete('is_setup_complete'),
  calendarEventLimit('calendar_event_limit'),
  atRiskThreshold('at_risk_threshold'),
  onTrackTolerance('on_track_tolerance'),
  showWeekNumbers('show_week_numbers');

  const SettingsPrefKey(this.key);

  final String key;

  static Iterable<String> get allKeys => values.map((v) => v.key);
}

class PrefService {
  FlutterSecureStorage? _secureStorageOverride;
  FlutterSecureStorage get _secureStorage =>
      _secureStorageOverride ??
      const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked,
        ),
      );

  SharedPreferencesWithCache? _sharedStorage;

  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  static PrefService _instance = PrefService._internal();

  factory PrefService() => _instance;

  PrefService._internal();

  @visibleForTesting
  PrefService.forTesting({
    required FlutterSecureStorage secureStorage,
    required SharedPreferencesWithCache sharedStorage,
  })  : _secureStorageOverride = secureStorage,
        _sharedStorage = sharedStorage,
        _isInitialized = true;

  @visibleForTesting
  static void resetForTesting() {
    _instance = PrefService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(PrefService instance) {
    _instance = instance;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      _sharedStorage = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    } finally {
      if (_isInitialized) {
        _initCompleter = null;
      }
    }
  }

  bool get isInitialized => _isInitialized;

  List<String>? getStringList(String key) {
    return _sharedStorage?.getStringList(key);
  }

  String? getString(String key) {
    return _sharedStorage?.getString(key);
  }

  int? getInt(String key) {
    return _sharedStorage?.getInt(key);
  }

  bool? getBool(String key) {
    return _sharedStorage?.getBool(key);
  }

  Future<void>? setStringList(String key, List<String> value) {
    return _sharedStorage?.setStringList(key, value);
  }

  Future<void>? setString(String key, String value) {
    return _sharedStorage?.setString(key, value);
  }

  Future<void>? setInt(String key, int value) {
    return _sharedStorage?.setInt(key, value);
  }

  Future<void>? setBool(String key, bool value) {
    return _sharedStorage?.setBool(key, value);
  }

  Future<String?> getSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (e) {
      if (e.message?.contains('-25308') == true) {
        _log.warning('Keychain unavailable for key=$key (${e.message})');
        return null;
      }
      rethrow;
    }
  }

  Future<void> setSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on PlatformException catch (e) {
      // Edge case for this iOS keychain error, which means the item already
      // exists; delete and retry
      if (e.message?.contains('-25299') == true) {
        await _secureStorage.delete(key: key);
        await _secureStorage.write(key: key, value: value);
      } else {
        rethrow;
      }
    }
  }

  Future<void>? deleteSecure(String key) {
    return _secureStorage.delete(key: key);
  }

  Future<void> removeKeys(Iterable<String> keys) async {
    if (_sharedStorage == null) return;
    await Future.wait([for (final key in keys) _sharedStorage!.remove(key)]);
  }

  Future<List<void>>? clear() async {
    return Future.wait([_sharedStorage!.clear(), _secureStorage.deleteAll()]);
  }
}
