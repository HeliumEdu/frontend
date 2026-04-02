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
import 'package:heliumapp/presentation/features/settings/controllers/change_email_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

class ChangeEmailScreen extends StatefulWidget {
  final VoidCallback? onActionStarted;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  const ChangeEmailScreen({
    super.key,
    this.onActionStarted,
    this.onCompleted,
    this.onFailed,
  });

  @override
  State<ChangeEmailScreen> createState() => ChangeEmailScreenState();
}

class ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final ChangeEmailFormController _formController = ChangeEmailFormController();

  bool _isSubmitting = false;
  String? _currentEmail;
  String? _emailChanging;

  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(FetchProfileEvent());
  }

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
        } else if (state is AuthProfileFetched) {
          setState(() {
            _currentEmail = state.user.email;
            _emailChanging = state.user.emailChanging;
          });
        } else if (state is AuthEmailChangeRequested) {
          _formController.clearForm();
          SnackBarHelper.show(
            context,
            'Verification email sent to ${state.newEmail}',
            useRootMessenger: true,
          );
          widget.onCompleted?.call();
        } else if (state is AuthEmailChangeCancelled) {
          _formController.clearForm();
          SnackBarHelper.show(
            context,
            'The pending email change was cancelled',
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
              if (_emailChanging != null && _emailChanging!.isNotEmpty) ...[
                WarningContainer(
                  text:
                      'Change pending, click the link sent to $_emailChanging to verify',
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 16),
              ],
              LabelAndTextFormField(
                label: 'New email',
                autofocus: kIsWeb,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _formController.newEmailController,
                validator: _validateNewEmail,
                onFieldSubmitted: (value) => onSubmit(),
              ),
              const SizedBox(height: 14),

              LabelAndTextFormField(
                label: 'Current password',
                prefixIcon: Icons.lock,
                controller: _formController.oldPasswordController,
                validator: BasicFormController.validatePassword,
                onFieldSubmitted: (value) => onSubmit(),
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
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: context.colorScheme.onSurface,
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
        ChangeEmailEvent(
          newEmail: _formController.newEmailController.text,
          oldPassword: _formController.oldPasswordController.text,
        ),
      );
    }
  }

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }

  String? _validateNewEmail(String? value) {
    final basicValidation = BasicFormController.validateRequiredEmail(value);
    if (basicValidation != null) {
      return basicValidation;
    }

    // Allow submitting current email only if there's a pending change (to cancel it)
    final isCurrentEmail = _currentEmail != null &&
        value?.toLowerCase().trim() == _currentEmail!.toLowerCase();
    if (isCurrentEmail && (_emailChanging == null || _emailChanging!.isEmpty)) {
      return 'New email must be different from your current email';
    }

    return null;
  }
}
