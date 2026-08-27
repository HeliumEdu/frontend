import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/system_proxy_io.dart'
    if (dart.library.js_interop) 'package:heliumapp/core/system_proxy_stub.dart';
import 'package:heliumapp/core/retry_evaluator.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

final _log = Logger('core');

class DioClient {
  static DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late final Dio _dio;
  late final PrefService _prefService;
  late final CacheService _cacheService;

  @visibleForTesting
  DioClient.forTesting({
    required Dio dio,
    required PrefService prefService,
    CacheService? cacheService,
  }) : _dio = dio,
       _prefService = prefService,
       _cacheService = cacheService ?? CacheService();

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;
  String? _clientVersion;
  String? _clientPlatform;

  @visibleForTesting
  static void resetForTesting() {
    _instance = DioClient._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(DioClient instance) {
    _instance = instance;
  }

  @visibleForTesting
  bool isInvalidTokenError(dynamic data) => _isInvalidTokenError(data);

  @visibleForTesting
  void refreshReplayBody(RequestOptions options) => _refreshReplayBody(options);

  Dio get dio => _dio;

  CacheService get cacheService => _cacheService;

  DioClient._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiUrl.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 120),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
      _prefService = PrefService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _clientVersion ??= await _resolveClientVersion();
          if (_clientVersion != null) {
            options.headers['X-Client-Version'] = _clientVersion;
          }

          _clientPlatform ??= _resolveClientPlatform();
          options.headers['X-Client-Platform'] = _clientPlatform;

          HeliumRetryEvaluator.deadlineFor(options);

          final requestId = const Uuid().v4();
          options.headers['X-Request-ID'] = requestId;
          _addRequestBreadcrumb(requestId, options);

