// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class UserProfileModel {
  final int id;
  final String username;
  final String email;
  final String? emailChanging;
  final UserProfile? profile;
  final UserSettings? settings;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.emailChanging,
    this.profile,
    this.settings,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      emailChanging: json['email_changing'],
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'email_changing': emailChanging,
      'profile': profile?.toJson(),
      'settings': settings?.toJson(),
    };
  }
}

class UserProfile {
  final String? phone;
  final String? phoneChanging;
  final bool phoneVerified;
  final int userId;

  UserProfile({
    this.phone,
    this.phoneChanging,
    required this.phoneVerified,
    required this.userId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phone: json['phone'],
      phoneChanging: json['phone_changing'],
      phoneVerified: json['phone_verified'] ?? false,
      userId: json['user'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'phone_changing': phoneChanging,
      'phone_verified': phoneVerified,
      'user': userId,
    };
  }
}

class UserSettings {
  final String timeZone;
  final int defaultView;
  final int weekStartsOn;
  final int allDayOffset;
  final bool showGettingStarted;
  final String eventsColor;
  final int defaultReminderOffset;
  final bool calendarEventLimit;
  final int defaultReminderOffsetType;
  final int defaultReminderType;
  final bool receiveEmailsFromAdmin;
  final String privateSlug;
  final int userId;

  UserSettings({
    required this.timeZone,
    required this.defaultView,
    required this.weekStartsOn,
    required this.allDayOffset,
    required this.showGettingStarted,
    required this.eventsColor,
    required this.defaultReminderOffset,
    required this.calendarEventLimit,
    required this.defaultReminderOffsetType,
    required this.defaultReminderType,
    required this.receiveEmailsFromAdmin,
    required this.privateSlug,
    required this.userId,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      timeZone: json['time_zone'] ?? 'UTC',
      defaultView: json['default_view'] ?? 0,
      weekStartsOn: json['week_starts_on'] ?? 0,
      allDayOffset: json['all_day_offset'] ?? 0,
      showGettingStarted: json['show_getting_started'] ?? true,
      eventsColor: json['events_color'] ?? '#ac725e',
      defaultReminderOffset: json['default_reminder_offset'] ?? 0,
      calendarEventLimit: json['calendar_event_limit'] ?? true,
      defaultReminderOffsetType: json['default_reminder_offset_type'] ?? 0,
      defaultReminderType: json['default_reminder_type'] ?? 0,
      receiveEmailsFromAdmin: json['receive_emails_from_admin'] ?? true,
      privateSlug: json['private_slug'] ?? '',
      userId: json['user'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_zone': timeZone,
      'default_view': defaultView,
      'week_starts_on': weekStartsOn,
      'all_day_offset': allDayOffset,
      'show_getting_started': showGettingStarted,
      'events_color': eventsColor,
      'default_reminder_offset': defaultReminderOffset,
      'calendar_event_limit': calendarEventLimit,
      'default_reminder_offset_type': defaultReminderOffsetType,
      'default_reminder_type': defaultReminderType,
      'receive_emails_from_admin': receiveEmailsFromAdmin,
      'private_slug': privateSlug,
      'user': userId,
    };
  }
}
