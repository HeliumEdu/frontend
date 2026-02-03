// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/firebase_options.dart';
import 'package:heliumapp/helium_app.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  // Only print logs in debug mode; rely on Sentry in release
  if (kDebugMode) {
    // Use --dart-define=LOG_LEVEL=FINE to set a log level in development
    const logLevelName = String.fromEnvironment('LOG_LEVEL', defaultValue: 'INFO');
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == logLevelName.toUpperCase(),
      orElse: () => Level.INFO,
    );

    Logger.root.onRecord.listen((record) {
      final String colorCode;
      if (record.level >= Level.SHOUT) {
        colorCode = '\x1B[31m'; // Dark red
      } else if (record.level >= Level.SEVERE) {
        colorCode = '\x1B[91m'; // Light red
      } else if (record.level >= Level.WARNING) {
        colorCode = '\x1B[33m'; // Yellow
      } else if (record.level >= Level.INFO) {
        colorCode = '\x1B[36m'; // Cyan
      } else {
        colorCode = '\x1B[90m'; // Grey
      }
      const resetCode = '\x1B[0m';

      // ignore: avoid_print
      print(
        '$colorCode${record.level.name}$resetCode: ${record.time}: [${record.loggerName}] ${record.message}',
      );
      if (record.error != null) {
        // ignore: avoid_print
        print('${colorCode}Error$resetCode: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('${colorCode}Stack Trace:$resetCode\n${record.stackTrace}');
      }
    });
  } else {
    await SentryFlutter.init((options) {
      options.dsn =
          'https://d6522731f64a56983e3504ed78390601@o4510767194570752.ingest.us.sentry.io/4510767197519872';
    });
  }

  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FcmService().init();

  await PrefService().init();

  usePathUrlStrategy();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final DioClient dioClient = DioClient();

  initializeRouter();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
            ),
            dioClient: dioClient,
          ),
        ),
      ],
      child: const HeliumApp(),
    ),
  );
}
