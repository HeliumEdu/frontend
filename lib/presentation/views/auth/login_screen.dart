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

final _log = Logger('presentation.views');

// TODO: High Value, Low Effort: especially on auth screens, make error / response message display consistent—should messages be defined on screens, or pulled from backend (or Bloc's message field)?
// TODO: Known Issues (9/High): some backend error messages (like when the user tries to login before verifying their email) have links in them to click, but these don't work on snackbar

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

            if (context.mounted) {
              // Redirect to intended destination or default to calendar
              final destination = _nextRoute ?? AppRoutes.plannerScreen;
              context.replace(destination);
            }
          } else if (state is AuthError) {
            // 401/403 errors on login screen are from force logout (already showed snackbar)
            if (state.code == '401' || state.code == '403') {
              _log.info(
                'Suppressing ${state.code} error snackbar on login screen: ${state.message}',
              );
            } else {
              showSnackBar(context, state.message!, isError: true, seconds: 6);
            }
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
    return SingleChildScrollView(
      child: ResponsiveCenterCard(
        child: AutofillGroup(
          child: Form(
            key: _formController.formKey,
            child: Column(
              children: [
                const SizedBox(height: 100),

                Center(
                  child: Image.asset(
                    AppAssets.logoImagePath,
                    height: 88,
                    width: 600,
                  ),
                ),
                const SizedBox(height: 100),

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
                        context.go(AppRoutes.forgotPasswordScreen);
                      },
                      child: Text(
                        'Forgot your password?',
                        style: AppStyles.standardBodyText(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.primary,
                        ),
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
                          onPressed: _onSubmit,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 25),

                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go(AppRoutes.registerScreen);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Need an account?',
                          style: AppStyles.buttonText(context).copyWith(
                            color: context.colorScheme.primary,
                          ),
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
