// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/dirty_dialog_registry.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:heliumapp/presentation/core/views/landing_screen.dart';
import 'package:heliumapp/presentation/core/views/mobile_web_screen.dart';
import 'package:heliumapp/presentation/core/views/notification_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/forgot_password_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/login_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/setup_account_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/signup_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/verify_email_screen.dart';
import 'package:heliumapp/presentation/core/views/responsive_dialog_page.dart';
import 'package:heliumapp/presentation/features/courses/views/course_add_screen.dart';
import 'package:heliumapp/presentation/features/courses/views/courses_screen.dart';
import 'package:heliumapp/presentation/features/grades/views/grades_screen.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/notebook/views/notebook_screen.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_screen.dart';
import 'package:heliumapp/presentation/features/resources/views/resource_add_screen.dart';
import 'package:heliumapp/presentation/features/resources/views/resources_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/settings_screen.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
late final GoRouter router;
final _log = Logger('config.router');

void initializeRouter() {
  // Enable URL updates for push/pop on web. Direct URL access to sub-sub pages
  // and edit screens is guarded by redirect checks in the route definitions.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.landingScreen,
    redirect: _authRedirect,
    observers: [AnalyticsService().observer],
    errorBuilder: (context, state) =>
        const _RouteRedirect(redirectTo: AppRoute.plannerScreen),
    routes: [
      // Public routes (no shell)
      GoRoute(
        path: AppRoute.landingScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LandingScreen()),
      ),
      GoRoute(
        path: AppRoute.signinScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoute.signupScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SignupScreen()),
      ),
      // Legacy aliases
      GoRoute(
        path: AppRoute.loginScreen,
        redirect: (_, _) => AppRoute.signinScreen,
      ),
      GoRoute(
        path: AppRoute.registerScreen,
        redirect: (_, _) => AppRoute.signupScreen,
      ),
      GoRoute(
        path: AppRoute.forgotPasswordScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoute.verifyEmailScreen,
        pageBuilder: (context, state) {
          // `username` accepted as a back-compat alias so verification links
          // from old emails (sent before the template moved to `?email=`) still
          // auto-fill the form.
          final email = state.uri.queryParameters['email']
              ?? state.uri.queryParameters['username'];
          final code = state.uri.queryParameters['code'];
          return MaterialPage(
            child: VerifyEmailScreen(email: email, code: code),
          );
        },
      ),
      GoRoute(
        path: AppRoute.setupAccountScreen,
        pageBuilder: (context, state) {
          final autoDetectTimeZone =
              state.uri.queryParameters['auto_detect_tz'] == 'true';
          return MaterialPage(
            child: SetupAccountScreen(autoDetectTimeZone: autoDetectTimeZone),
          );
        },
      ),
      GoRoute(
        path: AppRoute.mobileWebScreen,
        pageBuilder: (context, state) {
          final nextRoute =
              state.uri.queryParameters['next'] ?? AppRoute.landingScreen;
          return MaterialPage(child: MobileWebScreen(nextRoute: nextRoute));
        },
      ),

      // Bare-URL redirects for cross-shell overlay paths — seed the planner
      // shell underneath when entering /settings or /notifications directly.
      GoRoute(
        path: AppRoute.settingScreen,
        redirect: (context, state) => '${AppRoute.plannerScreen}'
            '${AppRoute.settingScreen}',
      ),
      GoRoute(
        path: '${AppRoute.settingScreen}/:subScreen',
        redirect: (context, state) =>
            '${AppRoute.plannerScreen}${AppRoute.settingScreen}'
            '/${state.pathParameters['subScreen']}',
      ),
      GoRoute(
        path: AppRoute.notificationsScreen,
        redirect: (context, state) => '${AppRoute.plannerScreen}'
            '${AppRoute.notificationsScreen}',
      ),

      // Main app shell — StatefulShellRoute preserves per-tab state via
      // separate navigators per branch. Overlay routes (settings,
      // notifications, etc.) are nested under each branch so the underlying
      // shell stays mounted behind the dialog.
      //
      // `navigatorContainerBuilder` renders only the active branch — tab
      // switches dispose the previous branch's tree and mount the next
      // afresh, so `initState` re-fires for the screen's BLoC fetches and
      // transient UI state (filter menus, scroll position) resets. Data
      // persistence is the DAO/HTTP cache's job, not the UI layer.
      StatefulShellRoute(
        builder: (context, state, navigationShell) => NavigationShell(
          navigationShell: navigationShell,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) {
          return children[navigationShell.currentIndex];
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.plannerScreen,
                pageBuilder: (context, state) =>
                    NoTransitionPage(child: PlannerScreen()),
                routes: [
                  ..._shellOverlayRoutes(),
                  ..._plannerItemEntityRoutes(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.notebookScreen,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: NotebookScreen()),
                routes: [
                  ..._shellOverlayRoutes(),
                  ..._noteEntityRoutes(),
                  ..._plannerItemEntityRoutes(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.coursesScreen,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CoursesScreen()),
                routes: [
                  ..._shellOverlayRoutes(),
                  ..._courseEntityRoutes(),
                  ..._plannerItemEntityRoutes(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.resourcesScreen,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ResourcesScreen()),
                routes: [
                  ..._shellOverlayRoutes(),
                  ..._resourceEntityRoutes(),
                  ..._plannerItemEntityRoutes(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.gradesScreen,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: GradesScreen()),
                routes: [
                  ..._shellOverlayRoutes(),
                  ..._plannerItemEntityRoutes(),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Overlay routes (settings, notifications) nested under each shell branch.
/// Sub-screens like `settings/:subScreen` are siblings of `settings` (not
/// child routes) so the navigator only ever has one settings page on its
/// stack. Switching between home and sub-screens swaps the page in place
/// via the shared [_settingsPageKey].
List<RouteBase> _shellOverlayRoutes() => [
      GoRoute(
        path: 'settings',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _settingsDialogPage(context, state, initialTab: null),
      ),
      GoRoute(
        path: 'settings/:subScreen',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final subScreen = state.pathParameters['subScreen'];
          if (subScreen == null ||
              !_validSettingsSubScreens.contains(subScreen)) {
            // Walk up to the parent settings home for unknown sub-screens.
            final base = state.matchedLocation;
            return base.substring(0, base.lastIndexOf('/'));
          }
          return null;
        },
        pageBuilder: (context, state) => _settingsDialogPage(
          context,
          state,
          initialTab: state.pathParameters['subScreen'],
        ),
      ),
      GoRoute(
        path: 'notifications',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          // Derive the originating shell from `matchedLocation` so the
          // homework/event open-from-notification flow lands on the same
          // shell the user opened notifications from.
          final matched = state.matchedLocation;
          final notificationsIdx =
              matched.indexOf(AppRoute.notificationsScreen);
          final shellPath = notificationsIdx > 0
              ? matched.substring(0, notificationsIdx)
              : AppRoute.plannerScreen;
          final useCompact = Responsive.useCompactLayout(context);
          return responsiveDialogPage(
            context,
            state,
            child: NotificationsScreen(shellPath: shellPath),
            width: useCompact
                ? double.infinity
                : AppConstants.notificationsDialogWidth,
            alignment: useCompact ? Alignment.center : Alignment.centerRight,
            insetPadding: useCompact
                ? EdgeInsets.zero
                : const EdgeInsets.only(
                    top: 16,
                    bottom: 16,
                    right: 16,
                    left: 100,
                  ),
          );
        },
      ),
    ];

const _validSettingsSubScreens = {
  'preferences',
  'external-calendars',
  'feeds',
  'change-email',
  'change-password',
  'import-export',
};

/// Static page key shared by all settings sub-route variants so Navigator
/// updates the existing page in-place when the URL changes between, e.g.,
/// `/settings` and `/settings/preferences`. Avoids the dialog flicker that
/// would result from a fresh push/pop on every sub-screen tap.
const _settingsPageKey = ValueKey('settings-dialog');

Page<dynamic> _settingsDialogPage(
  BuildContext context,
  GoRouterState state, {
  required String? initialTab,
}) {
  // Strip the trailing `/settings[/sub]` to get the underlying shell path
  // (e.g. `/planner`, `/notebook`). The pageBuilder's state is authoritative
  // for the active route; the global router config can lag for overlay routes.
  final matched = state.matchedLocation;
  final settingsIdx = matched.indexOf(AppRoute.settingScreen);
  final shellPath = settingsIdx > 0
      ? matched.substring(0, settingsIdx)
      : AppRoute.plannerScreen;
  final useCompact = Responsive.useCompactLayout(context);
  return responsiveDialogPage(
    context,
    state,
    key: _settingsPageKey,
    child: SettingsScreen(
      initialTab: initialTab,
      shellPath: shellPath,
    ),
    width: useCompact
        ? double.infinity
        : AppConstants.leftPanelDialogWidth,
    alignment: useCompact ? Alignment.center : Alignment.centerLeft,
    insetPadding: useCompact
        ? EdgeInsets.zero
        : const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 100),
  );
}

/// Step segments for the course editor dialog. URL position 0 is the
/// landing step; an unknown step segment redirects to the landing step.
const List<String> courseDialogSteps = [
  'details',
  'schedule',
  'reminders',
  'categories',
  'attachments',
];

/// Single key shared across every variant of the course editor route so
/// step transitions update the existing dialog in place rather than
/// pushing a new one each time.
const _courseDialogPageKey = ValueKey('course-dialog');

/// Course entity overlay routes mounted under the `/classes` shell branch.
/// `/classes/:id` redirects to the landing step; `/classes/:id/:step`
/// renders the editor. The `id` segment accepts an integer or the `'new'`
/// sentinel; for the create flow, the originating shell must supply the
/// course group via the `group` query parameter.
List<RouteBase> _courseEntityRoutes() => [
      GoRoute(
        path: ':id',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) return AppRoute.coursesScreen;
          return '${AppRoute.coursesScreen}/$id/${courseDialogSteps.first}';
        },
      ),
      GoRoute(
        path: ':id/:step',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final step = state.pathParameters['step'];
          if (step == null || !courseDialogSteps.contains(step)) {
            final id = state.pathParameters['id'] ?? 'new';
            return '${AppRoute.coursesScreen}/$id/${courseDialogSteps.first}';
          }
          return null;
        },
        pageBuilder: (context, state) => _courseDialogPage(context, state),
      ),
    ];

Page<dynamic> _courseDialogPage(
  BuildContext context,
  GoRouterState state,
) {
  final idParam = state.pathParameters['id'] ?? 'new';
  final stepParam = state.pathParameters['step'] ?? courseDialogSteps.first;
  final parsedId = DeepLinkParam.parseId(idParam);
  final extra = state.extra;
  // For the create flow the originating shell rides the course group in via
  // GoRouter's `extra`. For edit, the dialog resolves the group from
  // CourseBloc state and this stays null.
  final courseGroupId =
      (extra is CourseDialogExtra) ? extra.courseGroupId : null;
  final useCompact = Responsive.useCompactLayout(context);
  return responsiveDialogPage(
    context,
    state,
    key: _courseDialogPageKey,
    child: CourseAddScreen(
      shellPath: AppRoute.coursesScreen,
      courseId: parsedId.id,
      isNew: parsedId.isNew,
      courseGroupId: courseGroupId,
      initialStepName: stepParam,
      initialFullPath: state.uri.toString(),
    ),
    width: useCompact
        ? double.infinity
        : AppConstants.centeredDialogWidth,
    insetPadding:
        useCompact ? EdgeInsets.zero : const EdgeInsets.all(16),
    alignment: Alignment.center,
  );
}

/// Typed payload riding alongside an imperative push to the course editor
/// route. Carries the course group ID for the create flow without exposing
/// it in the URL. Survives in-app pushes/gos but not browser refresh —
/// existing-course edits use [CourseBloc] state to recover the group.
class CourseDialogExtra {
  final int courseGroupId;

  const CourseDialogExtra({required this.courseGroupId});
}

/// Single key shared across every variant of the note editor route so
/// in-dialog navigation updates the existing page in place rather than
/// pushing a fresh one.
const _noteDialogPageKey = ValueKey('note-dialog');

/// Note entity overlay route mounted under the `/notebook` shell branch.
/// `/notebook/:id` renders the editor; the dialog is single-step so no
/// step segment is needed. The `id` segment accepts an integer or the
/// `'new'` sentinel. Linked-entity context (homework, event, resource)
/// rides as GoRouter `extra` since it's only meaningful for the in-app
/// create flow.
List<RouteBase> _noteEntityRoutes() => [
      GoRoute(
        path: ':id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _noteDialogPage(context, state),
      ),
    ];

Page<dynamic> _noteDialogPage(
  BuildContext context,
  GoRouterState state,
) {
  final idParam = state.pathParameters['id'] ?? 'new';
  final parsedId = DeepLinkParam.parseId(idParam);
  // Linked-entity context for the create flow rides as query params so the
  // link survives browser refresh / sharing. Deep-link edits don't need
  // them — the note's own model carries the relation.
  final query = state.uri.queryParameters;
  final linkHomeworkId =
      int.tryParse(query[DeepLinkParam.linkHomeworkId] ?? '');
  final linkEventId = int.tryParse(query[DeepLinkParam.linkEventId] ?? '');
  final linkResourceId =
      int.tryParse(query[DeepLinkParam.linkResourceId] ?? '');
  final useCompact = Responsive.useCompactLayout(context);
  return responsiveDialogPage(
    context,
    state,
    key: _noteDialogPageKey,
    child: NoteAddScreen(
      shellPath: AppRoute.notebookScreen,
      noteId: parsedId.id,
      isNew: parsedId.isNew,
      initialFullPath: state.uri.toString(),
      linkHomeworkId: linkHomeworkId,
      linkEventId: linkEventId,
      linkResourceId: linkResourceId,
    ),
    width: double.infinity,
    insetPadding:
        useCompact ? EdgeInsets.zero : const EdgeInsets.all(32),
    alignment: Alignment.center,
  );
}

/// Step segments for the resource editor dialog. URL position 0 is the
/// landing step; an unknown step segment redirects to the landing step.
const List<String> resourceDialogSteps = [
  'details',
];

/// Single key shared across every variant of the resource editor route so
/// in-dialog navigation updates the existing page in place rather than
/// pushing a fresh one.
const _resourceDialogPageKey = ValueKey('resource-dialog');

/// Resource entity overlay routes mounted under the `/resources` shell
/// branch. `/resources/:id` redirects to the landing step;
/// `/resources/:id/:step` renders the editor. The `id` segment accepts an
/// integer or the `'new'` sentinel; for the create flow, the originating
/// shell must supply the resource group via GoRouter `extra`.
List<RouteBase> _resourceEntityRoutes() => [
      GoRoute(
        path: ':id',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) return AppRoute.resourcesScreen;
          return '${AppRoute.resourcesScreen}/$id/'
              '${resourceDialogSteps.first}';
        },
      ),
      GoRoute(
        path: ':id/:step',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final step = state.pathParameters['step'];
          if (step == null || !resourceDialogSteps.contains(step)) {
            final id = state.pathParameters['id'] ?? 'new';
            return '${AppRoute.resourcesScreen}/$id/'
                '${resourceDialogSteps.first}';
          }
          return null;
        },
        pageBuilder: (context, state) => _resourceDialogPage(context, state),
      ),
    ];

