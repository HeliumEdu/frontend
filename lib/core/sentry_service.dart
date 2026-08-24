import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  bool get isEnabled => !kDebugMode && !kProfileMode;

  Future<void> init() async {
    if (!isEnabled) return;

    // Skip Sentry entirely on Google Play pre-launch test farm devices.
    // Native crashes bypass Dart-level filters (sent via captureEnvelope),
    // so we must prevent initialization at the source.
    if (await _isTestFarmDevice()) {
      _log.info('Skipping Sentry initialization (test farm device)');
      return;
    }


    const environment = String.fromEnvironment('SENTRY_ENVIRONMENT');
    String release = const String.fromEnvironment('RELEASE_VERSION');
    String dist = const String.fromEnvironment('SENTRY_DIST');
    if (release.isEmpty) {
      final packageInfo = await PackageInfo.fromPlatform();
      release = '${packageInfo.version}+${packageInfo.buildNumber}';
      dist = packageInfo.buildNumber;
    }

    await SentryFlutter.init((options) {
      options.dsn =
          'https://d6522731f64a56983e3504ed78390601@o4510767194570752.ingest.us.sentry.io/4510767197519872';

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

      options.sendDefaultPii = false;
      options.enableLogs = true;
      options.maxBreadcrumbs = 200;
      options.tracesSampleRate = 0.1;
      // ignore: experimental_member_use
      options.profilesSampleRate = 0.1;
      options.enableAutoPerformanceTracing = true;
      options.enableUserInteractionTracing = true;

      // Our API traffic all runs through Dio, whose integration already
      // captures 5xx. Native capture only adds third-party SDK noise (Firebase,
      // FCM) we don't control and can't act on, so turn it off.
      options.captureNativeFailedRequests = false;

      // In sentry_flutter, ignoreErrors is a Dart-side filter that runs on the
      // deserialized SentryEvent; same as beforeSend. For onerror events where
      // exception.value is null after deserialization, neither filter can match;
      // those cases are prevented at the source (see _authRedirect in
      // app_router.dart).
      options.ignoreErrors = [
        '(?i)(status code of|http status error \\[)4\\d\\d',
        '(?i)dioexception.*bad response.*4\\d\\d',
        '(?i)bad response.*4\\d\\d',
        '(?i)goexception.*4\\d\\d',
        '(?i)dioexception \\[(connection|send|receive) timeout\\]',
        '(?i)dioexception \\[connection error\\]',
        '(?i)flutterCanvasKit.*is not a constructor',
        '(?i)messaging/unsupported-browser',
        '(?i)watchdogtermination',
        '(?i)database deleted by request of the user',
        '(?i)script error',
        '(?i)importing a module script failed',
        '(?i)failed to fetch dynamically imported module',
      ];

      options.ignoreTransactions = [
        '(?i)/auth/token/refresh/',
        '(?i)/auth/user/pushtoken/',
      ];

      options.beforeSend = _beforeSend;
    });

    _log.info('Sentry initialized successfully');
  }

  void setUser(String? userId) {
    if (!isEnabled || userId == null) return;
    try {
      Sentry.configureScope((scope) => scope.setUser(SentryUser(id: userId)));
    } catch (e) {
      _log.warning('Failed to set Sentry user context', e);
    }
  }

  void clearUser() {
    if (!isEnabled) return;
    try {
      Sentry.configureScope((scope) => scope.setUser(null));
    } catch (e) {
      _log.warning('Failed to clear Sentry user context', e);
    }
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
        if (_containsClientErrorStatusCode(errorString) &&
            _looksLikeHttpError(errorString)) {
          _log.fine('Filtered event from Sentry (via hint originalError)');
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
        _log.fine('Filtered event from Sentry (Apple development device)');
        return true;
      }
    }

    if (event.exceptions != null) {
      for (final exception in event.exceptions!) {
        if (_shouldFilterSentryException(exception)) {
          _log.fine('Filtered event from Sentry (via SentryException)');
          return true;
        }
      }
    }

    if (_shouldFilterByText(event)) {
      _log.fine('Filtered event from Sentry (via text matching)');
      return true;
    }

    return false;
  }

  /// Check SentryException type and value
  bool _shouldFilterSentryException(SentryException exception) {
    if (_shouldFilterByStackFrames(exception)) {
      return true;
    }

    // Native signal crashes (SIGABRT, SIGSEGV, etc.) with no app code in the
    // stacktrace are OS/driver-level kills we can't act on (OOM, GPU driver,
    // ANR). Filter them to reduce noise from low-end devices.
    if (_isBarNativeSignalCrash(exception)) {
      return true;
    }

    final type = exception.type?.toLowerCase() ?? '';
    final value = exception.value?.toLowerCase() ?? '';
    final combined = '$type $value';

    // CanvasKit failures are Flutter runtime issues we can't fix
    if (value.contains('fluttercanvaskit') &&
        value.contains('is not a constructor')) {
      return true;
    }

    // Firebase Messaging on browsers missing IndexedDB / Push APIs (private
    // mode, older browsers) — user-side capability gap, not actionable.
    if (value.contains('messaging/unsupported-browser')) {
      return true;
    }

    if (type.contains('unauthorizedexception') ||
        type.contains('validationexception') ||
        type.contains('notfoundexception')) {
      return true;
    }

    // GoException-wrapped redirects can carry a 4xx without HTTP keywords.
    if (type.contains('goexception') &&
        _containsClientErrorStatusCode(combined)) {
      return true;
    }

    if (_containsClientErrorStatusCode(combined) && _looksLikeHttpError(combined)) {
      return true;
    }

    if (combined.contains('failed host lookup')) {
      return true;
    }

    if (_isDioConnectivityFailure(combined)) {
      return true;
    }

    // Expected when device goes offline in background
    if (_looksLikeNetworkError(combined) &&
        (combined.contains('/auth/token/refresh/') ||
            combined.contains('/auth/user/pushtoken/'))) {
      return true;
    }

    return false;
  }

  /// Filter exceptions originating entirely within known third-party packages
  bool _shouldFilterByStackFrames(SentryException exception) {
    final frames = exception.stackTrace?.frames ?? [];
    return frames.any((f) =>
        (f.absPath ?? f.module ?? '').toLowerCase().contains('syncfusion_flutter'));
  }

  /// Native signal crashes (e.g. SIGABRT, SIGSEGV) with only system-level
  /// frames and no app code are not actionable.
  bool _isBarNativeSignalCrash(SentryException exception) {
    final type = exception.type?.toUpperCase() ?? '';
    if (!type.startsWith('SIG')) {
      return false;
    }

    final frames = exception.stackTrace?.frames ?? [];
    if (frames.isEmpty) {
      return true;
    }

    return frames.every((f) {
      final path = (f.absPath ?? f.module ?? f.fileName ?? '').toLowerCase();
      return path.isEmpty ||
          path == '<unknown>' ||
          path.startsWith('libc.') ||
          path.startsWith('libc++') ||
          path.startsWith('libsystem_') ||
          path.startsWith('/system/') ||
          path.startsWith('/apex/') ||
          path.startsWith('/usr/lib/') ||
          path.startsWith('/system/library/');
    });
  }

  /// Text-based filtering as a fallback
  bool _shouldFilterByText(SentryEvent event) {
    final textParts = <String>[
      event.message?.formatted ?? '',
      if (event.exceptions != null)
        ...event.exceptions!.map((e) => '${e.type ?? ''} ${e.value ?? ''}'),
    ];
    final eventText = textParts.join(' ').toLowerCase();

    if (_containsClientErrorStatusCode(eventText) &&
        _looksLikeHttpError(eventText)) {
      return true;
    }

    return false;
  }

  /// Matches any HTTP 4xx (client error) status code in free text.
  static final _clientErrorStatusPattern = RegExp(r'\b4\d\d\b');

  bool _containsClientErrorStatusCode(String text) {
    return _clientErrorStatusPattern.hasMatch(text);
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

  /// Matched as text because AOT and dart2js minify the DioException type name.
  static final _dioConnectivityFailurePattern = RegExp(
    r'dioexception \[(connection timeout|send timeout|receive timeout|connection error)\]',
  );

  bool _isDioConnectivityFailure(String text) {
    return _dioConnectivityFailurePattern.hasMatch(text);
  }

  /// Check if text looks like a network/connection error
  bool _looksLikeNetworkError(String text) {
    return text.contains('connection abort') ||
        text.contains('connection timeout') ||
        text.contains('connection error') ||
        text.contains('send timeout') ||
        text.contains('receive timeout') ||
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
