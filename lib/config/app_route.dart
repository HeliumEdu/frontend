import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/material_remote_data_source.dart';
import 'package:helium_student_flutter/data/repositories/material_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/materialBloc/material_bloc.dart';
import 'package:helium_student_flutter/presentation/views/authScreen/forgotPassword/forgot_password_screen.dart';
import 'package:helium_student_flutter/presentation/views/authScreen/signInScreen/sign_in_screen.dart';
import 'package:helium_student_flutter/presentation/views/authScreen/signupScreen/sign_up_screen.dart';
import 'package:helium_student_flutter/presentation/views/bottomNavBar/bottom_nav_bar_screen.dart';
import 'package:helium_student_flutter/presentation/views/classesScreen/add_classes_screen.dart';
import 'package:helium_student_flutter/presentation/views/classesScreen/categories_add_class.dart';
import 'package:helium_student_flutter/presentation/views/classesScreen/classes_screen.dart';
import 'package:helium_student_flutter/presentation/views/classesScreen/schedule_add_class.dart';
import 'package:helium_student_flutter/presentation/views/gradeScreen/grades_screen.dart';
import 'package:helium_student_flutter/presentation/views/homeScreen/assignmentScreen/add_assignment_screen.dart';
import 'package:helium_student_flutter/presentation/views/homeScreen/assignmentScreen/assignment_reminder_screen.dart';
import 'package:helium_student_flutter/presentation/views/homeScreen/eventScreen/add_event_screen.dart';
import 'package:helium_student_flutter/presentation/views/homeScreen/eventScreen/event_reminder_screen.dart';
import 'package:helium_student_flutter/presentation/views/homeScreen/home_screen.dart';
import 'package:helium_student_flutter/presentation/views/materialScreen/add_material_screen.dart';
import 'package:helium_student_flutter/presentation/views/materialScreen/material_screen.dart';
import 'package:helium_student_flutter/presentation/views/authScreen/otpScreen/otp_verification_screen.dart';
import 'package:helium_student_flutter/presentation/views/settingScreen/change_password_screen.dart';
import 'package:helium_student_flutter/presentation/views/settingScreen/notification_screen.dart';
import 'package:helium_student_flutter/presentation/views/settingScreen/preference_screen.dart';
import 'package:helium_student_flutter/presentation/views/settingScreen/setting_screen.dart';
import 'package:helium_student_flutter/presentation/views/settingScreen/feed_settings_screen.dart';
import 'package:helium_student_flutter/presentation/views/splashScreen/splash_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splashScreen';
  static const String homeScreen = '/homeScreen';
  static const String classesScreen = '/classesScreen';
  static const String materialScreen = '/materialScreen';
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
  static const String otpVerificationScreen = '/otpVerificationScreen';
  static const String forgotPasswordScreen = '/forgotPasswordScreen';
  static const String scheduleAddClass = '/scheduleAddClass';
  static const String categoriesAddClass = '/categoriesAddClass';
  static const String addAssignmentScreen = '/addAssignmentScreen';
  static const String addEventScreen = '/addEventScreen';
  static const String remainderScreen = '/remainderScreen';
  static const String eventRemainderScreen = '/eventRemainderScreen';
  static const String feedSettingsScreen = '/feedSettingsScreen';
  static const String addAssignmentEvent = '/addAssignmentEvent';
  // static const String notificationTestScreen = '/notificationTestScreen';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splashScreen: (context) => const SplashScreen(),
      homeScreen: (context) => const HomeScreen(),
      classesScreen: (context) => const ClassesScreen(),
      materialScreen: (context) => MaterialScreen(),
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
        return ScheduleAddClass(
          courseId: args?['courseId'] ?? 0,
          courseGroupId: args?['courseGroupId'] ?? 0,
          isEdit: args?['isEdit'] as bool? ?? false,
        );
      },
      categoriesAddClass: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CategoriesAddClass(
          courseId: args?['courseId'] ?? 0,
          courseGroupId: args?['courseGroupId'] ?? 0,
          isEdit: args?['isEdit'] as bool? ?? false,
        );
      },
      otpVerificationScreen: (context) {
        final phoneNumber =
            ModalRoute.of(context)?.settings.arguments as String;
        return OtpVerificationScreen(phoneNumber: phoneNumber);
      },

      addAssignmentScreen: (context) => const AddAssignmentScreen(),
      addEventScreen: (context) => const AddEventScreen(),
      remainderScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return ReminderScreen(
          homeworkId: args?['homeworkId'],
          groupId: args?['groupId'],
          courseId: args?['courseId'],
          isEditMode: args?['isEditMode'],
        );
      },
      eventRemainderScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return EventRemainderScreen(eventRequest: args?['eventRequest']);
      },
      feedSettingsScreen: (context) => const FeedSettingsScreen(),
      // notificationTestScreen: (context) => const NotificationTestScreen(),
    };
  }
}