Page<dynamic> _resourceDialogPage(
  BuildContext context,
  GoRouterState state,
) {
  final idParam = state.pathParameters['id'] ?? 'new';
  final stepParam = state.pathParameters['step'] ?? resourceDialogSteps.first;
  final parsedId = DeepLinkParam.parseId(idParam);
  final extra = state.extra;
  // The originating shell rides the resource group in via `extra` for the
  // create flow. For edit, the dialog resolves the group from ResourceBloc
  // state and this stays null.
  final resourceGroupId =
      (extra is ResourceDialogExtra) ? extra.resourceGroupId : null;
  final useCompact = Responsive.useCompactLayout(context);
  return responsiveDialogPage(
    context,
    state,
    key: _resourceDialogPageKey,
    child: ResourceAddScreen(
      shellPath: AppRoute.resourcesScreen,
      resourceId: parsedId.id,
      isNew: parsedId.isNew,
      resourceGroupId: resourceGroupId,
      initialStepName: stepParam,
      initialFullPath: state.uri.toString(),
    ),
    width: useCompact ? double.infinity : AppConstants.centeredDialogWidth,
    insetPadding:
        useCompact ? EdgeInsets.zero : const EdgeInsets.all(16),
    alignment: Alignment.center,
  );
}

/// Typed payload riding alongside an imperative push to the resource
/// editor route. Carries the resource group ID for the create flow without
/// exposing it in the URL. Survives in-app pushes/gos but not browser
/// refresh — existing-resource edits use [ResourceBloc] state to recover
/// the group.
class ResourceDialogExtra {
  final int resourceGroupId;

