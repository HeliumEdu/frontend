// preference_event.dart
abstract class PreferenceEvent {}

class IncrementOffsetEvent extends PreferenceEvent {}

class DecrementOffsetEvent extends PreferenceEvent {}

class UpdateOffsetEvent extends PreferenceEvent {
  final int value;
  UpdateOffsetEvent(this.value);
}

class ResetOffsetEvent extends PreferenceEvent {}

class SubmitPreferencesEvent extends PreferenceEvent {
  final String timeZone;
  final int defaultView;
  final String eventsColor;
  final int defaultReminderType;
  final int defaultReminderOffset;
  final int defaultReminderOffsetType;

  SubmitPreferencesEvent({
    required this.timeZone,
    required this.defaultView,
    required this.eventsColor,
    required this.defaultReminderType,
    required this.defaultReminderOffset,
    required this.defaultReminderOffsetType,
  });
}

class FetchPreferencesEvent extends PreferenceEvent {}
