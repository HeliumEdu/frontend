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
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/settings/controllers/change_password_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_password_field.dart';
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
          TextInput.finishAutofillContext();
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
        child: AutofillGroup(
          child: Form(
            key: _formController.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeliumPasswordField(
                  label: 'Current password',
                  autofocus: kIsWeb,
                  controller: _formController.oldPasswordController,
                  validator: BasicFormController.validatePassword,
                  onFieldSubmitted: (value) => onSubmit(),
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 14),

                HeliumPasswordField(
                  label: 'New password',
                  controller: _formController.newPasswordController,
                  validator: BasicFormController.validatePassword,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 14),

                HeliumPasswordField(
                  label: 'Confirm password',
                  prefixIcon: Icons.repeat,
                  controller: _formController.confirmPasswordController,
                  validator: _formController.validateConfirmPassword,
                  onFieldSubmitted: (value) => onSubmit(),
                  autofillHints: const [AutofillHints.newPassword],
                ),

                const SizedBox(height: 12),
              ],
            ),
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
