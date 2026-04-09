// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

enum AnalyticsCategory {
  featureInteraction,
  onboarding,
  edgeCase,
  operational;

  String get value => switch (this) {
    AnalyticsCategory.featureInteraction => 'feature_interaction',
    AnalyticsCategory.onboarding         => 'onboarding',
    AnalyticsCategory.edgeCase           => 'edge_case',
    AnalyticsCategory.operational        => 'operational',
  };
}

/// Analytics event name constants.
///
/// Naming convention:
/// - [helium_] prefix: user-behavior events (actions the user takes).
/// - [helium_debug_] prefix: diagnostic events (errors, edge cases, and
///   internal state transitions not driven by direct user action).
///
/// All event names use present-tense verbs to match Flutter/Firebase
/// auto-collected event conventions.
class AnalyticsEvent {
  // User behavior events
  static const String attachmentUpload = 'helium_attachment_upload';
  static const String categoryCreate = 'helium_category_create';
  static const String courseCreate = 'helium_course_create';
  static const String courseGroupCreate = 'helium_course_group_create';
  static const String exampleScheduleClear = 'helium_example_schedule_clear';
  static const String exampleScheduleImport = 'helium_example_schedule_reimport';
  static const String eventCreate = 'helium_event_create';
  static const String exportTrigger = 'helium_export_trigger';
  static const String externalCalendarAdd = 'helium_external_calendar_add';
  static const String feedsDisable = 'helium_feeds_disable';
  static const String feedsEnable = 'helium_feeds_enable';
  static const String gradeCalculatorOpen = 'helium_grade_calculator_open';
  static const String homeworkComplete = 'helium_homework_complete';
  static const String homeworkCreate = 'helium_homework_create';
  static const String homeworkGrade = 'helium_homework_grade';
  static const String importComplete = 'helium_import_complete';
  static const String mobileWebContinue = 'helium_mobile_web_continue';
  static const String noteCreate = 'helium_note_create';
  static const String notificationsOpen = 'helium_notifications_open';
  static const String printPreview = 'helium_print_preview';
  static const String reminderCreate = 'helium_reminder_create';
  static const String resourceCreate = 'helium_resource_create';
  static const String settingsOpen = 'helium_settings_open';
  static const String themeSelect = 'helium_theme_select';
  static const String todosExportCsv = 'helium_todos_export_csv';

  // Debug / diagnostic events
  static const String debugAuthNoSetupState = 'helium_debug_auth_no_setup_state';
  static const String debugAuthTokenRefreshQueue = 'helium_debug_auth_token_refresh_queue';
  static const String debugErrorDisplay = 'helium_debug_error_display';
  static const String debugFcmMessageDeduplicate = 'helium_debug_fcm_message_deduplicate';
  static const String debugFcmTokenStaleFail = 'helium_debug_fcm_token_stale_fail';
  static const String debugGradeCalcNoWeight = 'helium_debug_grade_calc_no_weight';
  static const String debugNoteAutosaveError = 'helium_debug_note_autosave_error';
  static const String debugSetupCacheFallback = 'helium_debug_setup_cache_fallback';
}
