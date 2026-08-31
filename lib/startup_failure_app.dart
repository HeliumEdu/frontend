import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';

/// Stands in for `HeliumApp` when a hard startup dependency fails, so the app
/// reports it instead of hanging on the splash screen.
///
/// Depends only on what is available before `runApp`: no router, no providers,
/// and the system theme rather than the stored preference.
class StartupFailureApp extends StatelessWidget {
  final VoidCallback onReload;

  const StartupFailureApp({super.key, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionService().reduceMotion;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(reduceMotion: reduceMotion),
      darkTheme: AppTheme.dark(reduceMotion: reduceMotion),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: SafeArea(
          child: ErrorCard(
            message: HeliumException.unexpectedError,
            source: 'startup',
            expanded: false,
            onReload: onReload,
          ),
        ),
      ),
    );
  }
}