          final token = await _prefService.getSecure('access_token');
          if (token?.isNotEmpty ?? false) {
            options.headers['Authorization'] = 'Bearer $token';
            _log.fine('Authorization token attached to request');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final requestPath = error.requestOptions.path;

            // Don't refresh on login or refresh token endpoints
            if (requestPath == ApiUrl.authTokenUrl ||
                requestPath == ApiUrl.authTokenRefreshUrl) {
              return handler.next(error);
            }

            // If refresh is already in progress, wait for it to complete
            if (_isRefreshing && _refreshCompleter != null) {
              _log.info(
                'Token refresh in progress, waiting for completion ...',
              );
              unawaited(
                AnalyticsService().logEvent(
                  name: AnalyticsEvent.debugAuthTokenRefreshQueue,
                  parameters: {'category': AnalyticsCategory.operational.value},
                ),
              );
              try {
                await _refreshCompleter!.future;
                final newToken = await getAccessToken();
                if (newToken?.isNotEmpty ?? false) {
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  _refreshReplayBody(error.requestOptions);
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                } else {
                  await forceLogout();
                  return handler.next(error);
                }
              } catch (e) {
                await forceLogout();
                return handler.next(error);
              }
            }

            _log.info('Got 401 error, attempting to refresh token ...');
            _isRefreshing = true;
            _refreshCompleter = Completer<void>();
            // Absorb completeError when no request is awaiting, so it can't
            // escape as an unhandled error.
            unawaited(_refreshCompleter!.future.catchError((_) {}));

            try {
              final refreshToken = await getRefreshToken();

              if (refreshToken == null || refreshToken.isEmpty) {
                _log.info('No refresh token available, redirecting to login');
                _isRefreshing = false;
                // Use complete() instead of completeError() to avoid unhandled
                // exception when no other requests are waiting on the completer.
                // Waiting requests check for null token after completion.
                _refreshCompleter!.complete();
                _refreshCompleter = null;
                await forceLogout();
                return handler.next(error);
              }

              // Create a new Dio instance for refresh to avoid recursion
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: ApiUrl.baseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    if (_clientVersion != null) 'X-Client-Version': _clientVersion,
                    'X-Client-Platform':
                        _clientPlatform ??= _resolveClientPlatform(),
                  },
                  validateStatus: (status) => status != null && status < 500,
                ),
              );

              // Retries only when no response came back; see HeliumRetryEvaluator.
              refreshDio.interceptors.add(
                RetryInterceptor(
                  dio: refreshDio,
                  logPrint: (message) => _log.info(message),
                  retries: 3,
                  retryDelays: const [
                    Duration(seconds: 1),
                    Duration(seconds: 2),
                    Duration(seconds: 3),
                  ],
                  retryEvaluator: HeliumRetryEvaluator().evaluate,
                ),
              );

              final request = RefreshTokenRequestModel(refresh: refreshToken);
              final response = await refreshDio.post(
                ApiUrl.authTokenRefreshUrl,
                data: request.toJson(),
              );

              final refreshStatusCode = response.statusCode;
              if (refreshStatusCode == 401 || refreshStatusCode == 403) {
                _log.info(
                  'Got $refreshStatusCode during token refresh, session expired',
                );
                _isRefreshing = false;
                _refreshCompleter!.complete();
                _refreshCompleter = null;
                await forceLogout();
                return handler.next(error);
              }

              if (response.statusCode == 200) {
                final refreshResponse = TokenResponseModel.fromJson(
                  response.data,
                );

                await saveTokens(
                  refreshResponse.access,
                  refreshResponse.refresh,
                );
                _log.info('Token refreshed successfully');
                _isRefreshing = false;
                _refreshCompleter!.complete();
                _refreshCompleter = null;

                error.requestOptions.headers['Authorization'] =
                    'Bearer ${refreshResponse.access}';

                _refreshReplayBody(error.requestOptions);
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } else {
                _log.warning(
                  'Token refresh failed with status: ${response.statusCode}',
                );
                _isRefreshing = false;
                _refreshCompleter!.completeError('Token refresh failed');
                _refreshCompleter = null;

                if (_isInvalidTokenError(response.data)) {
                  _log.info(
                    'Refresh token is invalid/expired, clearing tokens',
                  );
                  await forceLogout();
                  return handler.next(error);
                }

                _log.warning(
                  'Token refresh failed but not due to invalid token, retrying request',
                );

                return handler.next(error);
              }
            } catch (e) {
              _isRefreshing = false;
              if (_refreshCompleter != null) {
                _refreshCompleter!.completeError(e);
                _refreshCompleter = null;
              }

              bool shouldLogout = false;
              if (e is DioException) {
                final statusCode = e.response?.statusCode;
                if (statusCode == 401 || statusCode == 403) {
                  _log.info(
                    'Got $statusCode during token refresh, session expired',
                  );
                  shouldLogout = true;
                } else if (_isInvalidTokenError(e.response?.data)) {
                  _log.info('Refresh token is invalid/expired');
                  shouldLogout = true;
                }
              }

              // Don't logout on network errors, only on invalid/expired token
              if (shouldLogout) {
                await forceLogout();
              } else {
                _log.severe('Unexpected error during token refresh', e);
              }
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Retry on transient server/infrastructure errors
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: (message) => _log.info(message),
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: HeliumRetryEvaluator().evaluate,
      ),
    );

    applySystemProxy(_dio);

    _cacheService = CacheService();
    _cacheService.onInactivityResume = () => fetchSettings();
    _cacheService.addQuickResumeListener(refreshSystemProxy);
    _dio.interceptors.add(_cacheService.interceptor);
    _dio.interceptors.add(_cacheService.loggingInterceptor);

    // Add Sentry tracing for HTTP performance monitoring
    _dio.addSentry();

    if (kDebugMode) {
      final logLevel = Logger.root.level;
      final isVerbose = logLevel <= Level.FINE;
      final isVeryVerbose = logLevel <= Level.FINER;

      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: isVerbose,
          requestBody: isVeryVerbose,
          responseHeader: isVerbose,
          responseBody: isVeryVerbose,
          compact: !isVeryVerbose,
        ),
      );
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _prefService.setSecure('access_token', accessToken);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _prefService.setSecure('refresh_token', refreshToken);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  Future<List<void>?> clearStorage() async {
    await _cacheService.clearAll();
    return _prefService.clear();
  }

  Future<String?> getAccessToken() async {
    return await _prefService.getSecure('access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _prefService.getSecure('refresh_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token?.isNotEmpty ?? false;
  }

  Future<UserSettingsModel?> fetchSettings({bool forceRefresh = false}) async {
    try {
      _log.info('Fetching settings from API ...');
      final response = await _dio.get(
        ApiUrl.authUserUrl,
        options: forceRefresh ? _cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);

        await saveSettings(user.settings);

        unawaited(AnalyticsService().setStaffStatus(user.email));

        return user.settings;
      } else {
        _log.severe(
          'Failed to fetch settings from API: ${response.statusCode}',
        );
        return null;
      }
    } catch (apiError) {
      _log.severe('Error fetching settings from API: ${apiError.runtimeType}');

      return null;
    }
  }

  Future<UserSettingsModel?> getSettings() async {
    await _prefService.init();

    try {
      final p = _prefService;
      final cachedJson = <String, dynamic>{
        SettingsPrefKey.timeZone.key: p.getString(SettingsPrefKey.timeZone.key),
        SettingsPrefKey.colorByCategory.key: p.getBool(SettingsPrefKey.colorByCategory.key),
        SettingsPrefKey.defaultView.key: p.getInt(SettingsPrefKey.defaultView.key),
        SettingsPrefKey.colorSchemeTheme.key: p.getInt(SettingsPrefKey.colorSchemeTheme.key),
        SettingsPrefKey.weekStartsOn.key: p.getInt(SettingsPrefKey.weekStartsOn.key),
        SettingsPrefKey.whatsNewVersionSeen.key: p.getInt(SettingsPrefKey.whatsNewVersionSeen.key),
        SettingsPrefKey.showGettingStarted.key: p.getBool(SettingsPrefKey.showGettingStarted.key),
        SettingsPrefKey.eventsColor.key: p.getString(SettingsPrefKey.eventsColor.key),
        SettingsPrefKey.resourceColor.key: p.getString(SettingsPrefKey.resourceColor.key),
        SettingsPrefKey.gradeColor.key: p.getString(SettingsPrefKey.gradeColor.key),
        SettingsPrefKey.defaultReminderType.key: p.getInt(SettingsPrefKey.defaultReminderType.key),
        SettingsPrefKey.defaultReminderOffset.key: p.getInt(SettingsPrefKey.defaultReminderOffset.key),
        SettingsPrefKey.defaultReminderOffsetType.key: p.getInt(SettingsPrefKey.defaultReminderOffsetType.key),
        SettingsPrefKey.calendarUseCategoryColors.key: p.getBool(SettingsPrefKey.calendarUseCategoryColors.key),
        SettingsPrefKey.showPlannerTooltips.key: p.getBool(SettingsPrefKey.showPlannerTooltips.key),
        SettingsPrefKey.rememberFilterState.key: p.getBool(SettingsPrefKey.rememberFilterState.key),
        SettingsPrefKey.dragAndDropOnMobile.key: p.getBool(SettingsPrefKey.dragAndDropOnMobile.key),
        SettingsPrefKey.isSetupComplete.key: p.getBool(SettingsPrefKey.isSetupComplete.key),
        SettingsPrefKey.calendarEventLimit.key: p.getBool(SettingsPrefKey.calendarEventLimit.key),
        SettingsPrefKey.atRiskThreshold.key: p.getInt(SettingsPrefKey.atRiskThreshold.key),
        SettingsPrefKey.onTrackTolerance.key: p.getInt(SettingsPrefKey.onTrackTolerance.key),
        SettingsPrefKey.showWeekNumbers.key: p.getBool(SettingsPrefKey.showWeekNumbers.key),
      };

      if (cachedJson.values.any((v) => v == null)) {
        _log.info('Fetching settings from API ...');
        final fetchedSettings = await fetchSettings();
        if (fetchedSettings != null) {
          return fetchedSettings;
        }
        _log.warning('Failed to fetch settings from API');
        return null;
      }

      return UserSettingsModel.fromJson(cachedJson);
    } catch (parseError) {
      _log.info('Failed to parse cached settings: $parseError');
      return await fetchSettings();
    }
  }

  Future<void> clearSettings() =>
      _prefService.removeKeys(SettingsPrefKey.allKeys);

  Future<List<void>> saveSettings(UserSettingsModel settings) async {
    final themeMode = switch (settings.colorSchemeTheme) {
      0 => ThemeMode.light,
      1 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    await ThemeNotifier().setThemeMode(themeMode);

    final p = _prefService;
    final result = await Future.wait([
      ?p.setString(SettingsPrefKey.timeZone.key, settings.timeZone.toString()),
      ?p.setBool(SettingsPrefKey.colorByCategory.key, settings.colorByCategory),
      ?p.setInt(SettingsPrefKey.defaultView.key, settings.defaultView),
      ?p.setInt(SettingsPrefKey.colorSchemeTheme.key, settings.colorSchemeTheme),
      ?p.setInt(SettingsPrefKey.weekStartsOn.key, settings.weekStartsOn),
      ?p.setString(SettingsPrefKey.eventsColor.key, HeliumColors.colorToHex(settings.eventsColor)),
      ?p.setString(SettingsPrefKey.resourceColor.key, HeliumColors.colorToHex(settings.resourceColor)),
      ?p.setString(SettingsPrefKey.gradeColor.key, HeliumColors.colorToHex(settings.gradeColor)),
      ?p.setInt(SettingsPrefKey.defaultReminderType.key, settings.defaultReminderType),
      ?p.setInt(SettingsPrefKey.defaultReminderOffset.key, settings.defaultReminderOffset),
      ?p.setInt(SettingsPrefKey.defaultReminderOffsetType.key, settings.defaultReminderOffsetType),
      ?p.setBool(SettingsPrefKey.calendarUseCategoryColors.key, settings.colorByCategory),
      ?p.setBool(SettingsPrefKey.showPlannerTooltips.key, settings.showPlannerTooltips),
      ?p.setInt(SettingsPrefKey.whatsNewVersionSeen.key, settings.whatsNewVersionSeen),
      ?p.setBool(SettingsPrefKey.showGettingStarted.key, settings.showGettingStarted),
      ?p.setBool(SettingsPrefKey.rememberFilterState.key, settings.rememberFilterState),
      ?p.setBool(SettingsPrefKey.dragAndDropOnMobile.key, settings.dragAndDropOnMobile),
      ?p.setBool(SettingsPrefKey.isSetupComplete.key, settings.isSetupComplete),
      ?p.setInt(SettingsPrefKey.atRiskThreshold.key, settings.atRiskThreshold),
      ?p.setInt(SettingsPrefKey.onTrackTolerance.key, settings.onTrackTolerance),
      ?p.setBool(SettingsPrefKey.showWeekNumbers.key, settings.showWeekNumbers),
    ]);

    if (p.getString('saved_grades_graph_settings') == null) {
      final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
      final isMobile = view != null &&
          Responsive.isMobileWidth(
            view.physicalSize.width / view.devicePixelRatio,
          );
      await p.setString(
        'saved_grades_graph_settings',
        jsonEncode({
          'autoAdjustToGradedRange': isMobile,
          'hideLegend': false,
        }),
      );
    }

    return result;
  }

  Future<void> updateSettings(UpdateSettingsRequestModel request) async {
    try {
      final response = await _dio.put(
        ApiUrl.authUserSettingsUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final settings = UserSettingsModel.fromJson(response.data);
        await saveSettings(settings);
      }
    } catch (e) {
      _log.severe('Failed to update settings', e);
      rethrow;
    }
  }

  Future<void> acknowledgeReviewPrompt() async {
    await _dio.post(ApiUrl.authUserSettingsReviewPromptAckUrl);
  }

  Future<String?> _resolveClientVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (e) {
      _log.warning('Failed to resolve client version', e);
      return null;
    }
  }

  String _resolveClientPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// A [FormData] body is consumed when the request is sent, so replaying the
  /// original [RequestOptions] after a token refresh would finalize it twice.
  /// Cloning preserves the boundary, so the already-set content-type still matches.
  void _refreshReplayBody(RequestOptions options) {
    final data = options.data;
    if (data is FormData && data.isFinalized) {
      options.data = data.clone();
    }
  }

  void _addRequestBreadcrumb(String requestId, RequestOptions options) {
    if (!SentryService().isEnabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: '${options.method} ${options.path}',
        category: 'http.request',
        type: 'http',
        level: SentryLevel.info,
        data: {'request_id': requestId},
      ),
    );
  }

  bool _isInvalidTokenError(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];
      if (detail != null) {
        final detailStr = detail.toString().toLowerCase();
        return detail == 'Token is blacklisted' ||
            detailStr.contains('invalid') ||
            detailStr.contains('expired');
      }
    }
    return false;
  }

  Future<void> forceLogout([
    String message = 'Please sign in to continue.',
  ]) async {
    try {
      await clearStorage();
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        SnackBarHelper.show(
          context,
          message,
          seconds: 4,
          type: SnackType.error,
        );

        router.go(AppRoute.signinScreen);
      }
    } catch (_) {
      // Ignore navigation errors
    }
  }
}
