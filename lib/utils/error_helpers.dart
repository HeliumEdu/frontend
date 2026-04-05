// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = Logger('utils');

class ErrorHelpers {
  ErrorHelpers._();

  /// Logs [exception] locally at severe level and reports it to Sentry.
  ///
  /// Use at top-level rendering loops so a single bad item doesn't crash the
  /// entire screen. The caller should catch the exception, call this, then
  /// skip the failing item.
  static void logAndReport(
    String message,
    Object exception,
    StackTrace stackTrace, {
    Map<String, dynamic>? hints,
  }) {
    _log.severe(message, exception, stackTrace);
    Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hints != null ? Hint.withMap(hints) : null,
    );
  }
}
