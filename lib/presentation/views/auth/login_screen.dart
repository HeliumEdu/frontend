// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/controllers/auth/credentials_form_controller.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/responsive_center_card.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:sign_in_button/sign_in_button.dart';

final _log = Logger('presentation.views');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends BasePageScreenState<LoginScreen> {
  @override
  String get screenTitle => 'Login';

  @override
  bool get isAuthenticatedScreen => false;

  final CredentialsFormController _formController = CredentialsFormController();
  String? _nextRoute;
  bool isOAuthLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final next = GoRouterState.of(context).uri.queryParameters['next'];
      if (next?.isNotEmpty ?? false) {
        _nextRoute = Uri.decodeComponent(next!);
        showSnackBar(
          context,
          'Please login to continue.',
          isError: true,
          seconds: 4,
        );
      }
    });

    setState(() {
      isLoading = false;
    });
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
            _formController.clearForm();

            setState(() {
              isOAuthLoading = false;
              isSubmitting = true;
            });

            if (!context.mounted) return;

            // Check if account setup is complete
            final isSetupComplete =
                PrefService().getBool('is_setup_complete') ?? true;

            if (!isSetupComplete) {
              // New OAuth user - redirect to setup screen
              context.replace(AppRoute.setupScreen);
            } else {
              // Redirect to intended destination or default to planner
              final destination = _nextRoute ?? AppRoute.plannerScreen;
              context.replace(destination);
            }
          } else if (state is AuthAccountInactive) {
            _showInactiveAccountSnackBar(
              context,
              state.username,
              state.message,
            );
          } else if (state is AuthVerificationResent) {
            showSnackBar(
              context,
              'Verification email sent! Check your inbox.',
              seconds: 4,
            );
          } else if (state is AuthError) {
            // Only suppress 401/403 if NOT from active login attempt (force logout already showed snackbar)
            final isForceLogoutError =
                !isSubmitting &&
                !isOAuthLoading &&
                (state.httpStatusCode == 401 || state.httpStatusCode == 403);
            if (isForceLogoutError) {
              _log.info(
                'Suppressing force logout ${state.httpStatusCode} error on login screen: ${state.message}',
              );
            } else {
              showSnackBar(context, state.message!, isError: true, seconds: 6);
            }
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

  void _showInactiveAccountSnackBar(
    BuildContext context,
    String username,
    String? message,
  ) {
    showSnackBar(
      context,
      message ?? 'Your account is not yet verified.',
      isError: true,
      seconds: 10,
      action: SnackBarAction(
        label: 'Resend Email',
        textColor: context.colorScheme.onError,
        onPressed: () {
          context.read<AuthBloc>().add(
            ResendVerificationEvent(username: username),
          );
        },
      ),
    );
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
              const SizedBox(height: 50),

              Center(child: Image.asset(AppAssets.logoImagePath, height: 120)),

              const SizedBox(height: 50),

              LabelAndTextFormField(
                hintText: 'Username',
                autofocus: kIsWeb,
                prefixIcon: Icons.person,
                controller: _formController.usernameController,
                validator: BasicFormController.validateRequiredField,
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 32),

              LabelAndTextFormField(
                hintText: 'Password',
                prefixIcon: Icons.lock,
                controller: _formController.passwordController,
                validator: BasicFormController.validateRequiredField,
                onFieldSubmitted: (value) => _onSubmit(),
                obscureText: !_formController.isPasswordVisible,
                autofillHints: const [AutofillHints.password],
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _formController.isPasswordVisible =
                          !_formController.isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _formController.isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      context.go(AppRoute.forgotPasswordScreen);
                    },
                    child: Text(
                      'Forgot your password?',
                      style: AppStyles.standardBodyText(
                        context,
                      ).copyWith(color: context.colorScheme.primary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      HeliumElevatedButton(
                        buttonText: 'Sign In',
                        isLoading: isSubmitting,
                        enabled: !isOAuthLoading,
                        onPressed: _onSubmit,
                      ),
                    ],
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
                      text: 'Sign in with Google',
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
                        text: 'Sign in with Apple',
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 25),

              Center(
                child: TextButton(
                  onPressed: () {
                    context.go(AppRoute.registerScreen);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Need an account?',
                        style: AppStyles.buttonText(
                          context,
                        ).copyWith(color: context.colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: Responsive.getIconSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        color: context.colorScheme.primary,
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
  }

  void _onSubmit() {
    if (_formController.formKey.currentState!.validate()) {
      setState(() {
        isSubmitting = true;
      });

      context.read<AuthBloc>().add(
        LoginEvent(
          username: _formController.usernameController.text.trim(),
          password: _formController.passwordController.text,
        ),
      );
    }
  }
}
