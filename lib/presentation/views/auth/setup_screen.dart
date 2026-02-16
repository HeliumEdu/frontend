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
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.views');

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
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

  void _startPolling() {
    _log.info('Starting setup status polling');
    _checkSetupStatus();

    // Poll every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkSetupStatus();
    });
  }

  Future<void> _checkSetupStatus() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      _log.info('Checking setup status...');

      // Fetch fresh settings from API
      final settings = await DioClient().fetchSettings();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LoadingIndicator(size: 48, strokeWidth: 4),
                const SizedBox(height: 32),
                Text(
                  'Setting up your account...',
                  style: AppStyles.standardBodyText(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Creating your example schedule. This may take a moment.',
                  style: AppStyles.standardBodyText(context).copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
