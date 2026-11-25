import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/locale_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('config');

/// The account's locale settings: the regional formats and language the app
/// root applies for every screen (app language, Material localizations, media
/// query), and the time zone, mirroring [ThemeNotifier].
class LocaleNotifier extends ChangeNotifier {
  static final LocaleNotifier _instance = LocaleNotifier._internal();

  final PrefService _prefService = PrefService();

  factory LocaleNotifier() => _instance;

  LocaleNotifier._internal() {
    unawaited(init().catchError((Object e) {
      _log.warning('Preferences unavailable, keeping default locale settings: ${e.runtimeType}');
    }));
  }

  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  int _weekStartsOn = RegionalFormatConstants.weekStartsOnSunday;
  int _dateFormat = RegionalFormatConstants.dateFormatMonthDayYear;
  int _timeFormat = RegionalFormatConstants.timeFormatTwelveHour;
  int _numberFormat = RegionalFormatConstants.numberFormatPoint;
  String? _language;
  String? _timeZone;

  int get weekStartsOn => _weekStartsOn;

  int get dateFormat => _dateFormat;

  int get timeFormat => _timeFormat;

  int get numberFormat => _numberFormat;

  /// The account's time zone name, or null when none is stored.
  String? get timeZone => _timeZone;

  /// The account's language, or null to follow the device while no account
  /// is signed in.
  Locale? get appLocale => _language == null ? null : Locale(_language!);

  /// The language the app displays, which the API answers in: [appLocale]
  /// resolved as the app root resolves it, else the device's.
  String get displayedLanguage => HeliumLocale.languageFor(
    appLocale == null ? PlatformDispatcher.instance.locales : [appLocale!],
    AppLocalizations.supportedLocales,
  );

  bool get uses24HourClock => _timeFormat == RegionalFormatConstants.timeFormatTwentyFourHour;

  /// Loads the stored values once; await it before anything reads them.
  Future<void> init() async {
    if (_isInitialized) return;

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    _initCompleter!.future.ignore();
    try {
      await _prefService.init();
      _loadFromPrefs();
      _isInitialized = true;
      _initCompleter!.complete();
      notifyListeners();
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

  /// Returns every value to its default, for when the stored settings are cleared.
  void reset() {
    _weekStartsOn = RegionalFormatConstants.weekStartsOnSunday;
    _dateFormat = RegionalFormatConstants.dateFormatMonthDayYear;
    _timeFormat = RegionalFormatConstants.timeFormatTwelveHour;
    _numberFormat = RegionalFormatConstants.numberFormatPoint;
    _language = null;
    _timeZone = null;
    notifyListeners();
  }

  void _loadFromPrefs() {
    _weekStartsOn = _prefService.getInt(SettingsPrefKey.weekStartsOn.key) ??
        _weekStartsOn;
    _dateFormat =
        _prefService.getInt(SettingsPrefKey.dateFormat.key) ?? _dateFormat;
    _timeFormat =
        _prefService.getInt(SettingsPrefKey.timeFormat.key) ?? _timeFormat;
    _numberFormat =
        _prefService.getInt(SettingsPrefKey.numberFormat.key) ?? _numberFormat;
    _language = _prefService.getString(SettingsPrefKey.language.key);
    _timeZone = _prefService.getString(SettingsPrefKey.timeZone.key);
  }

  Future<void> update({
    required int weekStartsOn,
    required int dateFormat,
    required int timeFormat,
    required int numberFormat,
    required String language,
    required String timeZone,
  }) async {
    final changed = _weekStartsOn != weekStartsOn ||
        _dateFormat != dateFormat ||
        _timeFormat != timeFormat ||
        _numberFormat != numberFormat ||
        _language != language ||
        _timeZone != timeZone;
    _weekStartsOn = weekStartsOn;
    _dateFormat = dateFormat;
    _timeFormat = timeFormat;
    _numberFormat = numberFormat;
    _language = language;
    _timeZone = timeZone;
    await Future.wait([
      ?_prefService.setInt(SettingsPrefKey.weekStartsOn.key, weekStartsOn),
      ?_prefService.setInt(SettingsPrefKey.dateFormat.key, dateFormat),
      ?_prefService.setInt(SettingsPrefKey.timeFormat.key, timeFormat),
      ?_prefService.setInt(SettingsPrefKey.numberFormat.key, numberFormat),
      ?_prefService.setString(SettingsPrefKey.timeZone.key, timeZone),
      ?_prefService.setString(SettingsPrefKey.language.key, language),
    ]);
    unawaited(AnalyticsService().setUserProperty(name: 'app_language', value: displayedLanguage));
    if (changed) notifyListeners();
  }
}
