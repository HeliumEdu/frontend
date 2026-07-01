// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/config/app_providers.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/core/feedback_service.dart';
import 'package:heliumapp/core/log_service.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:heliumapp/firebase_environment.dart';
import 'package:heliumapp/helium_app.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz;

final _log = Logger('main');

void main() async {
  // Must be called before WidgetsFlutterBinding.ensureInitialized() — Flutter
  // web locks the URL strategy during binding initialization.
  usePathUrlStrategy();

  // Always ensure this is the first thing initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging (log level can be set via --dart-define=LOG_LEVEL=FINE)
  // In release mode, also initialize Sentry for error reporting
  LogService().init();
  try {
    await SentryService().init();
  } catch (e) {
    _log.severe('Sentry initialization failed', e);
  }

  GoogleFonts.config.allowRuntimeFetching = false;

  tz.initializeTimeZones();

  try {
    await Firebase.initializeApp(options: firebaseOptionsWithOverrides());
  } catch (e) {
    _log.severe('Firebase initialization failed', e);
  }

  if (!kIsWeb) {
    FirebaseAuth.instance.customAuthDomain = firebaseAuthDomain;
  }

  try {
    await AnalyticsService().init();
  } catch (e) {
    _log.severe('Analytics initialization failed', e);
  }

  initializeRouter();

  try {
    await FcmService().init();
  } catch (e) {
    _log.severe('FCM initialization failed', e);
  }

  FcmService.setForegroundTapCallback((route) {
    router.go(route);
  });

  await PrefService().init();

  final accessibilityFeatures = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
  MotionService().init(
    accessibilityFeatures.disableAnimations || accessibilityFeatures.reduceMotion,
  );

  try {
    await FeedbackService().init();
  } catch (e) {
    _log.severe('FeedbackService initialization failed', e);
  }

  // Handle pending notification navigation after first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FcmService.handlePendingRoute();
  });

  runApp(const AppProviders(child: HeliumApp()));
}
