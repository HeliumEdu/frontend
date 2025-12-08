// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/presentation/views/auth/login_controller.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/widgets/helium_text_button.dart';
import 'package:heliumapp/presentation/widgets/helium_text_field.dart';
import 'package:heliumapp/utils/app_colors.dart';
import 'package:heliumapp/utils/app_size.dart';
import 'package:heliumapp/utils/app_style.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();
    return BlocProvider(
      create: (context) => AuthBloc(
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
        ),
        dioClient: dioClient,
      ),
      child: const LoginScreenView(),
    );
  }
}

class LoginScreenView extends StatefulWidget {
  const LoginScreenView({super.key});

  @override
  State<LoginScreenView> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends State<LoginScreenView> {
  final LoginController _controller = LoginController();

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? redColor : greenColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: whiteColor,
          onPressed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  void _handleSignIn() {
    if (_controller.formKey.currentState!.validate()) {
      // Dispatch login event
      context.read<AuthBloc>().add(
        LoginEvent(
          username: _controller.usernameController.text.trim(),
          password: _controller.passwordController.text,
        ),
      );
    }
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const LogoutEvent());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
        } else if (state is AuthLoginSuccess) {
          _controller.clearForm();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.bottomNavBarScreen,
              );
            }
          });
        } else if (state is AuthError) {
          _showSnackBar(state.message, isError: true);
        } else if (state is AuthLogoutSuccess) {
          _showSnackBar(state.message, isError: false);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.h),
            child: Form(
              key: _controller.formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 99.v),

                    Center(
                      child: Image.asset(
                        AppAssets.welcomeImagePath,
                        height: 88.v,
                        width: 600.h,
                      ),
                    ),
                    SizedBox(height: 140.h),

                    HeliumTextField(
                      hintText: 'Username',
                      prefixIcon: Icons.person,
                      controller: _controller.usernameController,
                      validator: _controller.validateUsername,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 32.h),

                    HeliumTextField(
                      hintText: 'Password',
                      prefixIcon: Icons.lock,
                      controller: _controller.passwordController,
                      validator: _controller.validatePassword,
                      obscureText: !_controller.isPasswordVisible,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _controller.togglePasswordVisibility();
                          });
                        },
                        icon: Icon(
                          _controller.isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: textColor,
                        ),
                      ),
                    ),

                    SizedBox(height: 32.v),

                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPasswordScreen,
                        );
                        if (!mounted) return;
                        if (result is String && result.isNotEmpty) {
                          _showSnackBar(result, isError: false);
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot your password?',
                          style: AppStyle.fTextStyle.copyWith(
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32.v),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return Column(
                          children: [
                            HeliumTextButton(
                              buttonText: 'Sign In',
                              onPressed: _handleSignIn,
                              isLoading: isLoading,
                            ),
                            SizedBox(height: 16.v),
                            // Logout button for testing/debugging
                            if (state is AuthLogoutSuccess)
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(color: redColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton(
                                  onPressed: _handleLogout,
                                  child: Text(
                                    'Logout (Debug)',
                                    style: AppStyle.cTextStyle.copyWith(
                                      color: redColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.registerScreen);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Need an account? ',
                            style: AppStyle.mTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Sign Up',
                            style: AppStyle.cTextStyle.copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: primaryColor,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
