import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/unauthenticated_scaffold.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.views');

class SetupAccountScreen extends StatefulWidget {
  final bool autoDetectTimeZone;

  const SetupAccountScreen({super.key, this.autoDetectTimeZone = false});

  @override
  State<SetupAccountScreen> createState() => _SetupAccountScreenState();
}

class _SetupAccountScreenState extends BasePageScreenState<SetupAccountScreen> {
  @override
  String get screenTitle => '';

  Timer? _pollTimer;
  bool _isPolling = false;
  final Stopwatch _setupStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initializeSetupFlow();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget buildScaffold(BuildContext context) {
    return UnauthenticatedScaffold(
      showCard: false,
      child: buildMainArea(context),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Column(
      children: [
        Image.asset(AppAssets.logoImagePath, height: 90.0),

        const SizedBox(height: 50),

        const LoadingIndicator(size: 48, strokeWidth: 4, expanded: false),

        const SizedBox(height: 32),

        Text(
          'Getting things ready ...',
          style: AppStyles.standardBodyText(
            context,
          ).copyWith(fontSize: 18.0, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _startPolling() {
    _log.info('Starting setup status polling');
    _setupStopwatch.start();
    _checkSetupStatus();

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      _checkSetupStatus();
    });
  }

  Future<void> _initializeSetupFlow() async {
    await DioClient().clearSettings();
    await DioClient().cacheService.clearAll();

    try {
      await _updateDetectedSettings();
      await DioClient().startSetup();
    } catch (e) {
      _log.warning('Unexpected setup initialization error: ${e.runtimeType}');
    } finally {
      if (mounted) {
        _startPolling();
      }
    }
  }

  /// The time zone is detected only on the OAuth path; the signup form
  /// already captured it otherwise.
  Future<void> _updateDetectedSettings() async {
    try {
      final locale = PlatformDispatcher.instance.locale;
      final view = PlatformDispatcher.instance.views.firstOrNull;
      final alwaysUse24HourFormat = kIsWeb || view == null
          ? null
          : MediaQueryData.fromView(view).alwaysUse24HourFormat;

      await DioClient().updateSettings(
        UpdateSettingsRequestModel(
          timeZone: widget.autoDetectTimeZone
              ? HeliumDateTime.resolveTimeZone((await FlutterTimezone.getLocalTimezone()).identifier)
              : null,
          weekStartsOn: await HeliumDateTime.detectWeekStartsOn(locale),
          dateFormat: await HeliumDateTime.detectDateFormat(locale),
          timeFormat: await HeliumDateTime.detectTimeFormat(
            locale,
            alwaysUse24HourFormat: alwaysUse24HourFormat,
          ),
          numberFormat: HeliumNumber.detectNumberFormat(locale),
        ),
      );
      _log.info('Updated detected settings from setup flow');
    } catch (e) {
      _log.warning('Failed to auto-detect or update settings: ${e.runtimeType}');
    }
  }

  Future<void> _checkSetupStatus() async {
    if (_isPolling) return;
    _isPolling = true;

    if (_setupStopwatch.elapsed > const Duration(seconds: 30)) {
      _pollTimer?.cancel();
      _setupStopwatch.stop();
      _log.warning('Setup polling timed out after 30 seconds');
      await DioClient().forceLogout('Please sign in again to continue.');
      return;
    }

    try {
      _log.info('Checking setup status ...');

      final settings = await DioClient().getSettings(forceRefresh: true);

      if (settings != null && settings.isSetupComplete) {
        _log.info('... setup complete, navigating to planner');
        _pollTimer?.cancel();

        if (mounted) {
          context.replace(AppRoute.plannerScreen);
        }
      } else {
        _log.info('--> Setup not yet complete, continuing to poll');
      }
    } catch (e) {
      _log.warning('Error checking setup status: ${e.runtimeType}');
    } finally {
      _isPolling = false;
    }
  }
}
