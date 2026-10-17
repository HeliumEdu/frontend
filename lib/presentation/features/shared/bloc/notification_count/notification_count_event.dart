import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class NotificationCountEvent extends BaseEvent {
  NotificationCountEvent({required super.origin});
}

/// Clears the bell on logout so the next session's count is its own.
class ResetNotificationCountEvent extends NotificationCountEvent {
  ResetNotificationCountEvent() : super(origin: EventOrigin.bloc);
}

/// Refreshes the badge with a count-only query rather than the list, which
/// carries the notification screen's nested payload and its prefetches.
class RefreshNotificationCountEvent extends NotificationCountEvent {
  RefreshNotificationCountEvent({required super.origin});
}

/// Replaces the active set from an authoritative fetch.
class SetActiveRemindersEvent extends NotificationCountEvent {
  final List<ReminderModel> reminders;

  SetActiveRemindersEvent({required super.origin, required this.reminders});
}

/// Adds a pushed reminder, or replaces the copy already held.
class UpsertReminderEvent extends NotificationCountEvent {
  final ReminderModel reminder;

  UpsertReminderEvent({required super.origin, required this.reminder});
}

class RemoveReminderEvent extends NotificationCountEvent {
  final int reminderId;

  RemoveReminderEvent({required super.origin, required this.reminderId});
}

class RemoveRemindersWhereEvent extends NotificationCountEvent {
  final bool Function(ReminderModel reminder) test;

  RemoveRemindersWhereEvent({required super.origin, required this.test});
}

/// Empties the set as a known-current state (dismiss-all).
class ClearRemindersEvent extends NotificationCountEvent {
  ClearRemindersEvent({required super.origin});
}
