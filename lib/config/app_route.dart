// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class AppRoute {
  // Unauthenticated routes
  static const String landingScreen = '/';
  static const String loginScreen = '/login';
  static const String signupScreen = '/signup';
  static const String forgotPasswordScreen = '/forgot';
  static const String verifyEmailScreen = '/verify';
  static const String setupAccountScreen = '/setup';
  static const String mobileWebScreen = '/mobile-web';

  // Authenticated routes
  static const String plannerScreen = '/planner';
  static const String notebookScreen = '/notebook';
  static const String notebookEditScreen = '/notebook/edit';
  static const String coursesScreen = '/classes';
  static const String resourcesScreen = '/resources';
  static const String gradesScreen = '/grades';
  static const String notificationsScreen = '/notifications';
  static const String plannerItemAddScreen = '/planner/edit';
  static const String courseAddScreen = '/classes/edit';
  static const String resourcesAddScreen = '/resources/edit';
  static const String settingScreen = '/settings';
}
