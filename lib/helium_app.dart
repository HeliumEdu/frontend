import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/utils/print_service.dart';
import 'package:heliumapp/utils/web_helpers_stub.dart'
    if (dart.library.js_interop) 'package:heliumapp/utils/web_helpers_web.dart';
import 'package:heliumapp/utils/quill_helpers.dart';
import 'package:heliumapp/utils/sf_calendar_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/app_version_service.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:heliumapp/update_required_app.dart';
import 'package:heliumapp/utils/version_helpers.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';


final _log = Logger('app');

class HeliumApp extends StatefulWidget {
  const HeliumApp({super.key});

  @override
  State<HeliumApp> createState() => _HeliumAppState();
}

class _HeliumAppState extends State<HeliumApp> with WidgetsBindingObserver {
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.addListener(_onThemeChanged);
    if (PrintService.isSupported) HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final features = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
      MotionService().init(
        features.disableAnimations || features.reduceMotion || getSystemReduceMotion(),
      );
      setState(() {});
    });
    _log.info('HeliumApp initialized with theme: ${_themeNotifier.themeMode}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeNotifier.removeListener(_onThemeChanged);
    if (PrintService.isSupported) HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  // Dismiss any in-app browser left on top when a Universal/App Link
  // re-enters the app from SFSafariVC / Custom Tabs. Mobile-only: web and
  // desktop url_launcher implementations don't implement closeWebView and
  // would throw on every URL change.
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    if (_isMobile) unawaited(closeInAppWebView());
    return false;
  }

  @override
  Future<bool> didPushRoute(String route) async {
    if (_isMobile) unawaited(closeInAppWebView());
    return false;
  }

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  void _onThemeChanged() {
    setState(() {});
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final isPrint = event.logicalKey == LogicalKeyboardKey.keyP &&
        (HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed);
    if (!isPrint) return false;
    if (PrintService().hasHandler) {
      FocusManager.instance.primaryFocus?.unfocus();
      _handlePrint();
    } else if (kIsWeb) {
      // Call synchronously within the key event to satisfy the browser's
      // user-activation requirement; async delay would cause it to be blocked.
      unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.printPreview, parameters: {'category': AnalyticsCategory.featureInteraction.value}));
      triggerBrowserPrint();
    }
    return true;
  }

  Future<void> _handlePrint() async {
    final printed = await PrintService().printCurrent();
    if (printed) {
      unawaited(AnalyticsService().logEvent(name: AnalyticsEvent.printPreview, parameters: {'category': AnalyticsCategory.featureInteraction.value}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfoBloc, InfoState>(
      buildWhen: (previous, current) =>
          _updateRequired(previous) != _updateRequired(current),
      builder: (context, infoState) => _updateRequired(infoState)
          ? const UpdateRequiredApp()
          : _buildRoutedApp(context),
    );
  }

  bool _updateRequired(InfoState state) {
    final version = AppVersionService().version;
    return state is InfoLoaded &&
        version != null &&
        VersionHelpers.isBelow(version, state.info.minimumSupportedVersion);
  }

  Widget _buildRoutedApp(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(reduceMotion: MotionService().reduceMotion),
      darkTheme: AppTheme.dark(reduceMotion: MotionService().reduceMotion),
      themeMode: _themeNotifier.themeMode,
      localizationsDelegates: const [
        HeliumQuillLocalizationsDelegate(),
        HeliumSfLocalizationsDelegate(),
      ],
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
