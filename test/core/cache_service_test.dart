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

  });
}
