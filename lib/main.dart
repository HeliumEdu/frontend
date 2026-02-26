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
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/core/log_service.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/firebase_environment.dart';
import 'package:heliumapp/helium_app.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz;

final _log = Logger('main');

void main() async {
  // Always ensure this is the first thing initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging (log level can be set via --dart-define=LOG_LEVEL=FINE)
  // In release mode, also initialize Sentry for error reporting
  LogService().init();
  if (!kDebugMode) {
    try {
      await SentryService().init();
    } catch (e) {
      _log.severe('Sentry initialization failed', e);
    }
  }

  GoogleFonts.config.allowRuntimeFetching = false;

  tz.initializeTimeZones();

  try {
    await Firebase.initializeApp(options: firebaseOptionsWithOverrides());
  } catch (e) {
    _log.severe('Firebase initialization failed', e);
  }

  try {
    await AnalyticsService().init();
  } catch (e) {
    _log.severe('Analytics initialization failed', e);
  }

  try {
    await FcmService().init();
  } catch (e) {
    _log.severe('FCM initialization failed', e);
  }

  await PrefService().init();

  usePathUrlStrategy();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final DioClient dioClient = DioClient();
  final providerHelpers = ProviderHelpers();

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
        BlocProvider<ExternalCalendarBloc>(
          create: providerHelpers.createExternalCalendarBloc(),
        ),
        BlocProvider<PlannerItemBloc>(
          create: providerHelpers.createPlannerItemBloc(),
        ),
      ],
      child: const HeliumApp(),
    ),
  );
}
