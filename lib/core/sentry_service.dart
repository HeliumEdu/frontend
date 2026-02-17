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
        options.environment = 'prod';
      }

      options.beforeSend = _beforeSend;
    });

    _log.info('Sentry initialized successfully');
  }

  SentryEvent? _beforeSend(SentryEvent event, Hint? hint) {
    final textParts = <String>[
      event.message?.formatted ?? '',
      if (event.exceptions != null)
        ...event.exceptions!.map((e) => '${e.type ?? ''} ${e.value ?? ''}'),
    ];
    final eventText = textParts.join(' ').toLowerCase();

    final isVerify400 =
        eventText.contains('/auth/user/verify/') &&
        eventText.contains('status code of 400');
    if (isVerify400) {
      _log.info('Filtered /auth/user/verify/ 400 from Sentry (event text)');
      return null;
    }

    final isAuthStatus =
        eventText.contains('status code of 401') ||
        eventText.contains('status code of 403') ||
        eventText.contains('http 401') ||
        eventText.contains('http 403');
    final looksLikeDio = eventText.contains('dioexception');

    if (looksLikeDio && isAuthStatus) {
      _log.info('Filtered 401/403 DioException from Sentry (event text)');
      return null;
    }

    return event;
  }
}
