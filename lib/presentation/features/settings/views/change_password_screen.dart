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
import 'package:heliumapp/presentation/ui/layout/helium_full_screen_scroll_view.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

class ChangePasswordScreen extends StatefulWidget {
  final bool passwordless;
  final VoidCallback? onActionStarted;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  const ChangePasswordScreen({
    super.key,
    this.passwordless = false,
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

  bool get isChanged => _formController.isChanged;

  String _initialOld = '';
  String _initialNew = '';
  String _initialConfirm = '';
  bool _changeTrackingActive = false;

  @override
  void initState() {
    super.initState();
    if (!widget.passwordless) {
      _formController.oldPasswordController.addListener(_recomputeChanged);
    }
    _formController.newPasswordController.addListener(_recomputeChanged);
    _formController.confirmPasswordController.addListener(_recomputeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _initialOld = _formController.oldPasswordController.text;
        _initialNew = _formController.newPasswordController.text;
        _initialConfirm = _formController.confirmPasswordController.text;
        _changeTrackingActive = true;
      });
    });
  }

  @override
  void dispose() {
    if (!widget.passwordless) {
      _formController.oldPasswordController.removeListener(_recomputeChanged);
    }
    _formController.newPasswordController.removeListener(_recomputeChanged);
    _formController.confirmPasswordController.removeListener(_recomputeChanged);
    _formController.dispose();
    super.dispose();
  }

  void _recomputeChanged() {
    if (!_changeTrackingActive) return;
    final dirty =
        (!widget.passwordless &&
            _formController.oldPasswordController.text != _initialOld) ||
        _formController.newPasswordController.text != _initialNew ||
        _formController.confirmPasswordController.text != _initialConfirm;
    if (dirty == _formController.isChanged) return;
    setState(() => _formController.isChanged = dirty);
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
          setState(() {
            _initialOld = _formController.oldPasswordController.text;
            _initialNew = _formController.newPasswordController.text;
            _initialConfirm = _formController.confirmPasswordController.text;
            _formController.isChanged = false;
          });
          SnackBarHelper.show(context, 'Password changed.');
          widget.onCompleted?.call();
        }
      },
      child: HeliumFullScreenScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: AutofillGroup(
          child: Form(
            key: _formController.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.passwordless) ...[
                  HeliumPasswordField(
                    label: 'Current password',
                    autofocus: kIsWeb,
                    controller: _formController.oldPasswordController,
                    validator: BasicFormController.validatePassword,
                    onFieldSubmitted: (value) => onSubmit(),
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 14),
                ],

                HeliumPasswordField(
                  label: 'New password',
                  autofocus: widget.passwordless && kIsWeb,
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
          oldPassword: widget.passwordless
              ? null
              : _formController.oldPasswordController.text,
          newPassword: _formController.newPasswordController.text,
        ),
      );
    }
  }

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }
}
