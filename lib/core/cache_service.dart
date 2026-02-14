// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

/// Centralized cache service for HTTP requests.
///
/// Provides a 30-minute TTL cache for GET requests using an in-memory store.
/// Automatically invalidates cache when returning from background after 5+ minutes.
class CacheService with WidgetsBindingObserver {
  late final CacheStore _store;
  late final CacheOptions _options;
  late final DioCacheInterceptor _interceptor;
  late final Interceptor _loggingInterceptor;

  /// How long cached responses remain valid.
  static const cacheTtl = Duration(minutes: 30);

  /// If app is backgrounded longer than this, cache is invalidated on resume.
  static const inactivityThreshold = Duration(minutes: 5);

  DateTime? _pausedAt;

  CacheService() {
    _store = MemCacheStore();
    _options = CacheOptions(
      store: _store,
      policy: CachePolicy.forceCache,
      maxStale: cacheTtl,
      hitCacheOnNetworkFailure: true,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    );
    _interceptor = DioCacheInterceptor(options: _options);
    _loggingInterceptor = _createLoggingInterceptor();
    _initLifecycleObserver();
  }

  /// Constructor for testing with a custom store.
  @visibleForTesting
  CacheService.withStore(CacheStore store) {
    _store = store;
    _options = CacheOptions(
      store: _store,
      policy: CachePolicy.forceCache,
      maxStale: cacheTtl,
      hitCacheOnNetworkFailure: true,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    );
    _interceptor = DioCacheInterceptor(options: _options);
    _loggingInterceptor = _createLoggingInterceptor();
    // Skip lifecycle observer in tests
  }

  void _initLifecycleObserver() {
    // Use addPostFrameCallback to ensure WidgetsBinding is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addObserver(this);
    });
  }

  /// Call this when the service is no longer needed.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _log.fine('App paused, recording timestamp for cache invalidation check');
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final inactiveDuration = DateTime.now().difference(_pausedAt!);
      if (inactiveDuration > inactivityThreshold) {
        _log.info(
          'App resumed after ${inactiveDuration.inMinutes} minutes, invalidating cache',
        );
        invalidateAll();
      }
      _pausedAt = null;
    }
  }

  /// The cache interceptor to add to Dio.
  DioCacheInterceptor get interceptor => _interceptor;

  /// Logging interceptor to add after the cache interceptor.
  /// Logs whether responses came from cache or network.
  Interceptor get loggingInterceptor => _loggingInterceptor;

  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        final fromNetwork = response.extra['@fromNetwork@'];
        final cacheKey = response.extra['@cache_key@'];
        final path = response.requestOptions.path;
        if (cacheKey != null && fromNetwork == false) {
          _log.info('CACHED RESPONSE: $path');
        }
        handler.next(response);
      },
    );
  }

  /// Returns cache options configured for the given request.
  /// Returns options with noCache policy for excluded paths.
  CacheOptions optionsForRequest(RequestOptions request) {
    if (!shouldCache(request.path)) {
      return _options.copyWith(policy: CachePolicy.noCache);
    }
    return _options;
  }

  /// Determines if a path should be cached.
  /// Returns false for paths that should be excluded from caching.
  @visibleForTesting
  bool shouldCache(String path) {
    // All paths are cached; full invalidation on any mutation ensures correctness
    return true;
  }

  /// Returns options that force a refresh from the network.
  /// Use this for pull-to-refresh functionality.
  Options forceRefreshOptions() {
    return _options.copyWith(policy: CachePolicy.refresh).toOptions();
  }

  /// Clears all cached responses.
  /// Call this after any mutation (create/update/delete) to ensure
  /// subsequent GET requests fetch fresh data.
  Future<void> invalidateAll() async {
    _log.info('Invalidating all cached responses');
    await _store.clean();
  }

  /// Clears all cached responses synchronously accessible method.
  /// Alias for invalidateAll() for API consistency with DioClient.clearStorage().
  Future<void> clearAll() => invalidateAll();
}
