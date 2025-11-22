// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class UpdateSettingsRequestModel {
  final String timeZone;
  final int defaultView;
  final int weekStartsOn;
  final bool showGettingStarted;
  final String eventsColor;
  final int defaultReminderOffset;
  final bool calendarEventLimit;
  final int defaultReminderOffsetType;
  final bool receiveEmailsFromAdmin;

  UpdateSettingsRequestModel({
    required this.timeZone,
    required this.defaultView,
    required this.weekStartsOn,
    required this.showGettingStarted,
    required this.eventsColor,
    required this.defaultReminderOffset,
    required this.calendarEventLimit,
    required this.defaultReminderOffsetType,
    required this.receiveEmailsFromAdmin,
  });

  Map<String, dynamic> toJson() => {
    'time_zone': timeZone,
    'default_view': defaultView,
    'week_starts_on': weekStartsOn,
    'show_getting_started': showGettingStarted,
    'events_color': eventsColor,
    'default_reminder_offset': defaultReminderOffset,
    'calendar_event_limit': calendarEventLimit,
    'default_reminder_offset_type': defaultReminderOffsetType,
    'receive_emails_from_admin': receiveEmailsFromAdmin,
  };
}