  const ResourceDialogExtra({required this.resourceGroupId});
}

/// Step segments for the planner item (homework / event) editor dialog. URL
/// position 0 is the landing step; an unknown step segment redirects to the
/// landing step.
const List<String> plannerItemDialogSteps = [
  'details',
  'reminders',
  'attachments',
];

/// URL segment identifying the homework variant of the planner item dialog.
const String plannerItemHomeworkPath = 'homework';

/// URL segment identifying the event variant of the planner item dialog.
const String plannerItemEventPath = 'event';

/// Page key shared across every variant of the homework / event editor
/// routes so step and entity-type transitions update the existing dialog in
/// place rather than pushing a new one each time.
const _plannerItemDialogPageKey = ValueKey('planner-item-dialog');

/// Planner item entity overlay routes (homework + event), duplicated under
/// every shell branch so opening a planner item keeps the user on the shell
/// they came from (Q11 in the routing plan). The pageBuilder derives the
/// shell path from [GoRouterState.matchedLocation] rather than hardcoding
/// `/planner` so the same helper works for all five branches.
List<RouteBase> _plannerItemEntityRoutes() => [
      GoRoute(
        path: '$plannerItemHomeworkPath/:id',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          final shellPath = _plannerItemShellPath(
            state.matchedLocation,
            plannerItemHomeworkPath,
          );
          if (id == null) return shellPath;
          return '$shellPath/$plannerItemHomeworkPath/$id/'
              '${plannerItemDialogSteps.first}';
        },
      ),
      GoRoute(
        path: '$plannerItemHomeworkPath/:id/:step',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final step = state.pathParameters['step'];
          if (step == null || !plannerItemDialogSteps.contains(step)) {
            final id = state.pathParameters['id'] ?? 'new';
            final shellPath = _plannerItemShellPath(
              state.matchedLocation,
              plannerItemHomeworkPath,
            );
            return '$shellPath/$plannerItemHomeworkPath/$id/'
                '${plannerItemDialogSteps.first}';
          }
          return null;
        },
        pageBuilder: (context, state) => _plannerItemDialogPage(
          context,
          state,
          isHomework: true,
        ),
      ),
      GoRoute(
        path: '$plannerItemEventPath/:id',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          final shellPath = _plannerItemShellPath(
            state.matchedLocation,
            plannerItemEventPath,
          );
          if (id == null) return shellPath;
          return '$shellPath/$plannerItemEventPath/$id/'
              '${plannerItemDialogSteps.first}';
        },
      ),
      GoRoute(
        path: '$plannerItemEventPath/:id/:step',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final step = state.pathParameters['step'];
          if (step == null || !plannerItemDialogSteps.contains(step)) {
            final id = state.pathParameters['id'] ?? 'new';
            final shellPath = _plannerItemShellPath(
              state.matchedLocation,
              plannerItemEventPath,
            );
            return '$shellPath/$plannerItemEventPath/$id/'
                '${plannerItemDialogSteps.first}';
          }
          return null;
        },
        pageBuilder: (context, state) => _plannerItemDialogPage(
          context,
          state,
          isHomework: false,
        ),
      ),
    ];

