import 'dart:ui';

import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:timezone/standalone.dart' as tz;

/// An account's progress through first-time setup, mirroring the platform's
/// `setup_state`.
enum SetupState {
  pending(0),
  importing(1),
  complete(2);

  const SetupState(this.code);

  /// The value the platform uses for this state.
  final int code;

  /// Throws on a [code] the platform doesn't define rather than guessing.
  static SetupState fromCode(int code) {
    for (final state in values) {
      if (state.code == code) return state;
    }
    throw ArgumentError.value(code, 'code', 'Unknown setup state');
  }
}

class UserSettingsModel {
  tz.Location timeZone;
  final int defaultView;
  final int colorSchemeTheme;
  final int weekStartsOn;
  final int whatsNewVersionSeen;
  final bool showGettingStarted;
  final bool gettingStartedDue;
  final SetupState setupState;
  final Color eventsColor;
  final Color resourceColor;
  final Color gradeColor;
  final int defaultReminderType;
  final int defaultReminderOffset;
  final int defaultReminderOffsetType;
  final bool colorByCategory;
  final bool showPlannerTooltips;
  final bool dragAndDropOnMobile;
  final bool rememberFilterState;
  final bool collapseBusyDays;
  final int atRiskThreshold;
  final int onTrackTolerance;
  final bool showWeekNumbers;
  final int dateFormat;
  final int timeFormat;
  final int numberFormat;
  final String? privateSlug;
  final bool promptForReview;

  UserSettingsModel({
    required this.timeZone,
    required this.defaultView,
    required this.colorSchemeTheme,
    required this.weekStartsOn,
    required this.whatsNewVersionSeen,
    required this.showGettingStarted,
    required this.gettingStartedDue,
    required this.setupState,
    required this.eventsColor,
    required this.resourceColor,
    required this.gradeColor,
    required this.defaultReminderType,
    required this.defaultReminderOffset,
    required this.defaultReminderOffsetType,
    required this.colorByCategory,
    required this.showPlannerTooltips,
    required this.dragAndDropOnMobile,
    required this.rememberFilterState,
    required this.collapseBusyDays,
    required this.atRiskThreshold,
    required this.onTrackTolerance,
    required this.showWeekNumbers,
    required this.dateFormat,
    required this.timeFormat,
    required this.numberFormat,
    this.privateSlug,
    this.promptForReview = false,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    // Do not all default fallbacks here; userSettings must be populated and
    // non-null before base pages will move past isLoading, meaning if tests
    // fail and adding default values here would "fix" them, that is not the
    // correct solution, that is an incorrect workaround; find the actual
    // regression further up the stack and patch with default values
    // there (if necessary)
    return UserSettingsModel(
      timeZone: tz.getLocation(json['time_zone']),
      defaultView: json['default_view'],
      colorSchemeTheme: json['color_scheme_theme'],
      weekStartsOn: json['week_starts_on'],
      whatsNewVersionSeen: json['whats_new_version_seen'],
      showGettingStarted: json['show_getting_started'],
      gettingStartedDue: json['getting_started_due'],
      setupState: SetupState.fromCode(json['setup_state']),
      eventsColor: HeliumColors.hexToColor(json['events_color']),
      resourceColor: HeliumColors.hexToColor(json['resource_color']),
      gradeColor: HeliumColors.hexToColor(json['grade_color']),
      defaultReminderType: json['default_reminder_type'],
      defaultReminderOffset: json['default_reminder_offset'],
      defaultReminderOffsetType: json['default_reminder_offset_type'],
      colorByCategory: json['calendar_use_category_colors'],
      showPlannerTooltips: json['show_planner_tooltips'],
      dragAndDropOnMobile: json['drag_and_drop_on_mobile'],
      rememberFilterState: json['remember_filter_state'],
      collapseBusyDays: json['calendar_event_limit'],
      atRiskThreshold: json['at_risk_threshold'] ?? FallbackConstants.defaultAtRiskThreshold,
      onTrackTolerance: json['on_track_tolerance'] ?? FallbackConstants.defaultOnTrackTolerance,
      showWeekNumbers: json['show_week_numbers'] ?? FallbackConstants.defaultShowWeekNumbers,
      dateFormat: json['date_format'] ?? FallbackConstants.defaultDateFormat,
      timeFormat: json['time_format'] ?? FallbackConstants.defaultTimeFormat,
      numberFormat: json['number_format'] ?? FallbackConstants.defaultNumberFormat,
      privateSlug: json['private_slug'],
      promptForReview: json['prompt_for_review'] ?? false,
    );
  }
}
