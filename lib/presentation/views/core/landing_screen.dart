// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final DioClient _dioClient = DioClient();
  String? _deepLinkRoute;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      final uri = Uri.base;
      final currentPath = uri.path;
      if (currentPath.isNotEmpty && currentPath != '/') {
        _deepLinkRoute = currentPath;
        log.info('Deep link detected: $_deepLinkRoute');
      }
    }

    _checkAutoLogin();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  Future<void> _checkAutoLogin() async {
    final accessToken = await _dioClient.getAccessToken();

    if (mounted && (accessToken?.isNotEmpty ?? false)) {
      log.info('Token found, checking authentication ...');

      log.info('Checking access token validity ...');

      // Set up listener before dispatching event to avoid race condition
      _authSubscription = context.read<AuthBloc>().stream.listen((state) {
        log.info('Auth state received: ${state.runtimeType}');
        if (state is AuthAuthenticated || state is AuthTokenRefreshed) {
          log.info('Access token is valid, navigating to home');
          _authSubscription?.cancel();
          _navigateToTarget();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          log.info(
            'Access and refresh tokens missing or invalid, navigating to login',
          );
          _authSubscription?.cancel();
          _navigateToLogin();
        }
      });
      context.read<AuthBloc>().add(CheckAuthEvent());
    } else {
      log.info('No token found or context not mounted, navigate to login');
      _navigateToLogin();
    }
  }

  void _navigateToTarget() {
    if (!mounted) return;

    final targetRoute = _deepLinkRoute ?? AppRoutes.calendarScreen;
    log.info('Navigating to: $targetRoute');

    context.go(targetRoute);
  }

  void _navigateToLogin() {
    if (!mounted) return;

    context.replace(AppRoutes.loginScreen);
  }
}
