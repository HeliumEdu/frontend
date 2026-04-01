// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:web/web.dart' as web;
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/utils/print_service.dart';
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
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _log.info('HeliumApp initialized with theme: ${_themeNotifier.themeMode}');
  }

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
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
    _handlePrint();
    return true;
  }

  Future<void> _handlePrint() async {
    final handled = await PrintService().printCurrent();
    if (!handled && kIsWeb) {
      web.window.print();
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
