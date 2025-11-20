// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/auth_remote_data_source.dart';
import 'package:heliumedu/data/repositories/auth_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_event.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_state.dart';
import 'package:heliumedu/presentation/views/authScreen/signInScreen/sign_in_controller.dart';
import 'package:heliumedu/presentation/widgets/custom_text_button.dart';
import 'package:heliumedu/presentation/widgets/custom_text_field.dart';
import 'package:heliumedu/utils/app_assets.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

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
      child: const SignInScreenView(),
    );
  }
}

class SignInScreenView extends StatefulWidget {
  const SignInScreenView({super.key});

  @override
  State<SignInScreenView> createState() => _SignInScreenViewState();
}

class _SignInScreenViewState extends State<SignInScreenView> {
  final SignInController _controller = SignInController();

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
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
          _showSnackBar(
            'Login successful! Welcome ${state.username ?? "back"}!',
            isError: false,
          );
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

                    CustomTextField(
                      hintText: 'Username',
                      prefixIcon: Icons.person,
                      controller: _controller.usernameController,
                      validator: _controller.validateUsername,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 32.h),

                    CustomTextField(
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
                          style: AppTextStyle.fTextStyle.copyWith(
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
                            CustomTextButton(
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
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton(
                                  onPressed: _handleLogout,
                                  child: Text(
                                    'Logout (Debug)',
                                    style: AppTextStyle.cTextStyle.copyWith(
                                      color: Colors.red,
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
                        Navigator.pushNamed(context, AppRoutes.signUpScreen);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Need an account? ',
                            style: AppTextStyle.mTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Sign Up',
                            style: AppTextStyle.cTextStyle.copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: primaryColor,
                              color: primaryColor,
                            ),
                          )
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
