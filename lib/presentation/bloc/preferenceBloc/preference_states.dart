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
  final Color eventsColor;
  final Color materialsColor;
  final Color gradesColor;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  PreferenceState({
    this.reminderOffset = 0,
    this.defaultView,
    this.timeZone,
    this.reminderOffsetUnit,
    this.eventsColor = const Color(0xffe74674),
    this.materialsColor = const Color(0xffdc7d50),
    this.gradesColor = const Color(0xff9d629d),
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
    Color? selectedMaterialsColor,
    Color? selectedGradesColor,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return PreferenceState(
      defaultView:
          selectedDefaultView ?? defaultView,
      timeZone:
          selectedTimeZone ?? timeZone,
      reminderOffsetUnit:
          selectedReminderOffsetUnit ?? reminderOffsetUnit,
      reminderOffset: offsetValue ?? reminderOffset,
      eventsColor: selectedEventsColor ?? eventsColor,
      materialsColor: selectedMaterialsColor ?? materialsColor,
      gradesColor: selectedGradesColor ?? gradesColor,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}
