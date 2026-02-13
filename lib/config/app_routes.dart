// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class AppRoutes {
  // Unauthenticated routes
  static const String landingScreen = '/';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
  static const String forgotPasswordScreen = '/forgot';
  static const String verifyScreen = '/verify';

  // Authenticated routes
  static const String plannerScreen = '/planner';
  static const String coursesScreen = '/classes';
  static const String resourcesScreen = '/resources';
  static const String gradesScreen = '/grades';
  static const String notificationsScreen = '/notifications';
  static const String plannerItemAddScreen = '/planner/add';
  static const String courseAddScreen = '/classes/add';
  static const String resourcesAddScreen = '/resources/add';
  static const String settingScreen = '/settings';
  static const String preferencesScreen = '/settings/preferences';
  static const String feedsScreen = '/settings/feeds';
  static const String externalCalendarsScreen = '/settings/external-calendars';
  static const String changePasswordScreen = '/settings/change-password';
}
