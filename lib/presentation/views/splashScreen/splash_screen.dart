import 'dart:async';
import 'package:flutter/material.dart';
import 'package:helium_student_flutter/config/app_route.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/auth_remote_data_source.dart';
import 'package:helium_student_flutter/data/repositories/auth_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_event.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_state.dart';
import 'package:helium_student_flutter/utils/app_assets.dart';
import 'package:helium_student_flutter/utils/app_size.dart';

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
    final token = await _dioClient.getToken();
    final refreshToken = await _dioClient.getRefreshToken();

    if (token != null && token.isNotEmpty) {
      print(' Token found, checking authentication...');

      if (refreshToken != null && refreshToken.isNotEmpty) {
        print('🔄 Refresh token found, attempting to refresh access token...');
        _authBloc.add(const RefreshTokenEvent());

        _authBloc.stream.listen((state) {
          if (state is AuthTokenRefreshed || state is AuthAuthenticated) {
            print('✅ Authentication successful, navigating to home');
            _navigateToHome();
          } else if (state is AuthUnauthenticated || state is AuthError) {
            print('⚠️ Authentication failed, navigating to login');
            _navigateToLogin();
          }
        });
      } else {
        print('⚠️ No refresh token found, checking access token validity...');
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
      }
    } else {
      print('⚠️ No token found, navigate to login');
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
      backgroundColor: Colors.white,
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
