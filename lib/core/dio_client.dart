import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helium_mobile/config/app_routes.dart';
import 'package:helium_mobile/core/network_urls.dart';
import 'package:helium_mobile/data/models/auth/refresh_token_request_model.dart';
import 'package:helium_mobile/data/models/auth/refresh_token_response_model.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/main.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio _dio;
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: NetworkUrl.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token if available
          final prefs = await SharedPreferencesWithCache.create(
            cacheOptions: const SharedPreferencesWithCacheOptions(),
          );
          final token = prefs.getString('access_token');
          if (token != null && token.isNotEmpty) {
            // HeliumEdu API uses Bearer authentication, not Token
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Token added to request: ${token.substring(0, 10)}...');
          } else {
            print('⚠️ No token found in SharedPreferences');
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
            if (requestPath == NetworkUrl.signInUrl ||
                requestPath == NetworkUrl.refreshTokenUrl) {
              return handler.next(error);
            }

            // If refresh is already in progress, wait for it to complete
            if (_isRefreshing && _refreshCompleter != null) {
              print('⏳ Token refresh in progress, waiting for completion...');
              try {
                await _refreshCompleter!.future;
                // After refresh completes, retry the original request
                final newToken = await getAccessToken();
                if (newToken != null && newToken.isNotEmpty) {
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                } else {
                  // Refresh completed but no token available, logout
                  await _handleForceLogout(
                    'Session expired. Please login again.',
                  );
                  return handler.next(error);
                }
              } catch (e) {
                // Refresh failed, logout
                await _handleForceLogout(
                  'Session expired. Please login again.',
                );
                return handler.next(error);
              }
            }

            // Start token refresh process
            print('🔄 Got 401 error, attempting to refresh token...');
            _isRefreshing = true;
            _refreshCompleter = Completer<void>();

            try {
              final refreshToken = await getRefreshToken();

              if (refreshToken == null || refreshToken.isEmpty) {
                print('❌ No refresh token available');
                _isRefreshing = false;
                _refreshCompleter!.completeError('No refresh token');
                _refreshCompleter = null;
                await _handleForceLogout(
                  'Session expired. Please login again.',
                );
                return handler.next(error);
              }

              // Create a new Dio instance for refresh to avoid recursion
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: NetworkUrl.baseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              final request = RefreshTokenRequestModel(refresh: refreshToken);
              final response = await refreshDio.post(
                NetworkUrl.refreshTokenUrl,
                data: request.toJson(),
              );

              if (response.statusCode == 200 || response.statusCode == 201) {
                final refreshResponse = RefreshTokenResponseModel.fromJson(
                  response.data,
                );

                // Save BOTH new access token AND new refresh token
                await saveTokens(
                  refreshResponse.access,
                  refreshResponse.refresh,
                );
                print('✅ Tokens refreshed successfully (access + refresh)');

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
                print(
                  '❌ Token refresh failed with status: ${response.statusCode}',
                );
                _isRefreshing = false;
                _refreshCompleter!.completeError('Token refresh failed');
                _refreshCompleter = null;

                // Check if the error is due to blacklisted or invalid refresh token
                final responseData = response.data;
                if (responseData is Map<String, dynamic>) {
                  final detail = responseData['detail'];
                  if (detail == 'Token is blacklisted' ||
                      detail.toString().toLowerCase().contains('invalid') ||
                      detail.toString().toLowerCase().contains('expired')) {
                    print(
                      '🚫 Refresh token is invalid/expired, clearing tokens',
                    );
                    await clearTokens();
                    await _handleForceLogout(
                      'Session expired. Please login again.',
                    );
                    return handler.next(error);
                  }
                }

                // If it's not a token issue, don't logout - just retry might work
                print(
                  '⚠️ Token refresh failed but not due to invalid token, retrying request',
                );
                return handler.next(error);
              }
            } catch (e) {
              print('❌ Error during token refresh: $e');
              _isRefreshing = false;
              if (_refreshCompleter != null) {
                _refreshCompleter!.completeError(e);
                _refreshCompleter = null;
              }

              // Check if the error is due to blacklisted/invalid refresh token
              bool shouldLogout = false;
              if (e is DioException && e.response?.data != null) {
                final responseData = e.response!.data;
                if (responseData is Map<String, dynamic>) {
                  final detail = responseData['detail'];
                  if (detail == 'Token is blacklisted' ||
                      detail.toString().toLowerCase().contains('invalid') ||
                      detail.toString().toLowerCase().contains('expired')) {
                    print('🚫 Refresh token is invalid/expired');
                    shouldLogout = true;
                    await clearTokens();
                  }
                }
              }

              // Only logout if refresh token is actually invalid/expired
              // Don't logout on network errors or other transient issues
              if (shouldLogout) {
                await _handleForceLogout(
                  'Session expired. Please login again.',
                );
              } else {
                print(
                  '⚠️ Refresh failed due to network/transient error, not logging out',
                );
              }
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;

  // Save access token
  Future<void> saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    await prefs.setString('access_token', accessToken);
    print('✅ Token saved: ${accessToken.substring(0, 10)}...');
  }

  // Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    await prefs.setString('refresh_token', refreshToken);
    print('✅ Refresh token saved: ${refreshToken.substring(0, 10)}...');
  }

  // Save tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  // Clear token
  Future<void> clearTokens() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return prefs.getString('access_token');
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return prefs.getString('refresh_token');
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all authentication data
  Future<void> clearAllAuth() async {
    await clearTokens();
    print('🧹 Authentication data cleared');
  }

  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return UserSettings.fromJson({
      'time_zone': prefs.get('time_zone'),
      'default_view': prefs.getInt('default_view'),
      'week_starts_on': prefs.getInt('week_starts_on'),
      'all_day_offset': prefs.getInt('all_day_offset'),
      'events_color': prefs.get('events_color'),
      'materials_color': prefs.get('materials_color'),
      'grades_color': prefs.get('grades_color'),
      'default_reminder_offset': prefs.getInt('default_reminder_offset'),
      'default_reminder_offset_type': prefs.getInt(
        'default_reminder_offset_type',
      ),
    });
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    await prefs.setString('time_zone', settings.timeZone);
    await prefs.setInt('default_view', settings.defaultView);
    await prefs.setInt('week_starts_on', settings.weekStartsOn);
    await prefs.setInt('all_day_offset', settings.allDayOffset);
    await prefs.setString('events_color', settings.eventsColor);
    await prefs.setString('materials_color', settings.materialsColor);
    await prefs.setString('grades_color', settings.gradesColor);
    await prefs.setInt(
      'default_reminder_offset',
      settings.defaultReminderOffset,
    );
    await prefs.setInt(
      'default_reminder_offset_type',
      settings.defaultReminderOffsetType,
    );
  }

  Future<void> _handleForceLogout(String message) async {
    try {
      await clearAllAuth();
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Show a brief snackbar if possible
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: redColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate to login, clearing the stack
        await Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.signInScreen, (route) => false);
      }
    } catch (_) {
      // Ignore navigation errors
    }
  }
}
