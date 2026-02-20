// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/route_args.dart';
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
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/views/course_add_screen.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/views/resource_add_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/change_password_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/external_calendars_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/feeds_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/preferences_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/settings_screen.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();
late final GoRouter router;

void initializeRouter() {
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
        pageBuilder: (context, state) {
          if (!Responsive.isMobile(context)) {
            return const MaterialPage(
              child: _RouteRedirect(
                redirectTo: AppRoute.plannerScreen,
                queryParams: {'dialog': 'notifications'},
              ),
            );
          }

          return MaterialPage(child: NotificationsScreen());
        },
      ),

      GoRoute(
        path: AppRoute.plannerItemAddScreen,
        pageBuilder: (context, state) {
          final args = state.extra as PlannerItemAddArgs?;
          if (args == null) {
            return const MaterialPage(
              child: _RouteRedirect(redirectTo: AppRoute.plannerScreen),
            );
          }
          return MaterialPage(
            child: BlocProvider<AttachmentBloc>.value(
              value: args.attachmentBloc,
              child: PlannerItemAddScreen(
                eventId: args.eventId,
                homeworkId: args.homeworkId,
                initialDate: args.initialDate,
                isFromMonthView: args.isFromMonthView,
                isEdit: args.isEdit,
                isNew: args.isNew,
              ),
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoute.courseAddScreen,
        pageBuilder: (context, state) {
          final courseIdParam = state.uri.queryParameters['id'];
          final stepParam = state.uri.queryParameters['step'];

          if (courseIdParam != null) {
            final queryParams = {'class': courseIdParam};
            if (stepParam != null) {
              queryParams['step'] = stepParam;
            }
            return MaterialPage(
              child: _RouteRedirect(
                redirectTo: AppRoute.coursesScreen,
                queryParams: queryParams,
              ),
            );
          }

          final args = state.extra as CourseAddArgs?;
          if (args == null) {
            return const MaterialPage(
              child: _RouteRedirect(redirectTo: AppRoute.coursesScreen),
            );
          }
          return MaterialPage(
            child: BlocProvider<CourseBloc>.value(
              value: args.courseBloc,
              child: CourseAddScreen(
                courseGroupId: args.courseGroupId,
                courseId: args.courseId,
                isEdit: args.isEdit,
                isNew: args.isNew,
                initialStep: args.initialStep,
              ),
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoute.resourcesAddScreen,
        pageBuilder: (context, state) {
          final args = state.extra as ResourceAddArgs?;
          if (args == null) {
            return const MaterialPage(
              child: _RouteRedirect(redirectTo: AppRoute.resourcesScreen),
            );
          }
          return MaterialPage(
            child: BlocProvider<ResourceBloc>.value(
              value: args.resourceBloc,
              child: ResourceAddScreen(
                resourceGroupId: args.resourceGroupId,
                resourceId: args.resourceId,
                isEdit: args.isEdit,
                isNew: !args.isEdit,
              ),
            ),
          );
        },
      ),

      // Settings routes
      GoRoute(
        path: AppRoute.settingScreen,
        pageBuilder: (context, state) {
          if (!Responsive.isMobile(context)) {
            return const MaterialPage(
              child: _RouteRedirect(
                redirectTo: AppRoute.plannerScreen,
                queryParams: {'dialog': 'settings'},
              ),
            );
          }

          return const MaterialPage(child: SettingsScreen());
        },
      ),
      GoRoute(
        path: AppRoute.preferencesScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: PreferencesScreen()),
      ),
      GoRoute(
        path: AppRoute.feedsScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: FeedsScreen()),
      ),
      GoRoute(
        path: AppRoute.externalCalendarsScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ExternalCalendarsScreen()),
      ),
      GoRoute(
        path: AppRoute.changePasswordScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ChangePasswordScreen()),
      ),
    ],
  );
}

/// Auth redirect logic for go_router.
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
    await DioClient().fetchSettings();

    final isSetupComplete = PrefService().getBool('is_setup_complete') ?? true;

    // On public routes: redirect to setup or planner based on setup status
    if (publicRoutes.contains(matchedLocation)) {
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

  final isMobileWebPlatform = kDebugMode
      ? MediaQuery.maybeOf(context) != null && Responsive.isMobile(context)
      : Responsive.isIOSPlatform() || Responsive.isAndroidPlatform();
  if (!isMobileWebPlatform) return false;

  final requestedPath = state.matchedLocation;
  if (requestedPath == AppRoute.mobileWebScreen) return true;

  return true;
}

/// Widget that redirects to a fallback route when arguments are missing.
class _RouteRedirect extends StatelessWidget {
  final String redirectTo;
  final Map<String, String>? queryParams;

  const _RouteRedirect({required this.redirectTo, this.queryParams});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      if (queryParams != null && queryParams!.isNotEmpty) {
        final uri = Uri.parse(redirectTo);
        final newUri = uri.replace(
          queryParameters: {...uri.queryParameters, ...queryParams!},
        );
        context.go(newUri.toString());
      } else {
        context.go(redirectTo);
      }
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
