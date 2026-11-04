import 'package:flutter/foundation.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:logging/logging.dart';

final _log = Logger('config');

/// Regional presentation settings the app root applies once for every screen
/// (Material localizations, media query), mirroring [ThemeNotifier].
class RegionalSettingsNotifier extends ChangeNotifier {
  static final RegionalSettingsNotifier _instance = RegionalSettingsNotifier._internal();

  final PrefService _prefService = PrefService();

  factory RegionalSettingsNotifier() => _instance;

  RegionalSettingsNotifier._internal() {
    _prefService.init().then((_) {
      _loadFromPrefs();
      notifyListeners();
    }).catchError((Object e) {
      _log.warning('Preferences unavailable, keeping default regional settings: ${e.runtimeType}');
    });
  }

  int _weekStartsOn = RegionalFormatConstants.weekStartsOnSunday;
  int _dateFormat = RegionalFormatConstants.dateFormatMonthDayYear;
  int _timeFormat = RegionalFormatConstants.timeFormatTwelveHour;
  int _numberFormat = RegionalFormatConstants.numberFormatPoint;

  int get weekStartsOn => _weekStartsOn;

  int get dateFormat => _dateFormat;

  int get timeFormat => _timeFormat;

  int get numberFormat => _numberFormat;

  bool get uses24HourClock => _timeFormat == RegionalFormatConstants.timeFormatTwentyFourHour;

  void _loadFromPrefs() {
    _weekStartsOn = _prefService.getInt(SettingsPrefKey.weekStartsOn.key) ??
        _weekStartsOn;
    _dateFormat =
        _prefService.getInt(SettingsPrefKey.dateFormat.key) ?? _dateFormat;
    _timeFormat =
        _prefService.getInt(SettingsPrefKey.timeFormat.key) ?? _timeFormat;
    _numberFormat =
        _prefService.getInt(SettingsPrefKey.numberFormat.key) ?? _numberFormat;
  }

  Future<void> update({
    required int weekStartsOn,
    required int dateFormat,
    required int timeFormat,
    required int numberFormat,
  }) async {
    final changed = _weekStartsOn != weekStartsOn ||
        _dateFormat != dateFormat ||
        _timeFormat != timeFormat ||
        _numberFormat != numberFormat;
    _weekStartsOn = weekStartsOn;
    _dateFormat = dateFormat;
    _timeFormat = timeFormat;
    _numberFormat = numberFormat;
    await Future.wait([
      ?_prefService.setInt(SettingsPrefKey.weekStartsOn.key, weekStartsOn),
      ?_prefService.setInt(SettingsPrefKey.dateFormat.key, dateFormat),
      ?_prefService.setInt(SettingsPrefKey.timeFormat.key, timeFormat),
      ?_prefService.setInt(SettingsPrefKey.numberFormat.key, numberFormat),
    ]);
    if (changed) notifyListeners();
  }
}
