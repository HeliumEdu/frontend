// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/forms/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/forms/settings/change_password_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/config/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends BasePageScreenState<ChangePasswordScreen> {
  @override
  String get screenTitle => 'Change Password';

  @override
  ScreenType get screenType => ScreenType.subPage;

  final ChangePasswordFormController _formController =
      ChangePasswordFormController();

  @override
  void initState() {
    super.initState();

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
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is AuthPasswordChanged) {
            showSnackBar(context, 'Password changed');

            _formController.clearForm();

            context.pop();
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
  Widget buildMainArea(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Form(
          key: _formController.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelAndTextFormField(
                label: 'Current password',
                autofocus: true,
                prefixIcon: Icons.lock,
                controller: _formController.oldPasswordController,
                validator: BasicFormController.validatePassword,
                obscureText: !_formController.isOldPasswordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _formController.isOldPasswordVisible =
                          !_formController.isOldPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _formController.isOldPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              LabelAndTextFormField(
                label: 'New password',
                prefixIcon: Icons.lock,
                controller: _formController.newPasswordController,
                validator: BasicFormController.validatePassword,
                obscureText: !_formController.isNewPasswordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _formController.isNewPasswordVisible =
                          !_formController.isNewPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _formController.isNewPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              LabelAndTextFormField(
                label: 'Confirm password',
                prefixIcon: Icons.repeat,
                controller: _formController.confirmPasswordController,
                validator: _formController.validateConfirmPassword,
                onFieldSubmitted: (value) => _handleSubmit(),
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
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 44),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return HeliumElevatedButton(
                    buttonText: 'Save',
                    isLoading: isSubmitting,
                    onPressed: _handleSubmit,
                  );
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formController.formKey.currentState?.validate() ?? false) {
      setState(() {
        isSubmitting = true;
      });

      context.read<AuthBloc>().add(
        ChangePasswordEvent(
          oldPassword: _formController.oldPasswordController.text,
          newPassword: _formController.newPasswordController.text,
        ),
      );
    }
  }
}
