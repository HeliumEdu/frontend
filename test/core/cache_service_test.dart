// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

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
