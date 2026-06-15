// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class ResetPasswordScreen extends StatefulWidget {
  final String? uid;
  final String? token;

  const ResetPasswordScreen({super.key, this.uid, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends BasePageScreenState<ResetPasswordScreen> {
  @override
  String get screenTitle => 'Reset Password';

  @override
  bool get isAuthenticatedScreen => false;

  final BasicFormController _formController = BasicFormController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedIn) {
            showSnackBar(
              context,
              'Password reset! Welcome back.',
              seconds: 4,
            );

            if (!context.mounted) return;
            context.go(AppRoute.plannerScreen);
          } else if (state is AuthError) {
            showSnackBar(context, state.message!, type: SnackType.error, seconds: 4);
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
    final bool hasValidLink =
        widget.uid != null && widget.token != null;

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
                  Icons.lock_reset,
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
              hasValidLink
                  ? 'Enter your new password below.'
                  : 'This reset link is invalid or has expired. Please request a new one.',
              style: AppStyles.headingText(context),
            ),

            const SizedBox(height: 25),

            if (hasValidLink) ...[
              LabelAndTextFormField(
                hintText: 'New password',
                autofocus: kIsWeb,
                prefixIcon: Icons.lock_outline,
                controller: _passwordController,
                obscureText: true,
                validator: BasicFormController.validatePassword,
                onFieldSubmitted: (value) => _onSubmit(),
              ),

              const SizedBox(height: 12),

              LabelAndTextFormField(
                hintText: 'Confirm new password',
                prefixIcon: Icons.lock_outline,
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) => BasicFormController.validateConfirmPassword(
                  _passwordController.text,
                  value,
                ),
                onFieldSubmitted: (value) => _onSubmit(),
              ),

              const SizedBox(height: 25),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return HeliumElevatedButton(
                    buttonText: 'Set New Password',
                    isLoading: isSubmitting,
                    onPressed: _onSubmit,
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () {
                  context.go(AppRoute.signinScreen);
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
                      'Back to sign in',
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

  void _onSubmit() {
    if (_formController.formKey.currentState?.validate() ?? false) {
      setState(() {
        isSubmitting = true;
      });

      context.read<AuthBloc>().add(
        ResetPasswordEvent(
          uid: widget.uid!,
          token: widget.token!,
          password: _passwordController.text,
        ),
      );
    }
  }
}
