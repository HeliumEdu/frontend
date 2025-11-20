import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/material_remote_data_source.dart';
import 'package:heliumedu/data/repositories/material_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/materialBloc/material_bloc.dart';
import 'package:heliumedu/presentation/views/authScreen/forgotPassword/forgot_password_screen.dart';
import 'package:heliumedu/presentation/views/authScreen/signInScreen/sign_in_screen.dart';
import 'package:heliumedu/presentation/views/authScreen/signupScreen/sign_up_screen.dart';
import 'package:heliumedu/presentation/views/bottomNavBar/bottom_nav_bar_screen.dart';
import 'package:heliumedu/presentation/views/classesScreen/add_classes_screen.dart';
import 'package:heliumedu/presentation/views/classesScreen/add_classes_categories_screen.dart';
import 'package:heliumedu/presentation/views/classesScreen/classes_screen.dart';
import 'package:heliumedu/presentation/views/classesScreen/add_classes_schedule_screen.dart';
import 'package:heliumedu/presentation/views/gradeScreen/grades_screen.dart';
import 'package:heliumedu/presentation/views/calendarScreen/assignmentScreen/add_assignment_screen.dart';
import 'package:heliumedu/presentation/views/calendarScreen/assignmentScreen/assignment_reminder_screen.dart';
import 'package:heliumedu/presentation/views/calendarScreen/eventScreen/add_event_screen.dart';
import 'package:heliumedu/presentation/views/calendarScreen/eventScreen/event_reminder_screen.dart';
import 'package:heliumedu/presentation/views/calendarScreen/calendar_screen.dart';
import 'package:heliumedu/presentation/views/materialsScreen/add_material_screen.dart';
import 'package:heliumedu/presentation/views/materialsScreen/materials_screen.dart';
import 'package:heliumedu/presentation/views/settingScreen/change_password_screen.dart';
import 'package:heliumedu/presentation/views/settingScreen/notification_screen.dart';
import 'package:heliumedu/presentation/views/settingScreen/preference_screen.dart';
import 'package:heliumedu/presentation/views/settingScreen/setting_screen.dart';
import 'package:heliumedu/presentation/views/settingScreen/feed_settings_screen.dart';
import 'package:heliumedu/presentation/views/splashScreen/splash_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splashScreen';
  static const String calendarScreen = '/calendarScreen';
  static const String classesScreen = '/classesScreen';
  static const String materialsScreen = '/materialsScreen';
  static const String gradesScreen = '/gradesScreen';
  static const String signInScreen = '/signInScreen';
  static const String signUpScreen = '/signUpScreen';
  static const String bottomNavBarScreen = '/bottomNavBarScreen';
  static const String addClassesScreen = '/addClassesScreen';
  static const String addMaterialScreen = '/addMaterialScreen';
  static const String settingScreen = '/settingScreen';
  static const String changePasswordScreen = '/changePasswordScreen';
  static const String preferenceScreen = '/preferenceScreen';
  static const String notificationScreen = '/notificationScreen';
  static const String forgotPasswordScreen = '/forgotPasswordScreen';
  static const String scheduleAddClass = '/scheduleAddClass';
  static const String categoriesAddClass = '/categoriesAddClass';
  static const String addAssignmentScreen = '/addAssignmentScreen';
  static const String addEventScreen = '/addEventScreen';
  static const String assignmentReminderScreen = '/assignmentReminderScreen';
  static const String eventReminderScreen = '/eventReminderScreen';
  static const String feedSettingsScreen = '/feedSettingsScreen';
  static const String addAssignmentEvent = '/addAssignmentEvent';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splashScreen: (context) => const SplashScreen(),
      calendarScreen: (context) => const HomeScreen(),
      classesScreen: (context) => const ClassesScreen(),
      materialsScreen: (context) => MaterialsScreen(),
      gradesScreen: (context) => const GradesScreen(),
      signInScreen: (context) => const SignInScreen(),
      signUpScreen: (context) => const SignUpScreen(),
      bottomNavBarScreen: (context) => const BottomNavBarScreen(),
      addClassesScreen: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;

        // Handle both int (create) and Map (edit) arguments
        if (args is int) {
          return AddClassesScreen(courseGroupId: args);
        } else if (args is Map<String, dynamic>) {
          return AddClassesScreen(
            courseGroupId: args['courseGroupId'] as int,
            courseId: args['courseId'] as int?,
            isEdit: args['isEdit'] as bool? ?? false,
          );
        } else {
          return AddClassesScreen(courseGroupId: 0);
        }
      },
      addMaterialScreen: (context) {
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
          child: AddMaterialScreen(
            materialGroup: args['materialGroup'],
            courses: typedCourses,
            existingMaterial: existingMaterial,
          ),
        );
      },
      settingScreen: (context) => SettingScreen(),
      changePasswordScreen: (context) => ChangePasswordScreen(),
      preferenceScreen: (context) => PreferenceScreen(),
      notificationScreen: (context) => NotificationScreen(),
      forgotPasswordScreen: (context) => ForgotPasswordScreen(),
      scheduleAddClass: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return AddClassesScheduleScreen(
          courseId: args?['courseId'] ?? 0,
          courseGroupId: args?['courseGroupId'] ?? 0,
          isEdit: args?['isEdit'] as bool? ?? false,
        );
      },
      categoriesAddClass: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return AddClassesCategoriesScreen(
          courseId: args?['courseId'] ?? 0,
          courseGroupId: args?['courseGroupId'] ?? 0,
          isEdit: args?['isEdit'] as bool? ?? false,
        );
      },

      addAssignmentScreen: (context) => const AddAssignmentScreen(),
      addEventScreen: (context) => const AddEventScreen(),
      assignmentReminderScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return AssignmentReminderScreen(
          homeworkId: args?['homeworkId'],
          groupId: args?['groupId'],
          courseId: args?['courseId'],
          isEditMode: args?['isEditMode'],
        );
      },
      eventReminderScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return EventReminderScreen(eventRequest: args?['eventRequest']);
      },
      feedSettingsScreen: (context) => const FeedSettingsScreen(),
      // notificationTestScreen: (context) => const NotificationTestScreen(),
    };
  }
}