/// Strips the trailing `/<entityPath>[/...]` off [matched] to recover the
/// underlying shell path (e.g. `/planner`, `/notebook`). The pageBuilder's
/// state is authoritative for the active route; the global router config
/// can lag for overlay routes.
String _plannerItemShellPath(String matched, String entityPath) {
  final marker = '/$entityPath/';
  final idx = matched.indexOf(marker);
  if (idx > 0) return matched.substring(0, idx);
  return AppRoute.plannerScreen;
}

Page<dynamic> _plannerItemDialogPage(
  BuildContext context,
  GoRouterState state, {
  required bool isHomework,
}) {
  final entityPath =
      isHomework ? plannerItemHomeworkPath : plannerItemEventPath;
  final idParam = state.pathParameters['id'] ?? 'new';
  final stepParam =
      state.pathParameters['step'] ?? plannerItemDialogSteps.first;
  final parsedId = DeepLinkParam.parseId(idParam);
  final extra = state.extra;
  final dialogExtra =
      extra is PlannerItemDialogExtra ? extra : null;
  final shellPath = _plannerItemShellPath(state.matchedLocation, entityPath);
  final useCompact = Responsive.useCompactLayout(context);

  return responsiveDialogPage(
    context,
    state,
    key: _plannerItemDialogPageKey,
    child: PlannerItemAddScreen(
      shellPath: shellPath,
      isHomework: isHomework,
      entityId: parsedId.id,
      isNew: parsedId.isNew,
      initialStepName: stepParam,
      initialFullPath: state.uri.toString(),
      initialDate: dialogExtra?.initialDate,
      isFromMonthView: dialogExtra?.isFromMonthView ?? false,
    ),
    width: useCompact ? double.infinity : AppConstants.centeredDialogWidth,
    insetPadding: useCompact ? EdgeInsets.zero : const EdgeInsets.all(16),
    alignment: Alignment.center,
  );
}

