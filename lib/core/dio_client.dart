// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:logging/logging.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  // Getters
  Dio get dio => _dio;

  CacheService get cacheService => _cacheService;

  DioClient._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiUrl.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
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
          // Handle 401 errors by attempting to refresh token
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
              try {
                await _refreshCompleter!.future;
                // After refresh completes, retry the original request
                final newToken = await getAccessToken();
                if (newToken?.isNotEmpty ?? false) {
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                } else {
                  // Refresh completed but no token available, logout
                  await _forceLogout('Please login to continue.');
                  return handler.next(error);
                }
              } catch (e) {
                // Refresh failed, logout
                await _forceLogout('Please login to continue.');
                return handler.next(error);
              }
            }

            // Start token refresh process
            _log.info('Got 401 error, attempting to refresh token ...');
            _isRefreshing = true;
            _refreshCompleter = Completer<void>();

            try {
              final refreshToken = await getRefreshToken();

              if (refreshToken == null || refreshToken.isEmpty) {
                _log.warning('No refresh token available');
                _isRefreshing = false;
                _refreshCompleter!.completeError('No refresh token');
                _refreshCompleter = null;
                await _forceLogout('Please login to continue.');
                return handler.next(error);
              }

              // Create a new Dio instance for refresh to avoid recursion
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: ApiUrl.baseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              final request = RefreshTokenRequestModel(refresh: refreshToken);
              final response = await refreshDio.post(
                ApiUrl.authTokenRefreshUrl,
                data: request.toJson(),
              );

              if (response.statusCode == 200) {
                final refreshResponse = TokenResponseModel.fromJson(
                  response.data,
                );

                await saveTokens(
                  refreshResponse.access,
                  refreshResponse.refresh,
                );
                _log.info('Token refreshed successfully');

                // Complete the refresh completer to unblock queued requests
                _isRefreshing = false;
                _refreshCompleter!.complete();
                _refreshCompleter = null;

                // Retry the original request with new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer ${refreshResponse.access}';

                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } else {
                _log.warning(
                  'Token refresh failed with status: ${response.statusCode}',
                );
                _isRefreshing = false;
                _refreshCompleter!.completeError('Token refresh failed');
                _refreshCompleter = null;

                // Check if the error is due to blacklisted/invalid refresh token
                if (_isInvalidTokenError(response.data)) {
                  _log.info(
                    'Refresh token is invalid/expired, clearing tokens',
                  );
                  await _forceLogout('Please login to continue.');
                  return handler.next(error);
                }

                _log.warning(
                  'Token refresh failed but not due to invalid token, retrying request',
                );

                return handler.next(error);
              }
            } catch (e) {
              _log.severe('Error during token refresh', e);
              _isRefreshing = false;
              if (_refreshCompleter != null) {
                _refreshCompleter!.completeError(e);
                _refreshCompleter = null;
              }

              // Check if the error is due to blacklisted/invalid refresh token
              // or if the user/account no longer exists
              bool shouldLogout = false;
              if (e is DioException) {
                if (e.response?.statusCode == 403) {
                  _log.info(
                    'Got 403 during token refresh, account may not exist',
                  );
                  shouldLogout = true;
                } else if (_isInvalidTokenError(e.response?.data)) {
                  _log.info('Refresh token is invalid/expired');
                  shouldLogout = true;
                }
              }

              // Only logout if refresh token is actually invalid/expired
              // or account doesn't exist. Don't logout on network errors.
              if (shouldLogout) {
                await _forceLogout('Please login to continue.');
              } else {
                _log.warning(
                  'Refresh failed due to network/transient error, not logging out',
                );
              }
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Add cache interceptor
    _cacheService = CacheService();
    _dio.interceptors.add(_cacheService.interceptor);
    _dio.interceptors.add(_cacheService.loggingInterceptor);

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
      _log.info('Fetching settings from API...');
      final response = await _dio.get(
        ApiUrl.authUserUrl,
        options: forceRefresh ? _cacheService.forceRefreshOptions() : null,
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);

        await saveSettings(user.settings);

        return user.settings;
      } else {
        _log.severe(
          'Failed to fetch settings from API: ${response.statusCode}',
        );
        return null;
      }
    } catch (apiError) {
      _log.severe('Error fetching settings from API: $apiError', apiError);

      return null;
    }
  }

  Future<UserSettingsModel?> getSettings() async {
    // Ensure PrefService is initialized
    await _prefService.init();

    try {
      // Check for critical field to detect race conditions
      final timeZone = _prefService.getString('time_zone');
      if (timeZone == null) {
        const msg =
            'Race condition detected: time_zone is null in getSettings(), _prefService may not be fully populated';
        _log.severe(msg);
        await Sentry.captureException(
          Exception(msg),
          stackTrace: StackTrace.current,
        );
      }

      return UserSettingsModel.fromJson({
        'time_zone': timeZone ?? FallbackConstants.defaultTimeZone,
        'color_by_category':
            _prefService.getBool('color_by_category') ??
            FallbackConstants.defaultColorByCategory,
        'default_view':
            _prefService.getInt('default_view') ??
            FallbackConstants.defaultViewIndex,
        'color_scheme_theme':
            _prefService.getInt('color_scheme_theme') ??
            FallbackConstants.defaultColorSchemeTheme,
        'week_starts_on':
            _prefService.getInt('week_starts_on') ??
            FallbackConstants.defaultWeekStartsOn,
        'all_day_offset':
            _prefService.getInt('all_day_offset') ??
            FallbackConstants.defaultAllDayOffset,
        'whats_new_version_seen':
            _prefService.getInt('whats_new_version_seen') ??
            FallbackConstants.defaultWhatsNewVersionSeen,
        'show_getting_started':
            _prefService.getBool('show_getting_started') ??
            FallbackConstants.defaultShowGettingStarted,
        'events_color':
            _prefService.getString('events_color') ??
            FallbackConstants.defaultEventsColor,
        'material_color':
            _prefService.getString('resource_color') ??
            FallbackConstants.defaultResourceColor,
        'grade_color':
            _prefService.getString('grade_color') ??
            FallbackConstants.defaultGradeColor,
        'default_reminder_type':
            _prefService.getInt('default_reminder_type') ??
            FallbackConstants.defaultReminderType,
        'default_reminder_offset':
            _prefService.getInt('default_reminder_offset') ??
            FallbackConstants.defaultReminderOffset,
        'default_reminder_offset_type':
            _prefService.getInt('default_reminder_offset_type') ??
            FallbackConstants.defaultReminderOffsetType,
        'calendar_use_category_colors':
            _prefService.getBool('calendar_use_category_colors') ??
            FallbackConstants.defaultCalendarUseCategoryColors,
        'remember_filter_state':
            _prefService.getBool('remember_filter_state') ??
            FallbackConstants.defaultRememberFilterState,
      });
    } catch (parseError) {
      _log.info('Failed to parse cached settings: $parseError');
      return await fetchSettings();
    }
  }

  Future<List<void>> saveSettings(UserSettingsModel settings) async {
    // Sync ThemeNotifier with backend value
    final themeMode = switch (settings.colorSchemeTheme) {
      0 => ThemeMode.light,
      1 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    await ThemeNotifier().setThemeMode(themeMode);

    return Future.wait([
      ?_prefService.setString('time_zone', settings.timeZone.toString()),
      ?_prefService.setBool('color_by_category', settings.colorByCategory),
      ?_prefService.setInt('default_view', settings.defaultView),
      ?_prefService.setInt('color_scheme_theme', settings.colorSchemeTheme),
      ?_prefService.setInt('week_starts_on', settings.weekStartsOn),
      ?_prefService.setInt('all_day_offset', settings.allDayOffset),
      ?_prefService.setString(
        'events_color',
        HeliumColors.colorToHex(settings.eventsColor),
      ),
      ?_prefService.setString(
        'resource_color',
        HeliumColors.colorToHex(settings.resourceColor),
      ),
      ?_prefService.setString(
        'grade_color',
        HeliumColors.colorToHex(settings.gradeColor),
      ),
      ?_prefService.setInt(
        'default_reminder_type',
        settings.defaultReminderType,
      ),
      ?_prefService.setInt(
        'default_reminder_offset',
        settings.defaultReminderOffset,
      ),
      ?_prefService.setInt(
        'default_reminder_offset_type',
        settings.defaultReminderOffsetType,
      ),
      ?_prefService.setBool(
        'calendar_use_category_colors',
        settings.colorByCategory,
      ),
      ?_prefService.setInt(
        'whats_new_version_seen',
        settings.whatsNewVersionSeen,
      ),
      ?_prefService.setBool(
        'show_getting_started',
        settings.showGettingStarted,
      ),
      ?_prefService.setBool(
        'remember_filter_state',
        settings.rememberFilterState,
      ),
      ?_prefService.setBool('is_setup_complete', settings.isSetupComplete),
    ]);
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

  Future<void> _forceLogout(String message) async {
    try {
      await clearStorage();
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText(
              message,
              style: AppStyles.standardBodyText(
                context,
              ).copyWith(color: context.colorScheme.onPrimary),
            ),
            backgroundColor: context.colorScheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );

        router.go(AppRoute.loginScreen);
      }
    } catch (_) {
      // Ignore navigation errors
    }
  }
}
