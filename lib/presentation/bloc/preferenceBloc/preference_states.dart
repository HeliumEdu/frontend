// preference_state.dart
import 'dart:ui';

class PreferenceState {
  final int offsetValue;
  final String? selectedDefaultPreference;
  final String? selectedTimezonePreference;
  final String? selectedReminderPreference;
  final String? selectedReminderTypePreference;
  final Color selectedColor;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  PreferenceState({
    this.offsetValue = 0,
    this.selectedDefaultPreference,
    this.selectedTimezonePreference,
    this.selectedReminderPreference,
    this.selectedReminderTypePreference,
    this.selectedColor = const Color(0xFF26A69A),
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  PreferenceState copyWith({
    int? offsetValue,
    String? selectedDefaultPreference,
    String? selectedTimezonePreference,
    String? selectedReminderPreference,
    String? selectedReminderTypePreference,
    Color? selectedColor,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return PreferenceState(
      offsetValue: offsetValue ?? this.offsetValue,
      selectedDefaultPreference:
          selectedDefaultPreference ?? this.selectedDefaultPreference,
      selectedTimezonePreference:
          selectedTimezonePreference ?? this.selectedTimezonePreference,
      selectedReminderPreference:
          selectedReminderPreference ?? this.selectedReminderPreference,
      selectedReminderTypePreference:
          selectedReminderTypePreference ?? this.selectedReminderTypePreference,
      selectedColor: selectedColor ?? this.selectedColor,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}
