// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helium_mobile/config/app_routes.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/data/datasources/auth_remote_data_source.dart';
import 'package:helium_mobile/data/models/auth/user_profile_model.dart';
import 'package:helium_mobile/data/repositories/auth_repository_impl.dart';
import 'package:helium_mobile/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:helium_mobile/presentation/bloc/authBloc/auth_event.dart';
import 'package:helium_mobile/presentation/bloc/authBloc/auth_state.dart';
import 'package:helium_mobile/utils/app_assets.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_size.dart';

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
      print(' Token found, checking authentication...');

      print('⚠️ Checking access token validity...');
      _authBloc.add(const CheckAuthEvent());

      _authBloc.stream.listen((state) {
        if (state is AuthAuthenticated) {
          print('✅ Access token is valid, navigating to home');
          _navigateToHome();
        } else {
          print('⚠️ Access token invalid, navigating to login');
          _navigateToLogin();
        }
      });
    } else {
      print('⚠️ No token found, navigate to login');
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.bottomNavBarScreen,
        );
      }
    });
  }

  void _navigateToLogin() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.signInScreen);
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
