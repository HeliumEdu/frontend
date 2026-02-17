// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/controllers/auth/register_form_controller.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/responsive_center_card.dart';
import 'package:heliumapp/presentation/widgets/searchable_dropdown.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends BasePageScreenState<SignupScreen> {
  @override
  String get screenTitle => 'Create an Account';

  @override
  bool get isAuthenticatedScreen => false;

  final SignupFormController _formController = SignupFormController();
  bool isOAuthLoading = false;

  @override
  void initState() {
    super.initState();

    _initializeForm();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _initializeForm() async {
    await _formController.initializeTimeZones();
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
          if (state is AuthLoggedIn) {
            final wasOAuthFlow = isOAuthLoading;
            setState(() {
              isOAuthLoading = false;
              isSubmitting = true;
            });

            if (!context.mounted) return;

            // Check if account setup is complete
            final isSetupComplete =
                PrefService().getBool('is_setup_complete') ?? true;

            if (!isSetupComplete) {
              if (wasOAuthFlow) {
                context.replace(
                  '${AppRoute.setupAccountScreen}?auto_detect_tz=true',
                );
              } else {
                context.replace(AppRoute.setupAccountScreen);
              }
            } else {
              context.replace(AppRoute.plannerScreen);
            }
          } else if (state is AuthRegistered) {
            TextInput.finishAutofillContext();
            showSnackBar(
              context,
              'Almost there! Check your email for a verification code.',
              seconds: 6,
            );

            final email = state.email;
            if (email == null || email.isEmpty) {
              showSnackBar(
                context,
                'Registration succeeded, but we could not load your email. Please log in to continue.',
                isError: true,
                seconds: 6,
              );
              return;
            }

            if (!context.mounted) return;
            context.go(
              '${AppRoute.verifyEmailScreen}?email=${Uri.encodeComponent(email)}',
            );
          } else if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true, seconds: 6);
          }

          if (state is! AuthLoading && state is! AuthLoggedIn) {
            setState(() {
              isSubmitting = false;
              isOAuthLoading = false;
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
      child: AutofillGroup(
        child: Form(
          key: _formController.formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),

              Text(
                screenTitle,
                style: AppStyles.featureText(context).copyWith(
                  fontSize: Responsive.getFontSize(context, mobile: 22),
                ),
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

              const SizedBox(height: 25),

              LabelAndTextFormField(
                hintText: 'Email',
                autofocus: kIsWeb,
                prefixIcon: Icons.email_outlined,
                controller: _formController.emailController,
                validator: BasicFormController.validateRequiredEmail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),

              LabelAndTextFormField(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                controller: _formController.passwordController,
                validator: BasicFormController.validatePassword,
                obscureText: !_formController.isPasswordVisible,
                autofillHints: const [AutofillHints.newPassword],
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
                autofillHints: const [AutofillHints.newPassword],
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

              SearchableDropdown(
                initialValue: TimeZoneConstants.items.firstWhere(
                  (tz) => tz.value == _formController.selectedTimeZone,
                ),
                items: TimeZoneConstants.items,
                onChanged: (value) {
                  setState(() {
                    _formController.selectedTimeZone = value!.value!;
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
                          style: AppStyles.formText(context),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => launchUrl(
                                  Uri.parse('https://www.heliumedu.com/terms'),
                                  mode: LaunchMode.externalApplication,
                                ),
                                child: Text(
                                  'Terms of Service',
                                  style: AppStyles.formText(context).copyWith(
                                    color: context.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' and ',
                              style: AppStyles.formText(context),
                            ),
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
                                  style: AppStyles.formText(context).copyWith(
                                    color: context.colorScheme.primary,
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

              const SizedBox(height: 25),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return HeliumElevatedButton(
                    buttonText: 'Sign Up',
                    isLoading: isSubmitting,
                    enabled: !isOAuthLoading,
                    onPressed: _onSubmit,
                  );
                },
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: AppStyles.standardBodyText(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: 250,
                height: 40,
                child: IgnorePointer(
                  ignoring: isOAuthLoading || isSubmitting,
                  child: Opacity(
                    opacity: isOAuthLoading || isSubmitting ? 0.5 : 1.0,
                    child: SignInButton(
                      Buttons.google,
                      onPressed: () {
                        setState(() {
                          isOAuthLoading = true;
                        });
                        context.read<AuthBloc>().add(GoogleLoginEvent());
                      },
                      text: 'Sign up with Google',
                    ),
                  ),
                ),
              ),

              // Only show Apple Sign-In on iOS and web (not Android)
              if (kIsWeb || !Platform.isAndroid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: 250,
                  height: 40,
                  child: IgnorePointer(
                    ignoring: isOAuthLoading || isSubmitting,
                    child: Opacity(
                      opacity: isOAuthLoading || isSubmitting ? 0.5 : 1.0,
                      child: SignInButton(
                        Buttons.apple,
                        onPressed: () {
                          setState(() {
                            isOAuthLoading = true;
                          });
                          context.read<AuthBloc>().add(AppleLoginEvent());
                        },
                        text: 'Sign up with Apple',
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
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
          email: _formController.emailController.text.trim(),
          password: _formController.passwordController.text,
          timezone: _formController.selectedTimeZone,
        ),
      );
    }
  }
}
