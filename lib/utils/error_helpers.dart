import 'package:heliumapp/core/session_health.dart';
import 'package:logging/logging.dart';

final _log = Logger('utils');

class ErrorHelpers {
  /// Logs [exception] at severe level, which LogService forwards to Sentry
  /// with the stack trace attached.
  ///
  /// Use at top-level rendering loops so a single bad item doesn't crash the
  /// entire screen. The caller should catch the exception, call this, then
  /// skip the failing item.
  static void logAndReport(
    String message,
    Object exception,
    StackTrace stackTrace,
  ) {
    SessionHealth.markTroubled();

    _log.severe(message, exception, stackTrace);
  }
}
