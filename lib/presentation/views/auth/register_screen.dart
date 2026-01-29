// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/forms/auth/register_form_controller.dart';
import 'package:heliumapp/presentation/forms/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/responsive_center_card.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends BasePageScreenState<RegisterScreen> {
  @override
  String get screenTitle => 'New User Registration';

  @override
  bool get isAuthenticatedScreen => false;

  final RegisterFormController _formController = RegisterFormController();

  @override
  void initState() {
    super.initState();

    _initializeForm();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _initializeForm() async {
    await _formController.initializeTimezones();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _formController.dispose();

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
          if (state is AuthRegistered) {
            showSnackBar(
              context,
              'Almost there! Check your email for a verification code.',
              seconds: 6,
            );

            if (context.mounted) {
              context.go(
                AppRoutes.verifyScreen,
                extra: VerifyScreenArgs(username: state.username),
              );
            }
          } else if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true, seconds: 6);
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
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.transparent,
              size: 20,
            ),
            onPressed: () {},
          ),
          title: Text(screenTitle, style: context.pageTitle),
        ),
        body: SafeArea(child: buildMainArea(context)),
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return SingleChildScrollView(
      child: ResponsiveCenterCard(
        child: Form(
          key: _formController.formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),

              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
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

              const SizedBox(height: 44),

              LabelAndTextFormField(
                hintText: 'Username',
                autofocus: true,
                prefixIcon: Icons.person_outline,
                controller: _formController.usernameController,
                validator: BasicFormController.validateUsername,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),

              LabelAndTextFormField(
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                controller: _formController.emailController,
                validator: BasicFormController.validateRequiredEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              LabelAndTextFormField(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                controller: _formController.passwordController,
                validator: BasicFormController.validatePassword,
                obscureText: !_formController.isPasswordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _formController.isPasswordVisible =
                          !_formController.isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _formController.isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              LabelAndTextFormField(
                hintText: 'Confirm password',
                prefixIcon: Icons.repeat,
                controller: _formController.confirmPasswordController,
                validator: _formController.validateConfirmPassword,
                obscureText: !_formController.isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _formController.isConfirmPasswordVisible =
                          !_formController.isConfirmPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _formController.isConfirmPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              DropDown(
                prefixIcon: Icons.access_time_outlined,
                initialValue: TimeZoneConstants.items.firstWhere(
                  (tz) => tz.value == _formController.selectedTimezone,
                ),
                items: TimeZoneConstants.items,
                onChanged: (value) {
                  setState(() {
                    _formController.selectedTimezone = value!.value;
                  });
                },
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: RichText(
                        text: TextSpan(
                          text: "I agree to Helium's ",
                          style: context.formText,
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => launchUrl(
                                  Uri.parse('https://www.heliumedu.com/terms'),
                                  mode: LaunchMode.externalApplication,
                                ),
                                child: Text(
                                  'Terms of Service',
                                  style: context.formText.copyWith(
                                    color: context.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: ' and ', style: context.formText),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => launchUrl(
                                  Uri.parse(
                                    'https://www.heliumedu.com/privacy',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                                child: Text(
                                  'Privacy Policy',
                                  style: context.formText.copyWith(
                                    color: context.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      value: _formController.agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _formController.agreeToTerms =
                              !_formController.agreeToTerms;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return HeliumElevatedButton(
                    buttonText: 'Sign Up',
                    isLoading: isSubmitting,
                    onPressed: _handleSubmit,
                  );
                },
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      context.replace(AppRoutes.loginScreen);
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
                          style: context.buttonText.copyWith(
                            color: context.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formController.formKey.currentState!.validate()) {
      if (!_formController.agreeToTerms) {
        showSnackBar(
          context,
          'You must agree to Terms of Service and Privacy Policy',
          isError: true,
          seconds: 4,
        );
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      // Dispatch register event
      context.read<AuthBloc>().add(
        RegisterEvent(
          username: _formController.usernameController.text.trim(),
          email: _formController.emailController.text.trim(),
          password: _formController.passwordController.text,
          timezone: _formController.selectedTimezone,
        ),
      );
    }
  }
}
