import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.time_zone_database');

/// Warms the bundled time zone database asset, which consumers read directly
/// and treat as permanently unavailable if the load fails.
class TimeZoneDatabaseService {
  static const _assetKey = 'packages/timezone/data/latest_all.tzf';

  bool _isLoaded = false;
  Future<bool>? _pending;

  static TimeZoneDatabaseService _instance =
      TimeZoneDatabaseService._internal();

  factory TimeZoneDatabaseService() => _instance;

  TimeZoneDatabaseService._internal();

  @visibleForTesting
  TimeZoneDatabaseService.forTesting({bool isLoaded = false})
    : _isLoaded = isLoaded;

  @visibleForTesting
  static void setInstanceForTesting(TimeZoneDatabaseService instance) {
    _instance = instance;
  }

  /// Whether the asset is available, fetching it once per session. Only
  /// success is memoized, so a failure is retried by the next call.
  /// Never throws.
  Future<bool> ensureLoaded() {
    if (_isLoaded) return Future.value(true);

    return _pending ??= _load();
  }

  Future<bool> _load() async {
    try {
      await rootBundle.load(_assetKey);
      _isLoaded = true;
      return true;
    } catch (e) {
      _log.warning('Failed to load the time zone database asset', e);
      _pending = null;
      return false;
    }
  }
}
