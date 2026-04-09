// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/settings/controllers/change_password_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback? onActionStarted;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  const ChangePasswordScreen({
    super.key,
    this.onActionStarted,
    this.onCompleted,
    this.onFailed,
  });

  @override
  State<ChangePasswordScreen> createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final ChangePasswordFormController _formController =
      ChangePasswordFormController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          SnackBarHelper.show(context, state.message!, type: SnackType.error);
          setState(() => _isSubmitting = false);
          widget.onFailed?.call();
        } else if (state is AuthPasswordChanged) {
          _formController.clearForm();
          SnackBarHelper.show(
            context,
            'Password changed',
            useRootMessenger: true,
          );
          widget.onCompleted?.call();
        }
      },
      child: SingleChildScrollView(
        child: Form(
          key: _formController.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelAndTextFormField(
                label: 'Current password',
                autofocus: kIsWeb,
                prefixIcon: Icons.lock,
                controller: _formController.oldPasswordController,
                validator: BasicFormController.validatePassword,
                onFieldSubmitted: (value) => onSubmit(),
                obscureText: !_formController.isOldPasswordVisible,
                suffixIcon: ExcludeFocus(
                  excluding: true,
                  child: IconButton(
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
              ),
              const SizedBox(height: 14),

              LabelAndTextFormField(
                label: 'New password',
                prefixIcon: Icons.lock,
                controller: _formController.newPasswordController,
                validator: BasicFormController.validatePassword,
                obscureText: !_formController.isNewPasswordVisible,
                suffixIcon: ExcludeFocus(
                  excluding: true,
                  child: IconButton(
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
              ),
              const SizedBox(height: 14),

              LabelAndTextFormField(
                label: 'Confirm password',
                prefixIcon: Icons.repeat,
                controller: _formController.confirmPasswordController,
                validator: _formController.validateConfirmPassword,
                onFieldSubmitted: (value) => onSubmit(),
                obscureText: !_formController.isConfirmPasswordVisible,
                suffixIcon: ExcludeFocus(
                  excluding: true,
                  child: IconButton(
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
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void onSubmit() {
    if (_isSubmitting) return;
    if (_formController.formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      widget.onActionStarted?.call();

      context.read<AuthBloc>().add(
        ChangePasswordEvent(
          oldPassword: _formController.oldPasswordController.text,
          newPassword: _formController.newPasswordController.text,
        ),
      );
    }
  }

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }
}
