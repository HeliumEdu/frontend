// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
  final int defaultReminderOffset;
  final int defaultReminderOffsetType;

  SubmitPreferencesEvent({
    required this.timeZone,
    required this.defaultView,
    required this.eventsColor,
    required this.defaultReminderOffset,
    required this.defaultReminderOffsetType,
  });
}

class FetchPreferencesEvent extends PreferenceEvent {}
