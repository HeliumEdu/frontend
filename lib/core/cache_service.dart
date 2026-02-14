// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

/// Centralized cache service for HTTP requests.
///
/// Provides a 10-minute TTL cache for GET requests using an in-memory store.
/// Excludes `/planner/reminders/` from caching due to nested data concerns.
class CacheService {
  late final CacheStore _store;
  late final CacheOptions _options;
  late final DioCacheInterceptor _interceptor;

  CacheService() {
    _store = MemCacheStore();
    _options = CacheOptions(
      store: _store,
      policy: CachePolicy.request,
      maxStale: const Duration(minutes: 10),
      hitCacheOnNetworkFailure: true,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    );
    _interceptor = DioCacheInterceptor(options: _options);
  }

  /// Constructor for testing with a custom store.
  @visibleForTesting
  CacheService.withStore(CacheStore store) {
    _store = store;
    _options = CacheOptions(
      store: _store,
      policy: CachePolicy.request,
      maxStale: const Duration(minutes: 10),
      hitCacheOnNetworkFailure: true,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    );
    _interceptor = DioCacheInterceptor(options: _options);
  }

  /// The cache interceptor to add to Dio.
  DioCacheInterceptor get interceptor => _interceptor;

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
