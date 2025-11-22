// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

class PreferenceState {
  final int reminderOffset;
  final String? defaultView;
  final String? timeZone;
  final String? reminderOffsetUnit;
  final Color eventColor;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  PreferenceState({
    this.reminderOffset = 0,
    this.defaultView,
    this.timeZone,
    this.reminderOffsetUnit,
    this.eventColor = const Color(0xff26A69A),
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  PreferenceState copyWith({
    int? offsetValue,
    String? selectedDefaultView,
    String? selectedTimeZone,
    String? selectedReminderPreference,
    String? selectedReminderOffsetUnit,
    Color? selectedEventsColor,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return PreferenceState(
      defaultView:
          selectedDefaultView ?? this.defaultView,
      timeZone:
          selectedTimeZone ?? this.timeZone,
      reminderOffsetUnit:
          selectedReminderOffsetUnit ?? this.reminderOffsetUnit,
      reminderOffset: offsetValue ?? this.reminderOffset,
      eventColor: selectedEventsColor ?? this.eventColor,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}
