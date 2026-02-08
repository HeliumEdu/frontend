// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = Logger('core');

class SentryService {
  static final SentryService _instance = SentryService._internal();

  factory SentryService() => _instance;

  SentryService._internal();

  Future<void> init() async {
    await SentryFlutter.init((options) {
      options.dsn =
          'https://d6522731f64a56983e3504ed78390601@o4510767194570752.ingest.us.sentry.io/4510767197519872';
      const release = String.fromEnvironment('SENTRY_RELEASE');
      if (release.isNotEmpty) {
        options.release = release;
      }

      options.beforeSend = _beforeSend;
    });

    _log.info('Sentry initialized successfully');
  }

  SentryEvent? _beforeSend(SentryEvent event, Hint? hint) {
    final exceptions = event.exceptions;
    if (exceptions != null && exceptions.isNotEmpty) {
      final exceptionType = exceptions.first.type;
      final exceptionValue = exceptions.first.value;

      if (exceptionType == 'DioException' && exceptionValue != null) {
        // Filter expected user authentication errors (not bugs)

        // 401 on login endpoint = wrong credentials (expected user error)
        if (exceptionValue.contains('status code of 401') &&
            exceptionValue.contains('/auth/token/')) {
          _log.info('Filtered login failure from Sentry');
          return null;
        }

        // 401/403 on account deletion = wrong password (expected user error)
        if ((exceptionValue.contains('status code of 401') ||
                exceptionValue.contains('status code of 403')) &&
            exceptionValue.contains('/auth/user/delete/')) {
          _log.info('Filtered account deletion auth error from Sentry');
          return null;
        }

        // 400/401 on email verification = wrong/expired code (expected user error)
        if ((exceptionValue.contains('status code of 400') ||
                exceptionValue.contains('status code of 401')) &&
            exceptionValue.contains('/auth/user/verify/')) {
          _log.info('Filtered verification error from Sentry');
          return null;
        }
      }
    }

    return event;
  }
}
