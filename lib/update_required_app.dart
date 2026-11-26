import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/feedback/update_required_card.dart';
import 'package:heliumapp/utils/locale_helpers.dart';

/// Replaces the routed app when the installed build is below the backend's
/// minimum supported version, so no router or redirect runs on it.
class UpdateRequiredApp extends StatelessWidget {
  const UpdateRequiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionService().reduceMotion;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(reduceMotion: reduceMotion),
      darkTheme: AppTheme.dark(reduceMotion: reduceMotion),
      themeMode: ThemeMode.system,
      locale: LocaleNotifier().appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: HeliumLocale.resolve,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: UpdateRequiredCard(expanded: false),
          ),
        ),
      ),
    );
  }
}
