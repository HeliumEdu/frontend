// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/auth_remote_data_source.dart';
import 'package:heliumedu/data/repositories/auth_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_event.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_state.dart';
import 'package:heliumedu/presentation/views/authScreen/signUpScreen/sign_up_controller.dart';
import 'package:heliumedu/presentation/widgets/custom_text_field.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final SignUpController _controller = SignUpController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _handleSubmit(BuildContext ctx) async {
    if (_formKey.currentState?.validate() ?? false) {
      ctx.read<AuthBloc>().add(
        ForgotPasswordEvent(email: _controller.emailController.text.trim()),
      );
    }
  }

  @override
  void dispose() {
    _controller.emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();
    return BlocProvider(
      create: (_) => AuthBloc(
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
        ),
        dioClient: dioClient,
      ),
      child: Scaffold(
        backgroundColor: softGrey,
        appBar: AppBar(
          backgroundColor: whiteColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: transparentColor, size: 20),
            onPressed: () {},
          ),
          title: Text(
            'Forgot Password',
            style: AppTextStyle.aTextStyle.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthLoading) {
                setState(() => _isLoading = true);
              } else {
                if (_isLoading) setState(() => _isLoading = false);
              }
              if (state is AuthForgotPasswordSent) {
                Navigator.pop(context, state.message);
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.message),
                  ),
                );
              }
            },
            child: Builder(
              builder: (innerContext) => SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.h,
                    vertical: 24.v,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 120.h,
                            height: 120.v,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_reset,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                        ),

                        SizedBox(height: 32.v),

                        // Title
                        Text(
                          _emailSent ? 'Check Your Email' : 'Reset Password',
                          style: AppTextStyle.aTextStyle.copyWith(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 12.v),

                        // Description
                        Text(
                          _emailSent
                              ? 'We have sent a password reset link to ${_controller.emailController.text}. Please check your inbox and spam folder.'
                              : 'Enter the email associated with your account. We\'ll reset your password and send a temporary password to your email address.',
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: textColor.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: 40.v),

                        if (!_emailSent) ...[
                          // Email Field
                          CustomTextField(
                            hintText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            controller: _controller.emailController,
                            validator: _controller.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          SizedBox(height: 32.v),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50.v,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      _handleSubmit(innerContext);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                disabledBackgroundColor: primaryColor
                                    .withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.h),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Get It',
                                      style: AppTextStyle.mTextStyle.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                         fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 24.v),

                          // Back to Login
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 18,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 8.h),
                                  Text(
                                    'Back to Login',
                                    style: AppTextStyle.cTextStyle.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Success Actions
                          SizedBox(
                            width: double.infinity,
                            height: 50.v,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _emailSent = false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.h),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Open Email App',
                                style: AppTextStyle.mTextStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 16.v),

                          // Resend Button
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
