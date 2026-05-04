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
  static const String coursesScreen = '/classes';
  static const String resourcesScreen = '/resources';
  static const String gradesScreen = '/grades';
  static const String notificationsScreen = '/notifications';
  static const String settingScreen = '/settings';
}

/// Deep link query parameter name constants and parsing utilities.
///
/// Naming convention:
/// - The parent entity of the page uses the bare [id] param (e.g., note on
///   /notebook, class on /classes, resource on /resources).
/// - [homeworkId] and [eventId] are global; they open the planner item editor
///   from any shell route or from /notifications on mobile.
/// - Linked-entity params on /notebook use the `linked` prefix to avoid
///   collision with the global planner params.
class DeepLinkParam {
  // Global params; valid on any shell route and /notifications (mobile)
  static const String homeworkId = 'homeworkId';
  static const String eventId = 'eventId';

  // Parent-entity param; meaning depends on the current route
  static const String id = 'id';

  // /notebook link-entity params; create a note pre-linked to the entity
  static const String linkHomeworkId = 'linkHomeworkId';
  static const String linkEventId = 'linkEventId';
  static const String linkResourceId = 'linkResourceId';

  // Modifiers (apply to whichever entity param or dialog is present)
  static const String tab = 'tab';
  static const String dialog = 'dialog';

  // /planner: anchor the calendar's initial display date (YYYY-MM-DD)
  static const String date = 'date';

  // dialog= values
  static const String dialogSettings = 'settings';
  static const String dialogNotifications = 'notifications';

  /// Parses an entity ID param that accepts either an integer or the sentinel
  /// string `'new'`.
  ///
  /// Returns:
  /// - `(id: X,    isNew: false)`; valid integer ID
  /// - `(id: null, isNew: true)`; value is `'new'` (create-new intent)
  /// - `(id: null, isNew: false)`; value is absent or not a valid integer
  static ({int? id, bool isNew}) parseId(String? value) {
    if (value == null) return (id: null, isNew: false);
    if (value == 'new') return (id: null, isNew: true);
    final parsed = int.tryParse(value);
    return (id: parsed, isNew: false);
  }
}
