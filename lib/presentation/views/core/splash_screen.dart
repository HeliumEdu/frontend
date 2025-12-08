// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/utils/app_colors.dart';
import 'package:heliumapp/utils/app_size.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  final DioClient _dioClient = DioClient();
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _initializeAuthBloc();
    _checkAutoLogin();
  }

  void _initializeAuthBloc() {
    final authDataSource = AuthRemoteDataSourceImpl(dioClient: _dioClient);
    final authRepository = AuthRepositoryImpl(remoteDataSource: authDataSource);
    _authBloc = AuthBloc(authRepository: authRepository, dioClient: _dioClient);
  }

  Future<void> _checkAutoLogin() async {
    final accessToken = await _dioClient.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      log.info(' Token found, checking authentication...');

      log.info('⚠️ Checking access token validity...');
      _authBloc.add(const CheckAuthEvent());

      _authBloc.stream.listen((state) {
        if (state is AuthAuthenticated) {
          log.info('✅ Access token is valid, navigating to home');
          _navigateToHome();
        } else {
          log.info('⚠️ Access token invalid, navigating to login');
          _navigateToLogin();
        }
      });
    } else {
      log.info('⚠️ No token found, navigate to login');
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.bottomNavBarScreen);
      }
    });
  }

  void _navigateToLogin() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.welcomeImagePath,
                    width: 300.adaptSize,
                    height: 300.adaptSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
