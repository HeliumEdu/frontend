// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/presentation/core/views/landing_screen.dart';
import 'package:heliumapp/presentation/core/views/mobile_web_screen.dart';
import 'package:heliumapp/presentation/core/views/notification_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/forgot_password_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/login_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/setup_account_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/signup_screen.dart';
import 'package:heliumapp/presentation/features/auth/views/verify_email_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/settings_screen.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();
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
        path: AppRoute.loginScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoute.signupScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SignupScreen()),
      ),
      GoRoute(
        path: AppRoute.forgotPasswordScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoute.verifyEmailScreen,
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'];
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

      // Main app shell (tab navigation)
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: AppRoute.plannerScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.planner),
            ),
          ),
          GoRoute(
            path: AppRoute.notebookScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.notes),
            ),
          ),
          GoRoute(
            path: AppRoute.coursesScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.courses),
            ),
          ),
          GoRoute(
            path: AppRoute.resourcesScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.resources),
            ),
          ),
          GoRoute(
            path: AppRoute.gradesScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.grades),
            ),
          ),
        ],
      ),

      // Protected full-screen routes (outside shell)
      GoRoute(
        path: AppRoute.notificationsScreen,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: NotificationsScreen(),
        ),
      ),

      // Settings routes
      GoRoute(
        path: AppRoute.settingScreen,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SettingsScreen()),
      ),
    ],
  );
}

/// Auth redirect logic for go_router
Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  if (_shouldShowMobileWebPrompt(context, state)) {
    if (state.matchedLocation != AppRoute.mobileWebScreen) {
      final encodedNext = Uri.encodeComponent(state.uri.toString());
      return '${AppRoute.mobileWebScreen}?next=$encodedNext';
    }
    return null;
  }

  final token = await PrefService().getSecure('access_token');
  final isLoggedIn = token?.isNotEmpty ?? false;
  final publicRoutes = [
    AppRoute.landingScreen,
    AppRoute.loginScreen,
    AppRoute.signupScreen,
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
    return '${AppRoute.loginScreen}?next=$encodedNext';
  }

  // If logged in, check setup status for routing
  if (isLoggedIn) {
    try {
      await DioClient().fetchSettings();
    } on DioException catch (e) {
      // On web, a 401→refresh→403 path can escape fetchSettings()'s own
      // try-catch due to async zone isolation. Treat auth failures here as
      // "session gone" and redirect to login rather than letting the exception
      // propagate into GoRouter (which wraps it as a GoException).
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await DioClient().clearStorage();
        return AppRoute.loginScreen;
      }
      rethrow;
    }

    final isSetupComplete = PrefService().getBool('is_setup_complete');

    // Defensive fallback: if setup state is temporarily unavailable
    // (e.g. first load during API blip), avoid forcing a redirect.
    if (isSetupComplete == null) {
      _log.warning(
        'Setup completion flag unavailable during auth redirect '
        '(location=$matchedLocation), skipping setup-based redirect',
      );
      AnalyticsService().logEvent(name: 'router_auth_redirect_no_setup_state', parameters: {'category': 'edge_case'});
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

    // /settings and /notifications are opened via showSettings()/showNotifications()
    // in-app. Direct URL access redirects to the shell route with query params,
    // where _openFromQueryParams() handles opening them.
    if (matchedLocation == AppRoute.settingScreen) {
      final tabParam = state.uri.queryParameters[DeepLinkParam.tab];
      final params = <String, String>{
        DeepLinkParam.dialog: DeepLinkParam.dialogSettings,
      };
      if (tabParam != null) params[DeepLinkParam.tab] = tabParam;
      return Uri(
        path: AppRoute.plannerScreen,
        queryParameters: params,
      ).toString();
    }

    if (matchedLocation == AppRoute.notificationsScreen) {
      final homeworkIdParam =
          state.uri.queryParameters[DeepLinkParam.homeworkId];
      final eventIdParam = state.uri.queryParameters[DeepLinkParam.eventId];
      if (homeworkIdParam != null) {
        return Uri(
          path: AppRoute.plannerScreen,
          queryParameters: {DeepLinkParam.homeworkId: homeworkIdParam},
        ).toString();
      }
      if (eventIdParam != null) {
        return Uri(
          path: AppRoute.plannerScreen,
          queryParameters: {DeepLinkParam.eventId: eventIdParam},
        ).toString();
      }
      return Uri(
        path: AppRoute.plannerScreen,
        queryParameters: {
          DeepLinkParam.dialog: DeepLinkParam.dialogNotifications,
        },
      ).toString();
    }
  }

  return null;
}

bool _shouldShowMobileWebPrompt(BuildContext context, GoRouterState state) {
  if (!kIsWeb) return false;

  final hasBypassedPrompt =
      PrefService().getBool('mobile_web_continue') ?? false;
  if (hasBypassedPrompt) return false;

  final isMobileWebPlatform = kDebugMode
      ? MediaQuery.maybeOf(context) != null && Responsive.isMobile(context)
      : Responsive.isIOSPlatform() || Responsive.isAndroidPlatform();
  if (!isMobileWebPlatform) return false;

  final requestedPath = state.matchedLocation;
  if (requestedPath == AppRoute.mobileWebScreen) return true;

  return true;
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
