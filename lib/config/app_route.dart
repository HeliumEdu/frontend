// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class AppRoute {
  // Unauthenticated routes
  static const String landingScreen = '/';
  static const String signinScreen = '/signin';
  static const String signupScreen = '/signup';

  /// Legacy aliases — redirected to canonical routes.
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
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
/// - Linked-entity params on /notebook create a note pre-linked to the
///   homework/event/resource specified.
class DeepLinkParam {
  // Parent-entity param; meaning depends on the current route
  static const String id = 'id';

  // Note-link query params on `/notebook/new` — pre-link the new note
  // to an existing entity. Lives in the URL so the link survives browser
  // refresh; non-routing metadata, not a dialog-routing trigger.
  static const String linkHomeworkId = 'linkHomeworkId';
  static const String linkEventId = 'linkEventId';
  static const String linkResourceId = 'linkResourceId';

  // Modifiers (apply to whichever entity param is present)
  static const String tab = 'tab';

  // /planner: anchor the calendar's initial display date (YYYY-MM-DD)
  static const String date = 'date';

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
