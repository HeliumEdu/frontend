// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/notification_count_service.dart';
import 'package:heliumapp/data/models/notification/notification_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';

import '../mocks/mock_repositories.dart';

NotificationModel _notification(int id) => NotificationModel(
  id: id,
  title: 'Reminder $id',
  body: 'body',
  timestamp: '2025-01-15T10:00:00Z',
  reminder: ReminderModel(
    id: id,
    title: 'Reminder $id',
    message: 'body',
    startOfRange: DateTime.parse('2025-01-15T10:00:00Z'),
    type: 3,
    offset: 30,
    offsetType: 0,
    sent: true,
    dismissed: false,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationCountService service;

  setUp(() {
    service = NotificationCountService.forTesting(
      reminderRepository: MockReminderRepository(),
    );
    NotificationCountService.setInstanceForTesting(service);
  });

  group('notification list cache', () {
    test('returns the cached list when the count is unchanged', () {
      final list = [_notification(1), _notification(2)];
      service.count.value = 2;
      service.cacheNotifications(list);

      final cached = service.cachedNotifications;
      expect(cached, isNotNull);
      expect(cached!.map((n) => n.id), [1, 2]);
    });

    test('returns null when a push arrived while the screen was closed', () {
      service.count.value = 2;
      service.cacheNotifications([_notification(1), _notification(2)]);

      service.increment();

      expect(service.cachedNotifications, isNull);
    });

    test('returns null after a net-zero membership change (push + dismiss)', () {
      // A push (+1) and a cross-device dismiss (-1) net to the same count, but
      // the membership changed — the cache must still miss so the screen refetches.
      service.count.value = 2;
      service.cacheNotifications([_notification(1), _notification(2)]);

      service.increment();
      service.decrement();

      expect(service.count.value, 2);
      expect(service.cachedNotifications, isNull);
    });

    test('returns null after invalidation', () {
      service.count.value = 1;
      service.cacheNotifications([_notification(1)]);

      service.invalidateCachedNotifications();

      expect(service.cachedNotifications, isNull);
    });

    test('reset clears the cache', () {
      service.count.value = 1;
      service.cacheNotifications([_notification(1)]);

      service.reset();

      expect(service.cachedNotifications, isNull);
    });

    test('hands back a copy so the screen mutating its list cannot corrupt the cache', () {
      service.count.value = 2;
      service.cacheNotifications([_notification(1), _notification(2)]);

      service.cachedNotifications!.clear(); // mimic in-place mutation by the screen

      // The next read still sees the original cached list.
      expect(service.cachedNotifications!.length, 2);
    });
  });
}
