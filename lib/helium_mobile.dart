// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/config/app_routes.dart';
import 'package:helium_mobile/config/app_prefs.dart';
import 'package:helium_mobile/config/route_observer.dart';
import 'package:helium_mobile/core/fcm_service.dart';
import 'package:helium_mobile/presentation/bloc/core/notification_bloc.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Firebase.initializeApp();

  await FcmService().init();

  await PrefService().init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(HeliumApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HeliumApp extends StatelessWidget {
  const HeliumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiBlocProvider(
          providers: [BlocProvider(create: (context) => NotificationBloc())],
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
