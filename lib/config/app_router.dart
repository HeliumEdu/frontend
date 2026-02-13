// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/views/auth/forgot_password_screen.dart';
import 'package:heliumapp/presentation/views/auth/login_screen.dart';
import 'package:heliumapp/presentation/views/auth/register_screen.dart';
import 'package:heliumapp/presentation/views/auth/verify_screen.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_screen.dart';
import 'package:heliumapp/presentation/views/core/landing_screen.dart';
import 'package:heliumapp/presentation/views/core/navigation_shell.dart';
import 'package:heliumapp/presentation/views/core/notification_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_screen.dart';
import 'package:heliumapp/presentation/views/materials/material_add_screen.dart';
import 'package:heliumapp/presentation/views/settings/change_password_screen.dart';
import 'package:heliumapp/presentation/views/settings/external_calendars_screen.dart';
import 'package:heliumapp/presentation/views/settings/feeds_screen.dart';
import 'package:heliumapp/presentation/views/settings/preferences_screen.dart';
import 'package:heliumapp/presentation/views/settings/settings_screen.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();
late final GoRouter router;

void initializeRouter() {
  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.landingScreen,
    redirect: _authRedirect,
    observers: [AnalyticsService().observer],
    errorBuilder: (context, state) => const _RouteRedirect(
      redirectTo: AppRoutes.plannerScreen,
    ),
    routes: [
      // Public routes (no shell)
      GoRoute(
        path: AppRoutes.landingScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LandingScreen()),
      ),
      GoRoute(
        path: AppRoutes.loginScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.registerScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.verifyScreen,
        pageBuilder: (context, state) {
          final username = state.uri.queryParameters['username'];
          final code = state.uri.queryParameters['code'];
          return MaterialPage(
            child: VerifyScreen(username: username, code: code),
          );
        },
      ),

      // Main app shell (tab navigation)
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.plannerScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.calendar),
            ),
          ),
          GoRoute(
            path: AppRoutes.coursesScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.courses),
            ),
          ),
          GoRoute(
            path: AppRoutes.resourcesScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.materials),
            ),
          ),
          GoRoute(
            path: AppRoutes.gradesScreen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NavigationShellContent(page: NavigationPage.grades),
            ),
          ),
        ],
      ),

      // Protected full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.notificationsScreen,
        pageBuilder: (context, state) {
          if (!Responsive.isMobile(context)) {
            return const MaterialPage(
              child: _RouteRedirect(
                redirectTo: AppRoutes.plannerScreen,
                queryParams: {'dialog': 'notifications'},
              ),
            );
          }

          final args = state.extra as NotificationArgs?;
          final child = (args?.calendarItemBloc != null)
              ? BlocProvider<CalendarItemBloc>.value(
                  value: args!.calendarItemBloc!,
                  child: NotificationsScreen(),
                )
              : BlocProvider<CalendarItemBloc>(
                  create: ProviderHelpers().createCalendarItemBloc(),
                  child: NotificationsScreen(),
                );
          return MaterialPage(child: child);
        },
      ),

      GoRoute(
        path: AppRoutes.plannerItemAddScreen,
        pageBuilder: (context, state) {
          final args = state.extra as CalendarItemAddArgs?;
          if (args == null) {
            return const MaterialPage(
              child: _RouteRedirect(redirectTo: AppRoutes.plannerScreen),
            );
          }
          return MaterialPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider<CalendarItemBloc>.value(
                  value: args.calendarItemBloc,
                ),
                BlocProvider<AttachmentBloc>.value(
                  value: args.attachmentBloc,
                ),
              ],
              child: CalendarItemAddScreen(
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
        path: AppRoutes.courseAddScreen,
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
                redirectTo: AppRoutes.coursesScreen,
                queryParams: queryParams,
              ),
            );
          }

          final args = state.extra as CourseAddArgs?;
          if (args == null) {
            return const MaterialPage(
              child: _RouteRedirect(redirectTo: AppRoutes.coursesScreen),
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
              ),
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.resourcesAddScreen,
        pageBuilder: (context, state) {
          final args = state.extra as MaterialAddArgs?;
          if (args == null) {
            return const MaterialPage(
              child: _RouteRedirect(redirectTo: AppRoutes.resourcesScreen),
            );
          }
          return MaterialPage(
            child: BlocProvider<MaterialBloc>.value(
              value: args.materialBloc,
              child: MaterialAddScreen(
                materialGroupId: args.materialGroupId,
                materialId: args.materialId,
                isEdit: args.isEdit,
                isNew: !args.isEdit,
              ),
            ),
          );
        },
      ),

      // Settings routes
      GoRoute(
        path: AppRoutes.settingScreen,
        pageBuilder: (context, state) {
          if (!Responsive.isMobile(context)) {
            return const MaterialPage(
              child: _RouteRedirect(
                redirectTo: AppRoutes.plannerScreen,
                queryParams: {'dialog': 'settings'},
              ),
            );
          }

          final args = state.extra as SettingsArgs?;
          final child = (args?.externalCalendarBloc != null)
              ? BlocProvider<ExternalCalendarBloc>.value(
                  value: args!.externalCalendarBloc!,
                  child: const SettingsScreen(),
                )
              : const SettingsScreen();
          return MaterialPage(child: child);
        },
      ),
      GoRoute(
        path: AppRoutes.preferencesScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: PreferencesScreen()),
      ),
      GoRoute(
        path: AppRoutes.feedsScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: FeedsScreen()),
      ),
      GoRoute(
        path: AppRoutes.externalCalendarsScreen,
        pageBuilder: (context, state) {
          final args = state.extra as ExternalCalendarsArgs?;
          final child = (args?.externalCalendarBloc != null)
              ? BlocProvider<ExternalCalendarBloc>.value(
                  value: args!.externalCalendarBloc!,
                  child: const ExternalCalendarsScreen(),
                )
              : const ExternalCalendarsScreen();
          return MaterialPage(child: child);
        },
      ),
      GoRoute(
        path: AppRoutes.changePasswordScreen,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ChangePasswordScreen()),
      ),
    ],
  );
}

/// Auth redirect logic for go_router.
Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  final token = await PrefService().getSecure('access_token');
  final isLoggedIn = token?.isNotEmpty ?? false;
  final publicRoutes = [
    AppRoutes.landingScreen,
    AppRoutes.loginScreen,
    AppRoutes.registerScreen,
    AppRoutes.forgotPasswordScreen,
    AppRoutes.verifyScreen,
  ];

  final matchedLocation = state.matchedLocation;

  // If not logged in and trying to access protected route, redirect to login
  if (!isLoggedIn && !publicRoutes.contains(matchedLocation)) {
    // Pass intended destination as ?next param for redirect after login
    final intendedUrl = state.uri.toString();
    final encodedNext = Uri.encodeComponent(intendedUrl);
    return '${AppRoutes.loginScreen}?next=$encodedNext';
  }

  // If logged in and trying to access a public route, redirect to calendar
  if (isLoggedIn && publicRoutes.contains(matchedLocation)) {
    await DioClient().fetchSettings();

    return AppRoutes.plannerScreen;
  }

  return null;
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
