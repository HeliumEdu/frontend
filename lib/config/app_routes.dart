// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Route path constants for the application.
class AppRoutes {
  // Unauthenticated routes
  static const String landingScreen = '/';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
  static const String forgotPasswordScreen = '/forgot';
  static const String verifyScreen = '/verify';
  // Authenticated routes
  static const String calendarScreen = '/calendar';
  static const String coursesScreen = '/classes';
  static const String materialsScreen = '/materials';
  static const String gradesScreen = '/grades';
  static const String notificationsScreen = '/notifications';
  static const String calendarItemAddScreen = '/calendar/add';
  static const String calendarItemAddRemindersScreen = '/calendar/add/reminders';
  static const String calendarItemAddAttachmentsScreen =
      '/calendar/add/attachments';
  static const String courseAddScreen = '/classes/add';
  static const String courseAddScheduleScreen = '/classes/add/schedule';
  static const String courseAddCategoriesScreen = '/classes/add/categories';
  static const String courseAddAttachmentsScreen = '/classes/add/attachments';
  static const String materialAddScreen = '/materials/add';
  static const String settingScreen = '/settings';
  static const String preferencesScreen = '/settings/preferences';
  static const String feedsScreen = '/settings/feeds';
  static const String externalCalendarsScreen = '/settings/external-calendars';
  static const String changePasswordScreen = '/settings/change-password';
}
