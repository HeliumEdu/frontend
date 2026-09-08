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
/// A tray entry is stale when its reminder is no longer in the bell's active
/// set. Asking that rather than "was it dismissed?" also catches a reminder
/// un-sent by a reschedule, whose notification would otherwise sit in the tray
/// showing the old time.
///
/// Over-clearing is prevented by ordering: the tray is read before the active set
/// is fetched, so a reminder that fires in between cannot be cleared by mistake,
/// and a fetch failure throws past the clear step.
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

  /// Removes any delivered iOS notification whose reminder is no longer active.
  /// No-op on non-iOS platforms.
  Future<void> reconcile() async {
    if (kIsWeb || !Platform.isIOS) return;
    await _reconcile();
  }

  @visibleForTesting
  Future<void> reconcileForTesting() => _reconcile();

  Future<void> _reconcile() async {
    try {
      final deliveredIds = await _deliveredReminderIds();
      if (deliveredIds.isEmpty) return;

      final staleIds = deliveredIds.difference(await _activeReminderIds());
      if (staleIds.isEmpty) return;

      await _channel.invokeMethod('removeDeliveredNotifications', {
        'identifiers': staleIds.map((id) => 'reminder_$id').toList(),
      });
      _log.info('Cleared ${staleIds.length} stale notification(s) on resume');
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

  Future<Set<int>> _activeReminderIds() async {
    final active = await _reminderRepository.getReminders(
      sent: true,
      dismissed: false,
      type: 3,
      startOfRange: DateTime.now(),
      forceRefresh: true,
    );
    return active.map((reminder) => reminder.id).toSet();
  }
}
