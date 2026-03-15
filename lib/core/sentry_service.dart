// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = Logger('core');

class SentryService {
  static final SentryService _instance = SentryService._internal();

  factory SentryService() => _instance;

  SentryService._internal();

  static const _nativeChannel = MethodChannel('com.heliumedu.heliumapp/native');

  /// Exposed for testing - returns true if the event should be filtered (dropped)
  @visibleForTesting
  static bool shouldFilterEvent(SentryEvent event) {
    return _instance._shouldFilter(event);
  }

  Future<void> init() async {
    // Skip Sentry entirely on Google Play pre-launch test farm devices.
    // Native crashes bypass Dart-level filters (sent via captureEnvelope),
    // so we must prevent initialization at the source.
    if (await _isTestFarmDevice()) {
      _log.info('Skipping Sentry initialization (test farm device)');
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn =
          'https://d6522731f64a56983e3504ed78390601@o4510767194570752.ingest.us.sentry.io/4510767197519872';

      const release = String.fromEnvironment('RELEASE_VERSION');
      const dist = String.fromEnvironment('SENTRY_DIST');
      const environment = String.fromEnvironment('SENTRY_ENVIRONMENT');
      if (release.isNotEmpty) {
        options.release = release;
        // Default to 'prod' for release builds, but allow override
        options.environment = environment.isNotEmpty ? environment : 'prod';
      } else if (environment.isNotEmpty) {
        // Local builds without a release can still set an environment
        options.environment = environment;
      }
      if (dist.isNotEmpty) {
        options.dist = dist;
      }

      // Performance monitoring
      options.tracesSampleRate = 0.1;
      // ignore: experimental_member_use
      options.profilesSampleRate = 0.1;

      // Track user interactions and navigation
      options.enableAutoPerformanceTracing = true;
      options.enableUserInteractionTracing = true;

      // Belt-and-suspenders for auth errors with non-null values. In
      // sentry_flutter, ignoreErrors is a Dart-side filter that runs on the
      // deserialized SentryEvent — same as beforeSend. For onerror events where
      // exception.value is null after deserialization, neither filter can match;
      // those cases are prevented at the source (see _authRedirect in
      // app_router.dart).
      options.ignoreErrors = [
        '(?i)(status code of|http status error \\[)(401|403)',
        // DioException "bad response" format with auth status codes
        '(?i)dioexception.*bad response.*(401|403)',
        '(?i)bad response.*(401|403)',
        // GoRouter wraps DioExceptions during redirect - catch those too
        '(?i)goexception.*(401|403)',
        // Filter CanvasKit initialization failures - these are Flutter runtime
        // issues we can't fix (usually caused by WASM loading failures or
        // browser incompatibility)
        '(?i)flutterCanvasKit.*is not a constructor',
      ];

      // Ignore background/infrastructure transactions that aren't user-initiated
      options.ignoreTransactions = [
        '(?i)/auth/token/refresh/',
        '(?i)/auth/user/pushtoken/',
      ];

      options.beforeSend = _beforeSend;
    });

    _log.info('Sentry initialized successfully');
  }

  /// Check if running on a Google Play pre-launch test farm device.
  /// Only applicable on Android; returns false on other platforms.
  Future<bool> _isTestFarmDevice() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final result =
          await _nativeChannel.invokeMethod<bool>('isTestFarmDevice');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      _log.warning('Failed to check test farm device status: $e');
      return false;
    }
  }

  SentryEvent? _beforeSend(SentryEvent event, Hint? hint) {
    if (_shouldFilter(event)) {
      return null;
    }

    // Check hint for original exception - catches browser onerror cases where
    // the exception value may be null after deserialization
    if (hint != null) {
      final originalError = hint.get('originalError');
      if (originalError != null) {
        final errorString = originalError.toString().toLowerCase();
        if (_containsAuthStatusCode(errorString) &&
            _looksLikeHttpError(errorString)) {
          _log.info('Filtered event from Sentry (via hint originalError)');
          return null;
        }
      }
    }

    return event;
  }

  bool _shouldFilter(SentryEvent event) {
    // Note: Emulator/test farm detection is handled natively on Android
    // (see HeliumApplication.kt). Sentry won't initialize on those devices.

    // Filter Apple internal/development devices (e.g., App Review infrastructure).
    // These have DEVELOPMENT kernels that regular users cannot access.
    final osContext = event.contexts.operatingSystem;
    if (osContext != null) {
      final kernelVersion = (osContext.kernelVersion ?? '').toLowerCase();
      if (kernelVersion.contains('development')) {
        _log.info('Filtered event from Sentry (Apple development device)');
        return true;
      }
    }

    // Check the exception types in the event
    if (event.exceptions != null) {
      for (final exception in event.exceptions!) {
        if (_shouldFilterSentryException(exception)) {
          _log.info('Filtered event from Sentry (via SentryException)');
          return true;
        }
      }
    }

    // Fall back to text-based filtering for edge cases
    if (_shouldFilterByText(event)) {
      _log.info('Filtered event from Sentry (via text matching)');
      return true;
    }

    return false;
  }

  /// Check SentryException type and value
  bool _shouldFilterSentryException(SentryException exception) {
    final type = exception.type?.toLowerCase() ?? '';
    final value = exception.value?.toLowerCase() ?? '';
    final combined = '$type $value';

    // Filter CanvasKit initialization failures - these are Flutter runtime
    // issues we can't fix (usually caused by WASM loading failures or
    // browser incompatibility). This complements ignoreErrors which only
    // catches window.onerror events, not FlutterError mechanism events.
    if (value.contains('fluttercanvaskit') &&
        value.contains('is not a constructor')) {
      return true;
    }

    // Check exception types directly
    if (type.contains('unauthorizedexception')) {
      return true;
    }

    // Check for GoException wrapping auth errors (e.g., during GoRouter redirects)
    if (type.contains('goexception') && _containsAuthStatusCode(combined)) {
      return true;
    }

    // Check for DioException with auth status codes (type or value may contain "dio")
    if (type.contains('dioexception') || combined.contains('dio')) {
      if (_containsAuthStatusCode(combined)) {
        return true;
      }
    }

    // Check for GoException wrapping a DioException with auth status codes.
    // GoRouter throws GoException when its redirect callback throws; the
    // wrapped DioException message ends up in the value.
    if (type.contains('goexception')) {
      if (_containsAuthStatusCode(combined) && _looksLikeHttpError(combined)) {
        return true;
      }
    }

    // Check for "status code of 401/403" pattern (common in DioException messages)
    if (value.contains('status code of 401') ||
        value.contains('status code of 403')) {
      return true;
    }

    // Check for "bad response" pattern with auth status codes
    if (value.contains('bad response') && _containsAuthStatusCode(value)) {
      return true;
    }

    // Check for any HTTP error with auth status codes
    if (_containsAuthStatusCode(combined) && _looksLikeHttpError(combined)) {
      return true;
    }

    // Filter network errors to background/infrastructure endpoints - these are
    // expected when the device goes offline (especially in background)
    if (_looksLikeNetworkError(combined) &&
        (combined.contains('/auth/token/refresh/') ||
            combined.contains('/auth/user/pushtoken/'))) {
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

  /// Check if text looks like a network/connection error
  bool _looksLikeNetworkError(String text) {
    return text.contains('connection abort') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('connection closed') ||
        text.contains('connection timed out') ||
        text.contains('socket') ||
        text.contains('network is unreachable') ||
        text.contains('no route to host') ||
        text.contains('host unreachable');
  }
}
