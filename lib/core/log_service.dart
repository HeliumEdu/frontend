import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/log_formatter.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LogService {
  static final LogService _instance = LogService._internal();

  factory LogService() => _instance;

  LogService._internal();

  void init() {
    // Use --dart-define=LOG_LEVEL=FINE to set a log level in development
    const logLevelName = String.fromEnvironment(
      'LOG_LEVEL',
      defaultValue: 'INFO',
    );
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == logLevelName.toUpperCase(),
      orElse: () => Level.INFO,
    );

    if (!kReleaseMode) {
      Logger.root.onRecord.listen((record) {
        // ignore: avoid_print
        print(LogFormatter.format(record));
      });
    } else if (SentryService().isEnabled) {
      Logger.root.onRecord.listen(_forwardToSentry);
    }
  }

  void _forwardToSentry(LogRecord record) {
    switch (classifyRecord(record)) {
      case LogSentryAction.captureException:
        Sentry.captureException(record.error, stackTrace: record.stackTrace);
      case LogSentryAction.captureMessage:
        Sentry.captureMessage(record.message, level: SentryLevel.error);
      case LogSentryAction.breadcrumb:
        _addBreadcrumb(record, _breadcrumbLevelFor(record));
      case LogSentryAction.drop:
        break;
    }
  }

  /// Decides how a [LogRecord] maps onto Sentry when forwarded in release.
  /// Pure (no side effects) so the routing can be unit-tested without a hub.
  @visibleForTesting
  static LogSentryAction classifyRecord(LogRecord record) {
    if (record.level >= Level.SEVERE) {
      // Mirrors the sentry_service._beforeSend carve-outs, which match on type
      // names that AOT minifies out of their reach. ServerException and the
      // HeliumException base stay reportable.
      if (record.error is NetworkException ||
          record.error is UnauthorizedException ||
          record.error is NotFoundException ||
          record.error is ValidationException ||
          _isConnectivityFailure(record.error)) {
        return LogSentryAction.breadcrumb;
      }
      if (record.error != null) {
        return LogSentryAction.captureException;
      }
      return LogSentryAction.captureMessage;
    }
    if (record.level >= Level.INFO) {
      return LogSentryAction.breadcrumb;
    }
    return LogSentryAction.drop;
  }

  /// Connectivity failures that outlived DioClient's retries: the network path
  /// is at fault, and a real API outage surfaces in server-side monitoring.
  static bool _isConnectivityFailure(Object? error) {
    if (error is! DioException) {
      return false;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.cancel =>
        true,
      DioExceptionType.badCertificate ||
      DioExceptionType.badResponse ||
      DioExceptionType.unknown =>
        false,
    };
  }

  static SentryLevel _breadcrumbLevelFor(LogRecord record) {
    if (record.level >= Level.WARNING) {
      return SentryLevel.warning;
    }
    return SentryLevel.info;
  }

  void _addBreadcrumb(LogRecord record, SentryLevel level) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: record.message,
        category: record.loggerName,
        level: level,
      ),
    );
  }
}

/// How a forwarded [LogRecord] is routed to Sentry.
@visibleForTesting
enum LogSentryAction {
  /// Captured as an error event with the attached error + stacktrace.
  captureException,

  /// Captured as an error-level message event (no attached error).
  captureMessage,

  /// Attached as a breadcrumb (not its own event).
  breadcrumb,

  /// Not forwarded.
  drop;
}