/// Typed payload riding alongside an imperative push to the planner item
/// editor route. Carries the create-flow context (initial date, calendar
/// origin) without exposing it in the URL. Survives in-app pushes/gos but
/// not browser refresh — deep-link edits don't need this since the URL
/// already identifies the entity.
class PlannerItemDialogExtra {
  final DateTime? initialDate;
  final bool isFromMonthView;

  const PlannerItemDialogExtra({
    this.initialDate,
    this.isFromMonthView = false,
  });
}

/// Auth redirect logic for go_router
Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  // Intercept URL-driven dismissals (browser back, address-bar edits) of a
  // dirty path-based dialog. [DirtyDialogRegistry.guard] reverts the URL
  // to the dialog and queues the discard prompt; on Discard, the original
  // navigation is replayed.
  final dirtyRevert = DirtyDialogRegistry.guard(state.uri.path);
  if (dirtyRevert != null) return dirtyRevert;

  if (_shouldShowMobileWebPrompt(context, state)) {
    if (state.matchedLocation != AppRoute.mobileWebScreen) {
      final encodedNext = Uri.encodeComponent(state.uri.toString());
      return '${AppRoute.mobileWebScreen}?next=$encodedNext';
    }
    return null;
  }

  final token = await PrefService().getSecure('access_token');
  final isLoggedIn = token?.isNotEmpty ?? false;
  // Note: setupAccountScreen is intentionally excluded — it requires an
  // authenticated session. Unauthenticated access is caught by the !isLoggedIn
  // guard below; authenticated users on public routes are redirected to setup
  // or planner by the publicRoutes check further down. Adding setup here would
  // bypass the !isLoggedIn guard and expose the screen to unauthenticated users.
  final publicRoutes = [
    AppRoute.landingScreen,
    AppRoute.signinScreen,
    AppRoute.signupScreen,
    AppRoute.loginScreen,
    AppRoute.registerScreen,
    AppRoute.forgotPasswordScreen,
    AppRoute.verifyEmailScreen,
    AppRoute.mobileWebScreen,
  ];

  final matchedLocation = state.matchedLocation;

  // If not logged in and trying to access protected route, redirect to login
  if (!isLoggedIn && !publicRoutes.contains(matchedLocation)) {
    // Pass intended destination as ?next param for redirect after login
    final intendedUrl = state.uri.toString();
    final encodedNext = Uri.encodeComponent(intendedUrl);
    return '${AppRoute.signinScreen}?next=$encodedNext';
  }

  // If logged in, check setup status for routing
  if (isLoggedIn) {
    try {
      await DioClient().fetchSettings();
    } on DioException catch (e) {
      // On web, a 401 --> refresh --> 403 path can escape fetchSettings()'s own
      // try-catch due to async zone isolation. Treat auth failures here as
      // "session gone" and redirect to login rather than letting the exception
      // propagate into GoRouter (which wraps it as a GoException).
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await DioClient().clearStorage();
        return AppRoute.signinScreen;
      }
      rethrow;
    }

    final isSetupComplete = PrefService().getBool(SettingsPrefKey.isSetupComplete.key);

    // Defensive fallback: if setup state is temporarily unavailable
    // (e.g. first load during API blip), avoid forcing a redirect.
    if (isSetupComplete == null) {
      _log.warning(
        'Setup completion flag unavailable during auth redirect '
        '(location=$matchedLocation), skipping setup-based redirect',
      );
      unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.debugAuthNoSetupState, parameters: {'category': AnalyticsCategory.edgeCase.value}));
      unawaited(Sentry.captureMessage('Auth redirect skipped setup-based redirect: setup state unavailable at location=$matchedLocation', level: SentryLevel.error));
      return null;
    }

    // On public routes: redirect to setup or planner based on setup status
    // Exception: verify screen should always be accessible (for email change verification)
    if (publicRoutes.contains(matchedLocation) &&
        matchedLocation != AppRoute.verifyEmailScreen) {
      return isSetupComplete
          ? AppRoute.plannerScreen
          : AppRoute.setupAccountScreen;
    }

    // On setup screen: redirect to planner if setup is complete
    if (matchedLocation == AppRoute.setupAccountScreen && isSetupComplete) {
      return AppRoute.plannerScreen;
    }

  }

  return null;
}

bool _shouldShowMobileWebPrompt(BuildContext context, GoRouterState state) {
  if (!kIsWeb) return false;

  final hasBypassedPrompt =
      PrefService().getBool('mobile_web_continue') ?? false;
  if (hasBypassedPrompt) return false;

  return kDebugMode
      ? MediaQuery.maybeOf(context) != null && Responsive.isMobile(context)
      : Responsive.isIOSPlatform() || Responsive.isAndroidPlatform();
}

/// Widget that redirects to a fallback route when arguments are missing
class _RouteRedirect extends StatelessWidget {
  final String redirectTo;

  const _RouteRedirect({required this.redirectTo});

  @override
  Widget build(BuildContext context) {
    // Defer navigation so context.go is not called during a build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      context.go(redirectTo);
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
