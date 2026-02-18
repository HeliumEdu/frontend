// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:timezone/standalone.dart' as tz;

class UserModel extends BaseModel {
  final String email;
  final UserSettingsModel settings;
  final String? emailChanging;
  final bool hasUsablePassword;

  UserModel({
    required super.id,
    required this.email,
    required this.settings,
    this.emailChanging,
    required this.hasUsablePassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      emailChanging: json['email_changing'],
      settings: UserSettingsModel.fromJson(json['settings']),
      hasUsablePassword: json['has_usable_password'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_changing': emailChanging,
      'settings': settings.toJson(),
      'has_usable_password': hasUsablePassword,
    };
  }
}

class UserSettingsModel {
  tz.Location timeZone;
  final int defaultView;
  final int colorSchemeTheme;
  final int weekStartsOn;
  final int allDayOffset;
  final int whatsNewVersionSeen;
  final bool showGettingStarted;
  final bool isSetupComplete;
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
  final String? privateSlug;

  UserSettingsModel({
    required this.timeZone,
    required this.defaultView,
    required this.colorSchemeTheme,
    required this.weekStartsOn,
    required this.allDayOffset,
    required this.whatsNewVersionSeen,
    required this.showGettingStarted,
    required this.isSetupComplete,
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
    this.privateSlug,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      timeZone: tz.getLocation(json['time_zone']),
      defaultView: json['default_view'],
      colorSchemeTheme: json['color_scheme_theme'],
      weekStartsOn: json['week_starts_on'],
      allDayOffset: json['all_day_offset'],
      whatsNewVersionSeen: json['whats_new_version_seen'],
      showGettingStarted: json['show_getting_started'],
      isSetupComplete: json['is_setup_complete'],
      eventsColor: HeliumColors.hexToColor(json['events_color']),
      resourceColor: HeliumColors.hexToColor(json['material_color']),
      gradeColor: HeliumColors.hexToColor(json['grade_color']),
      defaultReminderType: json['default_reminder_type'],
      defaultReminderOffset: json['default_reminder_offset'],
      defaultReminderOffsetType: json['default_reminder_offset_type'],
      colorByCategory: json['calendar_use_category_colors'],
      showPlannerTooltips: json['show_planner_tooltips'],
      dragAndDropOnMobile: json['drag_and_drop_on_mobile'],
      rememberFilterState: json['remember_filter_state'],
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
      'show_getting_started': showGettingStarted,
      'is_setup_complete': isSetupComplete,
      'events_color': eventsColor,
      'material_color': resourceColor,
      'grade_color': gradeColor,
      'default_reminder_type': defaultReminderOffset,
      'default_reminder_offset': defaultReminderOffset,
      'default_reminder_offset_type': defaultReminderOffsetType,
      'calendar_use_category_colors': colorByCategory,
      'show_planner_tooltips': showPlannerTooltips,
      'drag_and_drop_on_mobile': dragAndDropOnMobile,
      'remember_filter_state': rememberFilterState,
      'private_slug': privateSlug,
    };
  }
}
