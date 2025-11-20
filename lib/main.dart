import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/config/route_observer.dart';
import 'package:heliumedu/presentation/bloc/bottombarBloc/bottom_bar_bloc.dart';
import 'package:heliumedu/presentation/bloc/notificationBloc/notification_bloc.dart';
import 'package:heliumedu/core/fcm_service.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Firebase.initializeApp();

  // Initialize FCM Service
  final fcmService = FCMService();
  await fcmService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(MyApp(fcmService: fcmService));
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final FCMService fcmService;

  const MyApp({super.key, required this.fcmService});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => BottomNavigationBloc()),
            BlocProvider(
              create: (context) => NotificationBloc(fcmService: fcmService),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Helium',
            theme: ThemeData(
              scaffoldBackgroundColor: whiteColor,
              primaryColor: primaryColor,
              progressIndicatorTheme: const ProgressIndicatorThemeData(
                color: primaryColor,
                circularTrackColor: primaryColor,
              ),
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: primaryColor,
                selectionColor: primaryColor,
                selectionHandleColor: primaryColor,
              ),
            ),
            navigatorObservers: [routeObserver],
            initialRoute: AppRoutes.splashScreen,
            routes: AppRoutes.getRoutes(),
          ),
        );
      },
    );
  }
}
