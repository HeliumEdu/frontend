// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/utils/color_helpers.dart';
import 'package:timezone/standalone.dart' as tz;

class UserModel {
  final int id;
  final String username;
  final String email;
  final String? emailChanging;
  final UserSettingsModel? settings;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.emailChanging,
    this.settings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      emailChanging: json['email_changing'],
      settings: json['settings'] != null
          ? UserSettingsModel.fromJson(json['settings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'email_changing': emailChanging,
      'settings': settings?.toJson(),
    };
  }
}

class UserSettingsModel {
  tz.Location timeZone;
  final int defaultView;
  final int colorSchemeTheme;
  final int weekStartsOn;
  final int allDayOffset;
  Color eventsColor;
  Color materialColor;
  Color gradeColor;
  final int defaultReminderType;
  final int defaultReminderOffset;
  final int defaultReminderOffsetType;
  final bool colorByCategory;
  final String? privateSlug;

  UserSettingsModel({
    required this.timeZone,
    required this.defaultView,
    required this.colorSchemeTheme,
    required this.weekStartsOn,
    required this.allDayOffset,
    required this.eventsColor,
    required this.materialColor,
    required this.gradeColor,
    required this.defaultReminderType,
    required this.defaultReminderOffset,
    required this.defaultReminderOffsetType,
    required this.colorByCategory,
    this.privateSlug,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      timeZone: tz.getLocation(json['time_zone']),
      defaultView: json['default_view'],
      colorSchemeTheme: json['color_scheme_theme'],
      weekStartsOn: json['week_starts_on'],
      allDayOffset: json['all_day_offset'],
      eventsColor: HeliumColors.hexToColor(json['events_color']),
      materialColor: HeliumColors.hexToColor(json['material_color']),
      gradeColor: HeliumColors.hexToColor(json['grade_color']),
      defaultReminderType: json['default_reminder_type'],
      defaultReminderOffset: json['default_reminder_offset'],
      defaultReminderOffsetType: json['default_reminder_offset_type'],
      colorByCategory: json['calendar_use_category_colors'],
      privateSlug: json['private_slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_zone': timeZone,
      'default_view': defaultView,
      'color_scheme_theme': colorSchemeTheme,
      'week_starts_on': weekStartsOn,
      'all_day_offset': allDayOffset,
      'events_color': eventsColor,
      'material_color': materialColor,
      'grade_color': gradeColor,
      'default_reminder_type': defaultReminderOffset,
      'default_reminder_offset': defaultReminderOffset,
      'default_reminder_offset_type': defaultReminderOffsetType,
      'calendar_use_category_colors': colorByCategory,
      'private_slug': privateSlug,
    };
  }
}
