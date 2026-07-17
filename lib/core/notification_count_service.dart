// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.notification_count');

/// Tracks the count of active (sent, undismissed push) reminders for the
/// notification-bell badge. Held as a singleton with a [ValueNotifier] so the
/// header bell can react to it and out-of-tree callers (FCM pushes, the dismiss
/// flow) can adjust it without a network round trip.
///
/// The authoritative value is fetched sparingly ([refresh]); between fetches
/// the count is nudged locally ([increment]/[decrement]) and reconciled on the
/// next refresh (notification screen open, app resume).
class NotificationCountService {
  final ValueNotifier<int> count = ValueNotifier<int>(0);

  final ReminderRepository _reminderRepository;

  static NotificationCountService _instance =
      NotificationCountService._internal();

  factory NotificationCountService() => _instance;

  NotificationCountService._internal()
    : _reminderRepository = ReminderRepositoryImpl(
        remoteDataSource: ReminderRemoteDataSourceImpl(dioClient: DioClient()),
      );

  @visibleForTesting
  NotificationCountService.forTesting({
    required ReminderRepository reminderRepository,
  }) : _reminderRepository = reminderRepository;

  @visibleForTesting
  static void resetForTesting() {
    _instance = NotificationCountService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(NotificationCountService instance) {
    _instance = instance;
  }

  Future<void> refresh() async {
    try {
      count.value = await _reminderRepository.getRemindersCount(
        sent: true,
        dismissed: false,
        type: 3,
        startOfRange: DateTime.now(),
      );
    } catch (e, s) {
      _log.warning('Failed to refresh notification count', e, s);
    }
  }

  void increment() => count.value = count.value + 1;

  void decrement() {
    if (count.value > 0) count.value = count.value - 1;
  }

  void reset() => count.value = 0;
}
