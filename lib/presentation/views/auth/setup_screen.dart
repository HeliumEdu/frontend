// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/responsive_center_card.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.views');

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends BasePageScreenState<SetupScreen> {
  @override
  String get screenTitle => '';

  Timer? _pollTimer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
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
            'Getting things ready...',
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

    // Poll every 3 seconds
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _checkSetupStatus();
    });
  }

  Future<void> _checkSetupStatus() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      _log.info('Checking setup status...');

      final settings = await DioClient().fetchSettings(forceRefresh: true);

      if (settings != null && settings.isSetupComplete) {
        _log.info('Setup complete, navigating to planner');
        _pollTimer?.cancel();

        if (mounted) {
          context.replace(AppRoute.plannerScreen);
        }
      } else {
        _log.info('Setup not yet complete, continuing to poll');
      }
    } catch (e) {
      _log.warning('Error checking setup status: $e');
    } finally {
      _isPolling = false;
    }
  }
}
