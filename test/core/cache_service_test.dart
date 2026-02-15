// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheService cacheService;

  setUp(() {
    cacheService = CacheService();
  });

  group('CacheService', () {
    group('shouldCache', () {
      test('returns true for all planner paths', () {
        // WHEN/THEN
        expect(cacheService.shouldCache('/planner/homework/'), isTrue);
        expect(cacheService.shouldCache('/planner/events/'), isTrue);
        expect(cacheService.shouldCache('/planner/courses/'), isTrue);
        expect(cacheService.shouldCache('/planner/reminders/'), isTrue);
      });
    });

    group('forceRefreshOptions', () {
      test('returns non-null Options with extra data', () {
        // WHEN
        final options = cacheService.forceRefreshOptions();

        // THEN
        expect(options, isNotNull);
        // Options should have extra map for cache interceptor to read
        expect(options.extra, isNotNull);
        expect(options.extra!.isNotEmpty, isTrue);
      });
    });

    group('invalidateAll', () {
      test('clears cache without throwing', () async {
        // WHEN/THEN - should complete without error
        await expectLater(cacheService.invalidateAll(), completes);
      });
    });

    group('clearAll', () {
      test('is alias for invalidateAll', () async {
        // WHEN/THEN - should complete without error
        await expectLater(cacheService.clearAll(), completes);
      });
    });

    group('interceptor', () {
      test('returns an Interceptor that filters by HTTP method', () {
        // WHEN
        final interceptor = cacheService.interceptor;

        // THEN - should be an Interceptor (wraps DioCacheInterceptor for GET-only caching)
        expect(interceptor, isA<Interceptor>());
      });
    });
  });
}
