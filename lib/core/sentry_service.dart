// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = Logger('core');

class SentryService {
  static final SentryService _instance = SentryService._internal();

  factory SentryService() => _instance;

  SentryService._internal();

  /// Exposed for testing - returns true if the event should be filtered (dropped)
  @visibleForTesting
  static bool shouldFilterEvent(SentryEvent event) {
    return _instance._shouldFilter(event);
  }

  Future<void> init() async {
    await SentryFlutter.init((options) {
      options.dsn =
          'https://d6522731f64a56983e3504ed78390601@o4510767194570752.ingest.us.sentry.io/4510767197519872';
      const release = String.fromEnvironment('SENTRY_RELEASE');
      if (release.isNotEmpty) {
        options.release = release;
        options.environment = 'prod';
      }

      // Performance monitoring
      options.tracesSampleRate = 0.1;
      options.profilesSampleRate = 0.1;

      // Track user interactions and navigation
      options.enableAutoPerformanceTracing = true;
      options.enableUserInteractionTracing = true;

      options.beforeSend = _beforeSend;
    });

    _log.info('Sentry initialized successfully');
  }

  SentryEvent? _beforeSend(SentryEvent event, Hint? hint) {
    if (_shouldFilter(event)) {
      return null;
    }
    return event;
  }

  bool _shouldFilter(SentryEvent event) {
    // Check the exception types in the event
    if (event.exceptions != null) {
      for (final exception in event.exceptions!) {
        if (_shouldFilterSentryException(exception)) {
          _log.info('Filtered auth error from Sentry (via SentryException)');
          return true;
        }
      }
    }

    // Fall back to text-based filtering for edge cases
    if (_shouldFilterByText(event)) {
      _log.info('Filtered auth error from Sentry (via text matching)');
      return true;
    }

    return false;
  }

  /// Check SentryException type and value
  bool _shouldFilterSentryException(SentryException exception) {
    final type = exception.type?.toLowerCase() ?? '';
    final value = exception.value?.toLowerCase() ?? '';
    final combined = '$type $value';

    // Check exception types directly
    if (type.contains('unauthorizedexception')) {
      return true;
    }

    // Check for DioException with auth status codes
    if (type.contains('dioexception') || combined.contains('dio')) {
      if (_containsAuthStatusCode(combined)) {
        return true;
      }
    }

    // Check for any HTTP error with auth status codes
    if (_containsAuthStatusCode(combined) && _looksLikeHttpError(combined)) {
      return true;
    }

    return false;
  }

  /// Text-based filtering as a fallback
  bool _shouldFilterByText(SentryEvent event) {
    final textParts = <String>[
      event.message?.formatted ?? '',
      if (event.exceptions != null)
        ...event.exceptions!.map((e) => '${e.type ?? ''} ${e.value ?? ''}'),
    ];
    final eventText = textParts.join(' ').toLowerCase();

    // Filter /auth/user/verify/ 400 errors
    if (eventText.contains('/auth/user/verify/') &&
        eventText.contains('400')) {
      return true;
    }

    // Filter any text mentioning 401/403 in HTTP context
    if (_containsAuthStatusCode(eventText) && _looksLikeHttpError(eventText)) {
      return true;
    }

    return false;
  }

  /// Check if text contains 401 or 403 status codes
  bool _containsAuthStatusCode(String text) {
    return text.contains('401') || text.contains('403');
  }

  /// Check if text looks like an HTTP error
  bool _looksLikeHttpError(String text) {
    return text.contains('status') ||
        text.contains('response') ||
        text.contains('request') ||
        text.contains('http') ||
        text.contains('api') ||
        text.contains('dio') ||
        text.contains('unauthorized') ||
        text.contains('forbidden');
  }
}
