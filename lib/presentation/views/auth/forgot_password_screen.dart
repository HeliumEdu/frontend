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
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/responsive_center_card.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends BasePageScreenState<ForgotPasswordScreen> {
  @override
  String get screenTitle => 'Password Reset';

  @override
  bool get isAuthenticatedScreen => false;

  final BasicFormController _formController = BasicFormController();
  final TextEditingController _emailController = TextEditingController();

  // State
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();

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
          if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true, seconds: 4);
          } else if (state is AuthPasswordReset) {
            showSnackBar(
              context,
              'Almost there! Check your email for a temporary password.',
              seconds: 6,
            );

            setState(() {
              _emailSent = true;
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
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: kIsWeb
            ? null
            : AppBar(
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.transparent,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
                title: Text(screenTitle, style: AppStyles.pageTitle(context)),
              ),
        body: SafeArea(child: buildMainArea(context)),
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: ResponsiveCenterCard(
            hasAppBar: true,
            child: Form(
              key: _formController.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
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

                  const SizedBox(height: 24),

                  Text(
                    _emailSent
                        ? "You've been emailed a temporary password. Log in to your account using the temporary password, then change it immediately."
                        : 'Enter the email associated with your account. We\'ll reset your password and send a temporary one to you.',
                    style: AppStyles.headingText(context),
                  ),

                  const SizedBox(height: 24),

                  if (!_emailSent) ...[
                    LabelAndTextFormField(
                      hintText: 'Email',
                      autofocus: kIsWeb,
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      onFieldSubmitted: (value) => _onSubmit(),
                      validator: BasicFormController.validateRequiredEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 25),

                    HeliumElevatedButton(
                      buttonText: 'Reset Password',
                      isLoading: isSubmitting,
                      onPressed: _onSubmit,
                    ),
                  ],

                  const SizedBox(height: 25),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.go(AppRoutes.loginScreen);
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
          ),
        );
      },
    );
  }

  Future<void> _onSubmit() async {
    if (_formController.formKey.currentState?.validate() ?? false) {
      setState(() {
        isSubmitting = true;
      });

      context.read<AuthBloc>().add(
        ForgotPasswordEvent(email: _emailController.text.trim()),
      );
    }
  }
}
