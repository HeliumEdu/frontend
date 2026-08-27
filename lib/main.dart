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
import 'package:heliumapp/core/app_version_service.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/core/feedback_service.dart';
import 'package:heliumapp/core/log_service.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:heliumapp/core/system_proxy_io.dart'
    if (dart.library.js_interop) 'package:heliumapp/core/system_proxy_stub.dart';
import 'package:heliumapp/firebase_environment.dart';
import 'package:heliumapp/helium_app.dart';
import 'package:heliumapp/utils/web_helpers_stub.dart'
    if (dart.library.js_interop) 'package:heliumapp/utils/web_helpers_web.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

final _log = Logger('main');

void main() async {
  // Must be called before WidgetsFlutterBinding.ensureInitialized() — Flutter
  // web locks the URL strategy during binding initialization.
  usePathUrlStrategy();

  // Initialize logging (log level can be set via --dart-define=LOG_LEVEL=FINE)
  // In release mode, also initialize Sentry for error reporting
  LogService().init();

  try {
    await SentryService().run(_bootstrap);
  } catch (e) {
    _log.severe('Sentry initialization failed', e);
    await _bootstrap();
  }
}

var _bootstrapped = false;

Future<void> _bootstrap() async {
  // Sentry throwing after it hands off must not start the app twice.
  if (_bootstrapped) return;
  _bootstrapped = true;

  // First thing initialized, and inside the runner: a binding initialized
  // outside the app's zone routes its callbacks' errors to the wrong one.
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  tz.initializeTimeZones();

  await refreshSystemProxy();

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
  } catch (e, s) {
    _log.severe('Analytics initialization failed', e, s);
  }

  initializeRouter();

  FcmService.setForegroundTapCallback((route) {
    router.go(route);
  });

  await PrefService().init();

  await AppVersionService().init();

  final accessibilityFeatures = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
  MotionService().init(
    accessibilityFeatures.disableAnimations || accessibilityFeatures.reduceMotion || getSystemReduceMotion(),
  );

  try {
    await FeedbackService().init();
  } catch (e) {
    _log.severe('FeedbackService initialization failed', e);
  }

  // FCM registration reaches the network, so it runs after the first frame:
  // on a slow or absent connection it would otherwise hold the app on a blank
  // screen. Pending notification navigation follows once it settles.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await FcmService().init();
    } catch (e, s) {
      _log.severe('FCM initialization failed', e, s);
    }
    FcmService.handlePendingRoute();
  });

  runApp(SentryWidget(child: const AppProviders(child: HeliumApp())));
}
