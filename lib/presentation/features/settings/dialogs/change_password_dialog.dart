import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/settings/controllers/change_password_form_controller.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_password_field.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

class _ChangePasswordDialogWidget extends StatefulWidget {
  final bool passwordless;
  final bool revokesApiToken;

  const _ChangePasswordDialogWidget({
    required this.passwordless,
    required this.revokesApiToken,
  });

  @override
  State<_ChangePasswordDialogWidget> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends BaseDialogState<_ChangePasswordDialogWidget> {
  final ChangePasswordFormController _formController =
      ChangePasswordFormController();

  @override
  String get dialogTitle =>
      widget.passwordless ? 'Set Password' : 'Change Password';

  @override
  BasicFormController get formController => _formController;

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, _) => isSubmitting,
        listener: (context, state) {
          if (state is AuthPasswordChanged) {
            TextInput.finishAutofillContext();
            Navigator.pop(context, true);
          } else if (state is AuthError) {
            setState(() {
              errorMessage = state.message;
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.revokesApiToken) ...[
            const WarningContainer(
              text:
                  'Changing your password also revokes your API token, so anything using it will stop working.',
            ),
            const SizedBox(height: 14),
          ],
          if (!widget.passwordless) ...[
            HeliumPasswordField(
              label: 'Current password',
              autofocus: PlatformBehavior.autofocusesOnOpen,
              controller: _formController.oldPasswordController,
              validator: BasicFormController.validatePassword,
              onChanged: (_) => _formController.markChanged(),
              onFieldSubmitted: (_) => handleSubmit(),
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 14),
          ],
          HeliumPasswordField(
            label: 'New password',
            autofocus:
                widget.passwordless && PlatformBehavior.autofocusesOnOpen,
            controller: _formController.newPasswordController,
            validator: BasicFormController.validatePassword,
            onChanged: (_) => _formController.markChanged(),
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 14),
          HeliumPasswordField(
            label: 'Confirm password',
            prefixIcon: Icons.repeat,
            controller: _formController.confirmPasswordController,
            validator: _formController.validateConfirmPassword,
            onChanged: (_) => _formController.markChanged(),
            onFieldSubmitted: (_) => handleSubmit(),
            autofillHints: const [AutofillHints.newPassword],
          ),
        ],
      ),
    );
  }

  @override
  void handleSubmit() {
    if (isSubmitting) return;
    super.handleSubmit();
    if (!isSubmitting) return;

    setState(() => errorMessage = null);
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

Future<bool> showChangePasswordDialog({
  required BuildContext parentContext,
  required bool passwordless,
  required bool revokesApiToken,
}) async {
  final changed = await showDialog<bool>(
    context: parentContext,
    barrierDismissible: false,
    builder: (_) => _ChangePasswordDialogWidget(
      passwordless: passwordless,
      revokesApiToken: revokesApiToken,
    ),
  );
  return changed ?? false;
}
