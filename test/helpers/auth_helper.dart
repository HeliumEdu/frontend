// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/private_feed_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';

/// Creates JSON data representing a user settings object.
Map<String, dynamic> givenUserSettingsJson({
  String timeZone = 'America/New_York',
  int defaultView = 0,
  int colorSchemeTheme = 0,
  int weekStartsOn = 0,
  int allDayOffset = 0,
  int whatsNewVersionSeen = 0,
  String eventsColor = '#4CAF50',
  String resourceColor = '#2196F3',
  String gradeColor = '#FF9800',
  int defaultReminderType = 3,
  int defaultReminderOffset = 15,
  int defaultReminderOffsetType = 0,
  bool colorByCategory = false,
  bool showGettingStarted = false,
  bool isSetupComplete = true,
  bool showPlannerTooltips = true,
  bool dragAndDropOnMobile = true,
  bool rememberFilterState = false,
  String? privateSlug,
}) {
  return {
    'time_zone': timeZone,
    'default_view': defaultView,
    'color_scheme_theme': colorSchemeTheme,
    'week_starts_on': weekStartsOn,
    'all_day_offset': allDayOffset,
    'whats_new_version_seen': whatsNewVersionSeen,
    'events_color': eventsColor,
    'material_color': resourceColor,
    'grade_color': gradeColor,
    'default_reminder_type': defaultReminderType,
    'default_reminder_offset': defaultReminderOffset,
    'default_reminder_offset_type': defaultReminderOffsetType,
    'calendar_use_category_colors': colorByCategory,
    'show_getting_started': showGettingStarted,
    'is_setup_complete': isSetupComplete,
    'show_planner_tooltips': showPlannerTooltips,
    'drag_and_drop_on_mobile': dragAndDropOnMobile,
    'remember_filter_state': rememberFilterState,
    'private_slug': privateSlug,
  };
}

/// Creates JSON data representing a user object.
Map<String, dynamic> givenUserJson({
  int id = 1,
  String email = 'test@heliumedu.com',
  String? emailChanging,
  Map<String, dynamic>? settings,
}) {
  return {
    'id': id,
    'email': email,
    'email_changing': emailChanging,
    'settings': settings ?? givenUserSettingsJson(),
  };
}

/// Creates JSON data representing a token response.
Map<String, dynamic> givenTokenResponseJson({
  String access = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test_access_token',
  String refresh = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test_refresh_token',
}) {
  return {'access': access, 'refresh': refresh};
}

/// Creates JSON data representing a private feed response.
Map<String, dynamic> givenPrivateFeedJson({
  String eventsPrivateUrl = 'https://api.heliumedu.com/feeds/events/abc123',
  String homeworkPrivateUrl = 'https://api.heliumedu.com/feeds/homework/abc123',
  String courseSchedulesPrivateUrl =
      'https://api.heliumedu.com/feeds/schedules/abc123',
}) {
  return {
    'events_private_url': eventsPrivateUrl,
    'homework_private_url': homeworkPrivateUrl,
    'courseschedules_private_url': courseSchedulesPrivateUrl,
  };
}

/// Creates JSON data representing a login request.
Map<String, dynamic> givenLoginRequestJson({
  String username = 'test_user',
  String password = 'test_pass_1!',
}) {
  return {'username': username, 'password': password};
}

/// Creates JSON data representing a register request.
Map<String, dynamic> givenRegisterRequestJson({
  String email = 'newuser@test.com',
  String password = 'secure_pass_1!',
  String timeZone = 'America/New_York',
}) {
  return {'email': email, 'password': password, 'time_zone': timeZone};
}

/// Verifies that a [UserModel] matches the expected JSON data.
void verifyUserMatchesJson(UserModel user, Map<String, dynamic> json) {
  expect(user.id, equals(json['id']));
  expect(user.email, equals(json['email']));
  expect(user.emailChanging, equals(json['email_changing']));

  if (json['settings'] != null) {
    verifyUserSettingsMatchesJson(user.settings, json['settings']);
  }
}

/// Verifies that a [UserSettingsModel] matches the expected JSON data.
void verifyUserSettingsMatchesJson(
  UserSettingsModel settings,
  Map<String, dynamic> json,
) {
  expect(settings.timeZone.name, equals(json['time_zone']));
  expect(settings.defaultView, equals(json['default_view']));
  expect(settings.weekStartsOn, equals(json['week_starts_on']));
  expect(settings.colorSchemeTheme, equals(json['color_scheme_theme']));
  expect(settings.allDayOffset, equals(json['all_day_offset']));
  expect(settings.whatsNewVersionSeen, equals(json['whats_new_version_seen']));
  expect(settings.defaultReminderType, equals(json['default_reminder_type']));
  expect(
    settings.defaultReminderOffset,
    equals(json['default_reminder_offset']),
  );
  expect(
    settings.defaultReminderOffsetType,
    equals(json['default_reminder_offset_type']),
  );
  expect(
    settings.colorByCategory,
    equals(json['calendar_use_category_colors']),
  );
  expect(settings.showPlannerTooltips, equals(json['show_planner_tooltips']));
  expect(settings.rememberFilterState, equals(json['remember_filter_state']));
  expect(settings.privateSlug, equals(json['private_slug']));
}

/// Verifies that a [TokenResponseModel] matches the expected JSON data.
void verifyTokenResponseMatchesJson(
  TokenResponseModel tokenResponse,
  Map<String, dynamic> json,
) {
  expect(tokenResponse.access, equals(json['access']));
  expect(tokenResponse.refresh, equals(json['refresh']));
}

/// Verifies that a [PrivateFeedModel] matches the expected JSON data.
void verifyPrivateFeedMatchesJson(
  PrivateFeedModel privateFeed,
  Map<String, dynamic> json,
) {
  expect(privateFeed.eventsPrivateUrl, equals(json['events_private_url']));
  expect(privateFeed.homeworkPrivateUrl, equals(json['homework_private_url']));
  expect(
    privateFeed.courseSchedulesPrivateUrl,
    equals(json['courseschedules_private_url']),
  );
}
