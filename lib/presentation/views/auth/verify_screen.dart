// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class VerifyScreen extends StatefulWidget {
  final String? username;
  final String? code;

  const VerifyScreen({super.key, this.username, this.code});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends BasePageScreenState<VerifyScreen> {
  @override
  String get screenTitle => 'Verify Email';

  @override
  bool get isAuthenticatedScreen => false;

  final BasicFormController _formController = BasicFormController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.username != null) {
      _usernameController.text = widget.username!;
    }
    if (widget.code != null) {
      _codeController.text = widget.code!;
    }

    setState(() {
      isLoading = false;
    });

    // Auto-submit if both username and code are provided (e.g., from email link)
    if (widget.username != null && widget.code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onSubmit();
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();

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
          if (state is AuthEmailVerified) {
            showSnackBar(
              context,
              'Email verified! You can now log in.',
              seconds: 6,
            );

            if (context.mounted) {
              context.go(AppRoutes.loginScreen);
            }
          } else if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true, seconds: 4);
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

              const SizedBox(height: 24),

              Text(
                'Enter the verification code sent to your email address to complete your registration.',
                style: AppStyles.headingText(context),
              ),

              const SizedBox(height: 25),

              LabelAndTextFormField(
                hintText: 'Username',
                autofocus: kIsWeb && widget.username == null,
                prefixIcon: Icons.person_outline,
                controller: _usernameController,
                validator: BasicFormController.validateRequiredField,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),

              LabelAndTextFormField(
                hintText: 'Verification code',
                autofocus: widget.username != null && widget.code == null,
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
                    buttonText: 'Verify Email',
                    isLoading: isSubmitting,
                    onPressed: _onSubmit,
                  );
                },
              ),

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
                        style: AppStyles.buttonText(context).copyWith(
                          color: context.colorScheme.primary,
                        ),
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
          username: _usernameController.text.trim(),
          code: _codeController.text.trim(),
        ),
      );
    }
  }
}
