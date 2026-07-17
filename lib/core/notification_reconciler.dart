// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io'
    if (dart.library.html) 'package:heliumapp/core/platform_stub.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.notification_reconciler');

/// Clears stale iOS notifications on app resume — the fallback for when a
/// cross-device dismiss push never reached this device (Apple throttles silent
/// pushes, drops them offline, and won't wake a force-quit app). Android and web
/// receive that push reliably, so they need no resume reconciliation.
///
/// The reconciliation is deliberately POSITIVE-CONFIRMATION: it reads the
/// reminder ids actually sitting in the tray, asks the server which of those
/// specific reminders are now dismissed, and removes only the confirmed ones.
/// A failed/empty fetch clears nothing — it never over-clears by treating "not
/// in the active set" as stale.
class NotificationReconciler {
  static const _nativeChannel = MethodChannel('com.heliumedu.heliumapp/native');
  static final RegExp _reminderIdentifier = RegExp(r'^reminder_(\d+)$');

  final ReminderRepository _reminderRepository;
  final MethodChannel _channel;

  static NotificationReconciler _instance = NotificationReconciler._internal();

  factory NotificationReconciler() => _instance;

  NotificationReconciler._internal()
    : _reminderRepository = ReminderRepositoryImpl(
        remoteDataSource: ReminderRemoteDataSourceImpl(dioClient: DioClient()),
      ),
      _channel = _nativeChannel;

  @visibleForTesting
  NotificationReconciler.forTesting({
    required ReminderRepository reminderRepository,
    required MethodChannel channel,
  }) : _reminderRepository = reminderRepository,
       _channel = channel;

  @visibleForTesting
  static void setInstanceForTesting(NotificationReconciler instance) {
    _instance = instance;
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = NotificationReconciler._internal();
  }

  /// Removes any delivered iOS notification whose reminder has since been
  /// dismissed. No-op on non-iOS platforms.
  Future<void> reconcile() async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final deliveredIds = await _deliveredReminderIds();
      if (deliveredIds.isEmpty) return;

      final dismissedIds = await _dismissedAmong(deliveredIds);
      if (dismissedIds.isEmpty) return;

      await _channel.invokeMethod('removeDeliveredNotifications', {
        'identifiers': dismissedIds.map((id) => 'reminder_$id').toList(),
      });
      _log.info('Cleared ${dismissedIds.length} stale notification(s) on resume');
    } catch (e, s) {
      _log.warning('Notification reconciliation failed', e, s);
    }
  }

  /// The reminder ids currently sitting in the iOS notification tray, parsed
  /// from the `reminder_<id>` identifiers the backend assigns via apns-collapse-id.
  Future<Set<int>> _deliveredReminderIds() async {
    final identifiers =
        await _channel.invokeListMethod<String>('getDeliveredReminderIdentifiers');
    if (identifiers == null) return {};

    final ids = <int>{};
    for (final identifier in identifiers) {
      final match = _reminderIdentifier.firstMatch(identifier);
      if (match != null) ids.add(int.parse(match.group(1)!));
    }
    return ids;
  }

  /// Of the given delivered reminder ids, those the server now reports dismissed.
  Future<Set<int>> _dismissedAmong(Set<int> deliveredIds) async {
    final dismissed = await _reminderRepository.getReminders(
      dismissed: true,
      type: 3,
      forceRefresh: true,
    );
    return dismissed
        .map((r) => r.id)
        .where(deliveredIds.contains)
        .toSet();
  }
}
