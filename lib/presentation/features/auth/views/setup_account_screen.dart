// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_center_card.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
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
  int _consecutiveStatusFailures = 0;

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
    return Title(
      title: AppConstants.appName,
      color: context.colorScheme.primary,
      child: Scaffold(body: SafeArea(child: buildMainArea(context))),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return ResponsiveCenterCard(
      showCard: false,
      child: Column(
        children: [
          Image.asset(AppAssets.logoImagePath, height: 120),

          const SizedBox(height: 50),

          const LoadingIndicator(size: 48, strokeWidth: 4, expanded: false),

          const SizedBox(height: 32),

          Text(
            'Getting things ready ...',
            style: AppStyles.standardBodyText(
              context,
            ).copyWith(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _startPolling() {
    _log.info('Starting setup status polling');
    _checkSetupStatus();

    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      _checkSetupStatus();
    });
  }

  Future<void> _initializeSetupFlow() async {
    try {
      if (widget.autoDetectTimeZone) {
        await _updateDetectedTimeZone();
      } else {
        _log.info(
          'Setup started from non-OAuth flow, skipping timezone auto-update',
        );
      }
    } catch (e) {
      _log.warning('Unexpected setup initialization error: $e');
    } finally {
      if (mounted) {
        _startPolling();
      }
    }
  }

  Future<void> _updateDetectedTimeZone() async {
    try {
      final detectedTimeZone =
          (await FlutterTimezone.getLocalTimezone()).identifier;

      await DioClient().updateSettings(
        UpdateSettingsRequestModel(timeZone: detectedTimeZone),
      );
      _log.info('Updated user timezone from setup flow');
    } catch (e) {
      _log.warning('Failed to auto-detect or update timezone: $e');
    }
  }

  Future<void> _checkSetupStatus() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      _log.info('Checking setup status ...');

      final settings = await DioClient().fetchSettings(forceRefresh: true);

      if (settings != null && settings.isSetupComplete) {
        _consecutiveStatusFailures = 0;
        _log.info('... setup complete, navigating to planner');
        _pollTimer?.cancel();

        if (mounted) {
          context.replace(AppRoute.plannerScreen);
        }
      } else if (settings == null) {
        await _handleTransientStatusFailure('Settings response was null');
      } else {
        _consecutiveStatusFailures = 0;
        _log.info('--> Setup not yet complete, continuing to poll');
      }
    } catch (e) {
      await _handleTransientStatusFailure(e.toString());
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _handleTransientStatusFailure(String errorMessage) async {
    _consecutiveStatusFailures++;
    _log.warning(
      'Error checking setup status ($errorMessage), '
      'failure count=$_consecutiveStatusFailures',
    );

    // After transient failures, fall back to any cached setup state so users
    // who are already configured are not blocked on /setup.
    if (_consecutiveStatusFailures < 2 || !mounted) return;

    try {
      final cachedSettings = await DioClient().getSettings();
      if (cachedSettings?.isSetupComplete == true && mounted) {
        _log.info('Cached setup indicates complete, routing to planner');
        _pollTimer?.cancel();
        context.replace(AppRoute.plannerScreen);
      }
    } catch (e) {
      _log.warning('Failed cached setup fallback check: $e');
    }
  }
}
