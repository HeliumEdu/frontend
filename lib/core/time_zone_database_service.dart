import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.time_zone_database');

/// Warms the bundled time zone database asset, which consumers read directly
/// and treat as permanently unavailable if the load fails.
class TimeZoneDatabaseService {
  static const _assetKey = 'packages/timezone/data/latest_all.tzf';

  bool _isLoaded = false;
  Future<bool>? _pending;

  static final TimeZoneDatabaseService _instance =
      TimeZoneDatabaseService._internal();

  factory TimeZoneDatabaseService() => _instance;

  TimeZoneDatabaseService._internal();

  /// Whether the asset is available, fetching it once per session. Only
  /// success is memoized, so a failure is retried by the next call.
  /// Never throws.
  Future<bool> ensureLoaded() {
    if (_isLoaded) return Future.value(true);

    return _pending ??= _load();
  }

  Future<bool> _load() async {
    try {
      final asset = await rootBundle.load(_assetKey);
      if (asset.lengthInBytes == 0) {
        return _recordFailure('The time zone database asset loaded empty');
      }
      _isLoaded = true;
      return true;
    } catch (e) {
      return _recordFailure('Failed to load the time zone database asset', e);
    }
  }

  bool _recordFailure(String message, [Object? error]) {
    _log.warning(message, error);
    _pending = null;
    return false;
  }
}
