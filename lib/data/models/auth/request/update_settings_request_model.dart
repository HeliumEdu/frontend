class UpdateSettingsRequestModel {
  final String? timeZone;
  final int? defaultView;
  final int? weekStartsOn;
  final int? colorSchemeTheme;
  final int? whatsNewVersionSeen;
  final bool? colorByCategory;
  final bool? showPlannerTooltips;
  final bool? dragAndDropOnMobile;
  final String? eventsColor;
  final String? resourceColor;
  final String? gradeColor;
  final int? defaultReminderType;
  final int? defaultReminderOffset;
  final int? defaultReminderOffsetType;
  final bool? rememberFilterState;
  final bool? collapseBusyDays;
  final int? atRiskThreshold;
  final int? onTrackTolerance;
  final bool? showWeekNumbers;
  final int? dateFormat;
  final int? timeFormat;
  final int? numberFormat;

  UpdateSettingsRequestModel({
    this.timeZone,
    this.defaultView,
    this.weekStartsOn,
    this.colorSchemeTheme,
    this.whatsNewVersionSeen,
    this.colorByCategory,
    this.showPlannerTooltips,
    this.dragAndDropOnMobile,
    this.eventsColor,
    this.resourceColor,
    this.gradeColor,
    this.defaultReminderType,
    this.defaultReminderOffset,
    this.defaultReminderOffsetType,
    this.rememberFilterState,
    this.collapseBusyDays,
    this.atRiskThreshold,
    this.onTrackTolerance,
    this.showWeekNumbers,
    this.dateFormat,
    this.timeFormat,
    this.numberFormat,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (defaultView != null) {
      json['default_view'] = defaultView;
    }
    if (weekStartsOn != null) {
      json['week_starts_on'] = weekStartsOn;
    }
    if (colorSchemeTheme != null) {
      json['color_scheme_theme'] = colorSchemeTheme;
    }
    if (whatsNewVersionSeen != null) {
      json['whats_new_version_seen'] = whatsNewVersionSeen;
    }
    if (colorByCategory != null) {
      json['calendar_use_category_colors'] = colorByCategory;
    }
    if (showPlannerTooltips != null) {
      json['show_planner_tooltips'] = showPlannerTooltips;
    }
    if (dragAndDropOnMobile != null) {
      json['drag_and_drop_on_mobile'] = dragAndDropOnMobile;
    }
    if (timeZone != null) {
      json['time_zone'] = timeZone;
    }
    if (eventsColor != null) {
      json['events_color'] = eventsColor;
    }
    if (resourceColor != null) {
      json['resource_color'] = resourceColor;
    }
    if (gradeColor != null) {
      json['grade_color'] = gradeColor;
    }
    if (defaultReminderType != null) {
      json['default_reminder_type'] = defaultReminderType;
    }
    if (defaultReminderOffset != null) {
      json['default_reminder_offset'] = defaultReminderOffset;
    }
    if (defaultReminderOffsetType != null) {
      json['default_reminder_offset_type'] = defaultReminderOffsetType;
    }
    if (rememberFilterState != null) {
      json['remember_filter_state'] = rememberFilterState;
    }
    if (collapseBusyDays != null) {
      json['calendar_event_limit'] = collapseBusyDays;
    }
    if (atRiskThreshold != null) {
      json['at_risk_threshold'] = atRiskThreshold;
    }
    if (onTrackTolerance != null) {
      json['on_track_tolerance'] = onTrackTolerance;
    }
    if (showWeekNumbers != null) {
      json['show_week_numbers'] = showWeekNumbers;
    }
    if (dateFormat != null) {
      json['date_format'] = dateFormat;
    }
    if (timeFormat != null) {
      json['time_format'] = timeFormat;
    }
    if (numberFormat != null) {
      json['number_format'] = numberFormat;
    }

    return json;
  }
}
