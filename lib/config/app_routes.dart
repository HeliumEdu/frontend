// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/material_remote_data_source.dart';
import 'package:heliumapp/data/repositories/material_repository_impl.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/views/auth/forgot_password_screen.dart';
import 'package:heliumapp/presentation/views/auth/login_screen.dart';
import 'package:heliumapp/presentation/views/auth/register_screen.dart';
import 'package:heliumapp/presentation/views/calendar/assignment_add_reminder_screen.dart';
import 'package:heliumapp/presentation/views/calendar/assignment_add_screen.dart';
import 'package:heliumapp/presentation/views/calendar/event_add_reminder_screen.dart';
import 'package:heliumapp/presentation/views/calendar/event_add_screen.dart';
import 'package:heliumapp/presentation/views/core/bottom_nav_bar_screen.dart';
import 'package:heliumapp/presentation/views/core/notification_screen.dart';
import 'package:heliumapp/presentation/views/core/splash_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_category_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_schedule_screen.dart';
import 'package:heliumapp/presentation/views/courses/course_add_screen.dart';
import 'package:heliumapp/presentation/views/materials/material_add_screen.dart';
import 'package:heliumapp/presentation/views/settings/change_password_screen.dart';
import 'package:heliumapp/presentation/views/settings/external_calendars_screen.dart';
import 'package:heliumapp/presentation/views/settings/feeds_screen.dart';
import 'package:heliumapp/presentation/views/settings/preferences_screen.dart';
import 'package:heliumapp/presentation/views/settings/settings_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
  static const String forgotPasswordScreen = '/forgot-password';
  static const String bottomNavBarScreen = '/nav-bar';
  static const String notificationScreen = '/notifications';
  static const String calendarAddAssignmentScreen = '/calendar/add-assignment';
  static const String calendarAddEventScreen = '/calendar/add-event';
  static const String calendarAddAssignmentReminderScreen =
      '/calendar/add-assignment/reminder';
  static const String calendarAddEventReminderScreen =
      '/calendar/add-event/reminder';
  static const String coursesAddScreen = '/classes/add';
  static const String courseAddScheduleScreen = '/classes/add/schedule';
  static const String courseAddCategoryScreen = '/classes/add/category';
  static const String materialsAddScreen = '/materials/add';
  static const String settingScreen = '/settings';
  static const String preferencesScreen = '/settings/preference';
  static const String feedsScreen = '/settings/feeds';
  static const String externalCalendarsScreen = '/settings/external-calendars';
  static const String changePasswordScreen = '/settings/change-password';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Unauthenticated routes
      splashScreen: (context) => const SplashScreen(),
      loginScreen: (context) => const LoginScreen(),
      registerScreen: (context) => const RegisterScreen(),
      forgotPasswordScreen: (context) => ForgotPasswordScreen(),
      // Authenticated routes
      bottomNavBarScreen: (context) => BottomNavBarScreen(),
      notificationScreen: (context) => NotificationScreen(),
      calendarAddAssignmentScreen: (context) => const AssignmentAddScreen(),
      calendarAddEventScreen: (context) => const EventAddScreen(),
      calendarAddAssignmentReminderScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return AssignmentAddReminderScreen(
          homeworkId: args?['homeworkId'],
          groupId: args?['groupId'],
          courseId: args?['courseId'],
          isEditMode: args?['isEditMode'],
        );
      },
      calendarAddEventReminderScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return EventAddReminderScreen(eventRequest: args?['eventRequest']);
      },
      coursesAddScreen: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;

        // Handle both int (create) and Map (edit) arguments
        if (args is int) {
          return CourseAddScreen(courseGroupId: args);
        } else if (args is Map<String, dynamic>) {
          return CourseAddScreen(
            courseGroupId: args['courseGroupId'] as int,
            courseId: args['courseId'] as int?,
            isEdit: args['isEdit'] as bool? ?? false,
          );
        } else {
          return CourseAddScreen(courseGroupId: 0);
        }
      },
      courseAddScheduleScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CourseAddScheduleScreen(
          courseId: args?['courseId'] ?? 0,
          courseGroupId: args?['courseGroupId'] ?? 0,
          isEdit: args?['isEdit'] as bool? ?? false,
        );
      },
      courseAddCategoryScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CourseAddCategoryScreen(
          courseId: args?['courseId'] ?? 0,
          courseGroupId: args?['courseGroupId'] ?? 0,
          isEdit: args?['isEdit'] as bool? ?? false,
        );
      },
      materialsAddScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args == null || args['materialGroup'] == null) {
          return Scaffold(
            body: Center(child: Text('Error: Material group is required')),
          );
        }

        // Safely cast courses list
        final coursesList = args['courses'] as List<dynamic>?;
        final typedCourses =
            coursesList?.map((e) => e as Map<String, dynamic>).toList() ??
            <Map<String, dynamic>>[];

        final existingMaterial = args['existingMaterial'];

        return BlocProvider(
          create: (context) => MaterialBloc(
            materialRepository: MaterialRepositoryImpl(
              remoteDataSource: MaterialRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          ),
          child: MaterialsAddScreen(
            materialGroup: args['materialGroup'],
            courses: typedCourses,
            existingMaterial: existingMaterial,
          ),
        );
      },
      settingScreen: (context) => SettingsScreen(),
      preferencesScreen: (context) => PreferencesScreen(),
      feedsScreen: (context) => const FeedsSettingsScreen(),
      externalCalendarsScreen: (context) =>
          const ExternalCalendarsSettingsScreen(),
      changePasswordScreen: (context) => ChangePasswordScreen(),
    };
  }
}
