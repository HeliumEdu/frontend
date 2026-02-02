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
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/views/auth/forgot_password_screen.dart';
import 'package:heliumapp/presentation/views/auth/login_screen.dart';
import 'package:heliumapp/presentation/views/auth/register_screen.dart';
import 'package:heliumapp/presentation/views/auth/verify_screen.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_attachment_screen.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_reminder_screen.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_screen.dart';
import 'package:heliumapp/presentation/views/core/landing_screen.dart';
import 'package:heliumapp/presentation/views/core/navigation_shell.dart';
import 'package:heliumapp/presentation/views/core/notification_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_attachment_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_category_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_schedule_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_screen.dart';
import 'package:heliumapp/presentation/views/materials/material_add_screen.dart';
import 'package:heliumapp/presentation/views/settings/change_password_screen.dart';
import 'package:heliumapp/presentation/views/settings/external_calendars_screen.dart';
import 'package:heliumapp/presentation/views/settings/feeds_screen.dart';
import 'package:heliumapp/presentation/views/settings/preferences_screen.dart';
import 'package:heliumapp/presentation/views/settings/settings_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();
late final GoRouter router;

void initializeRouter() {
  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.landingScreen,
    redirect: _authRedirect,
    routes: [
      // Public routes (no shell)
      GoRoute(
        path: AppRoutes.landingScreen,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginScreen,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerScreen,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordScreen,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyScreen,
        builder: (context, state) {
          final args = state.extra as VerifyScreenArgs?;
          // Support both route args and query parameters (from email link)
          final username =
              args?.username ?? state.uri.queryParameters['username'];
          final code = args?.code ?? state.uri.queryParameters['code'];
          return VerifyScreen(username: username, code: code);
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
        builder: (context, state) {
          final args = state.extra as NotificationArgs?;
          if (args?.calendarItemBloc != null) {
            return BlocProvider<CalendarItemBloc>.value(
              value: args!.calendarItemBloc!,
              child: NotificationsScreen(),
            );
          }
          return BlocProvider<CalendarItemBloc>(
            create: ProviderHelpers().createCalendarItemBloc(),
            child: NotificationsScreen(),
          );
        },
      ),

      // Calendar item add flow
      GoRoute(
        path: AppRoutes.plannerItemAddScreen,
        builder: (context, state) {
          final args = state.extra as CalendarItemAddArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.plannerScreen);
          }
          return BlocProvider<CalendarItemBloc>.value(
            value: args.calendarItemBloc,
            child: CalendarItemAddProvidedScreen(
              eventId: args.eventId,
              homeworkId: args.homeworkId,
              initialDate: args.initialDate,
              isFromMonthView: args.isFromMonthView,
              isEdit: args.isEdit,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.plannerItemAddRemindersScreen,
        builder: (context, state) {
          final args = state.extra as CalendarItemReminderArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.plannerScreen);
          }
          return BlocProvider<CalendarItemBloc>.value(
            value: args.calendarItemBloc,
            child: CalendarItemAddReminderScreen(
              isEvent: args.isEvent,
              entityId: args.entityId,
              isEdit: args.isEdit,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.plannerItemAddAttachmentsScreen,
        builder: (context, state) {
          final args = state.extra as CalendarItemAttachmentArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.plannerScreen);
          }
          return BlocProvider<CalendarItemBloc>.value(
            value: args.calendarItemBloc,
            child: CalendarItemAddAttachmentScreen(
              isEvent: args.isEvent,
              entityId: args.entityId,
              isEdit: args.isEdit,
            ),
          );
        },
      ),

      // Course add flow
      GoRoute(
        path: AppRoutes.courseAddScreen,
        builder: (context, state) {
          final args = state.extra as CourseAddArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.coursesScreen);
          }
          return BlocProvider<CourseBloc>.value(
            value: args.courseBloc,
            child: CourseAddProvidedScreen(
              courseGroupId: args.courseGroupId,
              courseId: args.courseId,
              isEdit: args.isEdit,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.courseAddScheduleScreen,
        builder: (context, state) {
          final args = state.extra as CourseAddArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.coursesScreen);
          }
          return BlocProvider<CourseBloc>.value(
            value: args.courseBloc,
            child: CourseAddScheduleProvidedScreen(
              courseGroupId: args.courseGroupId,
              courseId: args.courseId!,
              isEdit: args.isEdit,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.courseAddCategoriesScreen,
        builder: (context, state) {
          final args = state.extra as CourseAddArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.coursesScreen);
          }
          return BlocProvider<CourseBloc>.value(
            value: args.courseBloc,
            child: CourseAddCategoryScreen(
              courseGroupId: args.courseGroupId,
              courseId: args.courseId!,
              isEdit: args.isEdit,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.courseAddAttachmentsScreen,
        builder: (context, state) {
          final args = state.extra as CourseAddArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.coursesScreen);
          }
          return BlocProvider<CourseBloc>.value(
            value: args.courseBloc,
            child: CourseAddAttachmentScreen(
              courseGroupId: args.courseGroupId,
              entityId: args.courseId!,
              isEdit: args.isEdit,
            ),
          );
        },
      ),

      // Material add flow
      GoRoute(
        path: AppRoutes.resourcesAddScreen,
        builder: (context, state) {
          final args = state.extra as MaterialAddArgs?;
          if (args == null) {
            return const _RouteRedirect(redirectTo: AppRoutes.resourcesScreen);
          }
          return BlocProvider<MaterialBloc>.value(
            value: args.materialBloc,
            child: MaterialAddProvidedScreen(
              materialGroupId: args.materialGroupId,
              materialId: args.materialId,
              isEdit: args.isEdit,
            ),
          );
        },
      ),

      // Settings routes
      GoRoute(
        path: AppRoutes.settingScreen,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.preferencesScreen,
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutes.feedsScreen,
        builder: (context, state) => const FeedsScreen(),
      ),
      GoRoute(
        path: AppRoutes.externalCalendarsScreen,
        builder: (context, state) => ExternalCalendarsScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePasswordScreen,
        builder: (context, state) => const ChangePasswordScreen(),
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
    return AppRoutes.plannerScreen;
  }

  return null;
}

/// Widget that redirects to a fallback route when arguments are missing.
class _RouteRedirect extends StatelessWidget {
  final String redirectTo;

  const _RouteRedirect({required this.redirectTo});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(redirectTo);
      }
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
