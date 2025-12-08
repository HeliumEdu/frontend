// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

abstract class PreferencesEvent {}

class IncrementOffsetEvent extends PreferencesEvent {}

class DecrementOffsetEvent extends PreferencesEvent {}

class UpdateOffsetEvent extends PreferencesEvent {
  final int value;

  UpdateOffsetEvent(this.value);
}

class ResetOffsetEvent extends PreferencesEvent {}

class SubmitPreferencesEvent extends PreferencesEvent {
  final String timeZone;
  final int defaultView;
  final String eventsColor;
  final String gradesColor;
  final String materialsColor;
  final int defaultReminderOffset;
  final int defaultReminderOffsetType;

  SubmitPreferencesEvent({
    required this.timeZone,
    required this.defaultView,
    required this.eventsColor,
    required this.gradesColor,
    required this.materialsColor,
    required this.defaultReminderOffset,
    required this.defaultReminderOffsetType,
  });
}

class FetchPreferencesEvent extends PreferencesEvent {}
