// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class UpdateSettingsRequestModel {
  final String? timeZone;
  final int? defaultView;
  final int? weekStartsOn;
  final int? colorSchemeTheme;
  final int? whatsNewVersionSeen;
  final bool? showGettingStarted;
  final bool? colorByCategory;
  final String? eventsColor;
  final String? resourceColor;
  final String? gradeColor;
  final int? defaultReminderType;
  final int? defaultReminderOffset;
  final int? defaultReminderOffsetType;
  final bool? rememberFilterState;

  UpdateSettingsRequestModel({
    this.timeZone,
    this.defaultView,
    this.weekStartsOn,
    this.colorSchemeTheme,
    this.whatsNewVersionSeen,
    this.showGettingStarted,
    this.colorByCategory,
    this.eventsColor,
    this.resourceColor,
    this.gradeColor,
    this.defaultReminderType,
    this.defaultReminderOffset,
    this.defaultReminderOffsetType,
    this.rememberFilterState,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (defaultView != null) json['default_view'] = defaultView;
    if (weekStartsOn != null) json['week_starts_on'] = weekStartsOn;
    if (colorSchemeTheme != null) json['color_scheme_theme'] = colorSchemeTheme;
    if (whatsNewVersionSeen != null) json['whats_new_version_seen'] = whatsNewVersionSeen;
    if (showGettingStarted != null) json['show_getting_started'] = showGettingStarted;
    if (colorByCategory != null) json['calendar_use_category_colors'] = colorByCategory;
    if (timeZone != null) json['time_zone'] = timeZone;
    if (eventsColor != null) json['events_color'] = eventsColor;
    if (resourceColor != null) json['material_color'] = resourceColor;
    if (gradeColor != null) json['grade_color'] = gradeColor;
    if (defaultReminderType != null) json['default_reminder_type'] = defaultReminderType;
    if (defaultReminderOffset != null) json['default_reminder_offset'] = defaultReminderOffset;
    if (defaultReminderOffsetType != null) json['default_reminder_offset_type'] = defaultReminderOffsetType;
    if (rememberFilterState != null) json['remember_filter_state'] = rememberFilterState;

    return json;
  }
}
