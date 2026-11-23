import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:timezone/timezone.dart' as tz;

/// Refreshes open screens in place when a new day starts, on the device clock
/// (the calendar's today) and in the account's time zone (the day items are
/// due), and tells listeners which device day just ended.
class DayChangeService {
  static final DayChangeService _instance = DayChangeService._internal();

  factory DayChangeService() => _instance;

  DayChangeService._internal();

  final List<ValueChanged<DateTime>> _deviceDayEndedListeners = [];
  Timer? _timer;

  void addDeviceDayEndedListener(ValueChanged<DateTime> listener) =>
      _deviceDayEndedListeners.add(listener);

  void removeDeviceDayEndedListener(ValueChanged<DateTime> listener) =>
      _deviceDayEndedListeners.remove(listener);

  /// Arms the timer for the next day start; call again when the account's
  /// time zone changes.
  void scheduleRefresh() {
    _timer?.cancel();
    final now = DateTime.now();
    final deviceDay = HeliumDateTime.dateOnly(now);
    _timer = Timer(
      nextDayStart(now, _accountTimeZone()).difference(now),
      () => _onDayStarted(deviceDay),
    );
  }

  /// The earlier of the next device midnight and the next midnight in
  /// [timeZone].
  @visibleForTesting
  static DateTime nextDayStart(DateTime now, tz.Location? timeZone) {
    final deviceMidnight = HeliumDateTime.addDays(
      HeliumDateTime.dateOnly(now),
      1,
    );
    if (timeZone == null) return deviceMidnight;
    final accountMidnight = HeliumDateTime.addDays(
      HeliumDateTime.midnightIn(now, timeZone),
      1,
    );
    return accountMidnight.isBefore(deviceMidnight)
        ? accountMidnight
        : deviceMidnight;
  }

  void _onDayStarted(DateTime deviceDayBefore) {
    if (!DateUtils.isSameDay(DateTime.now(), deviceDayBefore)) {
      for (final listener in List<ValueChanged<DateTime>>.of(
        _deviceDayEndedListeners,
      )) {
        listener(deviceDayBefore);
      }
    }
    DioClient().cacheService.refreshInPlace(reason: 'new day');
    scheduleRefresh();
  }

  tz.Location? _accountTimeZone() {
    final name = PrefService().getString(SettingsPrefKey.timeZone.key);
    return name == null ? null : tz.timeZoneDatabase.locations[name];
  }
}
