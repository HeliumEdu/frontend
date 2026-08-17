// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
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
    if (record.level >= Level.SEVERE) {
      if (record.error != null) {
        Sentry.captureException(record.error, stackTrace: record.stackTrace);
      } else {
        Sentry.captureMessage(record.message, level: SentryLevel.error);
      }
    } else if (record.level >= Level.WARNING) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: record.message,
          category: record.loggerName,
          level: SentryLevel.warning,
        ),
      );
    }
  }
}
