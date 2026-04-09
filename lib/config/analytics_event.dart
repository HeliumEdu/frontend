// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
  static const String courseCreate = 'helium_course_create';
  static const String exampleScheduleClear = 'helium_example_schedule_clear';
  static const String exampleScheduleImport = 'helium_example_schedule_import';
  static const String exportTrigger = 'helium_export_trigger';
  static const String externalCalendarAdd = 'helium_external_calendar_add';
  static const String feedsDisable = 'helium_feeds_disable';
  static const String feedsEnable = 'helium_feeds_enable';
  static const String homeworkCreate = 'helium_homework_create';
  static const String importComplete = 'helium_import_complete';
  static const String noteCreate = 'helium_note_create';
  static const String reminderCreate = 'helium_reminder_create';

  // Debug / diagnostic events
  static const String debugAuthNoSetupState = 'helium_debug_auth_no_setup_state';
  static const String debugAuthTokenRefreshQueue = 'helium_debug_auth_token_refresh_queue';
  static const String debugFcmMessageDeduplicate = 'helium_debug_fcm_message_deduplicate';
  static const String debugFcmTokenStaleFail = 'helium_debug_fcm_token_stale_fail';
  static const String debugGradeCalcNoWeight = 'helium_debug_grade_calc_no_weight';
  static const String debugNoteAutosaveError = 'helium_debug_note_autosave_error';
  static const String debugSetupCacheFallback = 'helium_debug_setup_cache_fallback';
}
