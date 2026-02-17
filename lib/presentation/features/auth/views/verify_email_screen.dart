// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_center_card.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  final String? code;

  const VerifyEmailScreen({super.key, this.email, this.code});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends BasePageScreenState<VerifyEmailScreen> {
  @override
  String get screenTitle => 'Verify Email';

  @override
  bool get isAuthenticatedScreen => false;

  final BasicFormController _formController = BasicFormController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // Resend countdown timer
  static const int _resendCooldownSeconds = 60;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    if (widget.code != null) {
      _codeController.text = widget.code!;
    }

    setState(() {
      isLoading = false;
    });

    // Auto-submit if both email and code are provided (e.g., from email link)
    if (widget.email != null && widget.code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _onSubmit();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: buildListeners(context),
      child: buildScaffold(context),
    );
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedIn) {
            showSnackBar(
              context,
              'Email verified. Welcome to Helium!',
              seconds: 4,
            );

            if (!context.mounted) return;
            context.go(AppRoute.setupAccountScreen);
          } else if (state is AuthVerificationResent) {
            showSnackBar(
              context,
              'Verification email sent! Check your inbox.',
              seconds: 4,
            );
            _startResendCountdown();
          } else if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true, seconds: 4);
            setState(() {
              _isResending = false;
            });
          }

          if (state is! AuthLoading) {
            setState(() {
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildScaffold(BuildContext context) {
    return Title(
      title: '$screenTitle | ${AppConstants.appName}',
      color: context.colorScheme.primary,
      child: Scaffold(body: SafeArea(child: buildMainArea(context))),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return ResponsiveCenterCard(
      child: Form(
        key: _formController.formKey,
        child: Column(
          children: [
            const SizedBox(height: 12),

            Text(
              screenTitle,
              style: AppStyles.featureText(
                context,
              ).copyWith(fontSize: Responsive.getFontSize(context, mobile: 22)),
            ),

            const SizedBox(height: 25),

            Center(
              child: Container(
                width: AppConstants.authContainerSize,
                height: AppConstants.authContainerSize,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 60,
                    tablet: 64,
                    desktop: 68,
                  ),
                  color: context.colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Text(
              'Enter the verification code sent to your email address to complete your registration.',
              style: AppStyles.headingText(context),
            ),

            const SizedBox(height: 25),

            LabelAndTextFormField(
              hintText: 'Email',
              autofocus: kIsWeb && widget.email == null,
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              validator: BasicFormController.validateRequiredEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            LabelAndTextFormField(
              hintText: 'Verification code',
              autofocus: widget.email != null && widget.code == null,
              prefixIcon: Icons.pin,
              controller: _codeController,
              validator: _validateCode,
              onFieldSubmitted: (value) => _onSubmit(),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),

            const SizedBox(height: 25),

            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return HeliumElevatedButton(
                  buttonText: 'Verify & Login',
                  isLoading: isSubmitting,
                  onPressed: _onSubmit,
                );
              },
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: _canResend ? _onResend : null,
                child: _isResending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colorScheme.primary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: Responsive.getIconSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            color: _canResend
                                ? context.colorScheme.primary
                                : context.colorScheme.onSurface.withValues(
                                    alpha: 0.38,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resend verification email',
                            style: AppStyles.buttonText(context).copyWith(
                              color: _canResend
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onSurface.withValues(
                                      alpha: 0.38,
                                    ),
                            ),
                          ),
                          if (_resendCountdown > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '($_resendCountdown)',
                              style: AppStyles.buttonText(context).copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: () {
                  context.go(AppRoute.loginScreen);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: Responsive.getIconSize(
                        context,
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Back to login',
                      style: AppStyles.buttonText(
                        context,
                      ).copyWith(color: context.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length != 6) {
      return 'Please enter the 6-digit code';
    }
    return null;
  }

  void _onSubmit() {
    if (_formController.formKey.currentState?.validate() ?? false) {
      setState(() {
        isSubmitting = true;
      });

      context.read<AuthBloc>().add(
        VerifyEmailEvent(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
        ),
      );
    }
  }

  bool get _canResend =>
      _resendCountdown == 0 &&
      !_isResending &&
      _emailController.text.trim().isNotEmpty;

  void _onResend() {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
    });

    context.read<AuthBloc>().add(
      ResendVerificationEvent(email: _emailController.text.trim()),
    );
  }

  void _startResendCountdown() {
    setState(() {
      _isResending = false;
      _resendCountdown = _resendCooldownSeconds;
    });

    _resendTimer?.cancel();

    // Wait 1 second before starting countdown to avoid hitting rate limit edge case
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            timer.cancel();
          }
        });
      });
    });
  }
}

