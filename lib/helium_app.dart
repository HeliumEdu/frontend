// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/utils/print_service.dart';
import 'package:heliumapp/utils/web_helpers_stub.dart'
    if (dart.library.js_interop) 'package:heliumapp/utils/web_helpers_web.dart';
import 'package:heliumapp/utils/quill_helpers.dart';
import 'package:heliumapp/utils/sf_calendar_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:logging/logging.dart';

final _log = Logger('app');

class HeliumApp extends StatefulWidget {
  const HeliumApp({super.key});

  @override
  State<HeliumApp> createState() => _HeliumAppState();
}

class _HeliumAppState extends State<HeliumApp> {
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.addListener(_onThemeChanged);
    if (PrintService.isSupported) HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _log.info('HeliumApp initialized with theme: ${_themeNotifier.themeMode}');
  }

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    if (PrintService.isSupported) HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

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
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeNotifier.themeMode,
      localizationsDelegates: const [
        HeliumQuillLocalizationsDelegate(),
        HeliumSfLocalizationsDelegate(),
      ],
    );
  }
}
