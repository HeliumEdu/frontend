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
      case LogSentryAction.log:
        _sendLog(record);
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
      // Downgraded by type, which survives AOT minification — sentry_service no
      // longer carries a peer filter for these, since matching on type names
      // does not. ServerException and the HeliumException base stay reportable.
      if (record.error is NetworkException ||
          record.error is UnauthorizedException ||
          record.error is NotFoundException ||
          record.error is ValidationException ||
          _isConnectivityFailure(record.error)) {
        return LogSentryAction.log;
      }
      if (record.error != null) {
        return LogSentryAction.captureException;
      }
      return LogSentryAction.captureMessage;
    }
    if (record.level >= Level.INFO) {
      return LogSentryAction.log;
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
      DioExceptionType.unknown => _isTlsFailure(error),
      DioExceptionType.badCertificate || DioExceptionType.badResponse => false,
    };
  }

  /// TLS failures arrive as `unknown`, which otherwise stays reportable: it wraps real bugs.
  static bool _isTlsFailure(DioException error) {
    final text = '${error.message ?? ''} ${error.error ?? ''}'.toLowerCase();

    return text.contains('handshakeexception') ||
        text.contains('tlsexception') ||
        text.contains('certificate_verify_failed');
  }

  static SentryLevel _breadcrumbLevelFor(LogRecord record) {
    if (record.level >= Level.WARNING) {
      return SentryLevel.warning;
    }
    return SentryLevel.info;
  }

  void _sendLog(LogRecord record) {
    final logger = Sentry.logger;
    final body = record.message;
    final attributes = _logAttributes(record);
    if (record.level >= Level.SEVERE) {
      logger.error(body, attributes: attributes);
    } else if (record.level >= Level.WARNING) {
      logger.warn(body, attributes: attributes);
    } else {
      logger.info(body, attributes: attributes);
    }
  }

  Map<String, SentryAttribute> _logAttributes(LogRecord record) {
    final tlsFailureReason = tlsFailureReasonOf(record.error);

    return {
      'logger': SentryAttribute.string(record.loggerName),
      'level': SentryAttribute.string(record.level.name),
      if (record.error != null)
        'error_type': SentryAttribute.string(
          record.error.runtimeType.toString(),
        ),
      if (tlsFailureReason != null)
        'tls_failure_reason': SentryAttribute.string(tlsFailureReason),
    };
  }

  /// Normalized reason a TLS handshake was rejected, so a genuine certificate
  /// regression stays distinguishable from a network intercepting the
  /// connection — these never become events, and the reason is absent from the
  /// log body, so without this they are all one indistinguishable line.
  ///
  /// Returns a fixed token, never text from the exception.
  @visibleForTesting
  static String? tlsFailureReasonOf(Object? error) {
    if (error is! DioException || !_isTlsFailure(error)) {
      return null;
    }

    final text = '${error.message ?? ''} ${error.error ?? ''}'.toLowerCase();
    if (text.contains('hostname mismatch')) {
      return 'hostname_mismatch';
    }
    if (text.contains('application verification failure')) {
      return 'application_verification';
    }
    if (text.contains('certificate has expired')) {
      return 'certificate_expired';
    }
    if (text.contains('self signed certificate')) {
      return 'self_signed';
    }
    if (text.contains('unable to get local issuer')) {
      return 'unknown_issuer';
    }
    return 'other';
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

  /// Sent to Sentry Logs *and* kept as a breadcrumb — queryable later, without
  /// raising an issue.
  log,

  /// Not forwarded.
  drop;
}
