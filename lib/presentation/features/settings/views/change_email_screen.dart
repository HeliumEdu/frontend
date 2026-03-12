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
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/settings/controllers/change_email_form_controller.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Shows as a dialog on desktop, or navigates on mobile.
void showChangeEmail(BuildContext context) {
  if (Responsive.isMobile(context)) {
    context.push(AppRoute.changeEmailScreen, extra: true);
  } else {
    showScreenAsDialog(
      context,
      child: const ChangeEmailScreen(),
      width: AppConstants.leftPanelDialogWidth,
      alignment: Alignment.centerLeft,
      insetPadding: const EdgeInsets.all(0),
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends BasePageScreenState<ChangeEmailScreen> {
  @override
  String get screenTitle => 'Change Email';

  @override
  IconData get icon => Icons.email_outlined;

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function? get saveAction => _onSubmit;

  final ChangeEmailFormController _formController = ChangeEmailFormController();

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
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            showSnackBar(context, state.message!, type: SnackType.error);
          } else if (state is AuthProfileFetched) {
            setState(() {
              _currentEmail = state.user.email;
              _emailChanging = state.user.emailChanging;
              isLoading = false;
            });
          } else if (state is AuthEmailChangeRequested) {
            _formController.clearForm();

            showSnackBar(
              context,
              'Verification email sent to ${state.newEmail}',
              useRootMessenger: true,
            );

            if (DialogModeProvider.isDialogMode(context)) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          } else if (state is AuthEmailChangeCancelled) {
            _formController.clearForm();

            showSnackBar(
              context,
              'The pending email change was cancelled',
              useRootMessenger: true,
            );

            if (DialogModeProvider.isDialogMode(context)) {
              Navigator.of(context).pop();
            } else {
              context.pop();
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
  Widget buildMainArea(BuildContext context) {
    return Expanded(
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
                onFieldSubmitted: (value) => _onSubmit(),
              ),
              const SizedBox(height: 14),

              LabelAndTextFormField(
                label: 'Current password',
                prefixIcon: Icons.lock,
                controller: _formController.oldPasswordController,
                validator: BasicFormController.validatePassword,
                onFieldSubmitted: (value) => _onSubmit(),
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

  void _onSubmit() {
    if (_formController.formKey.currentState?.validate() ?? false) {
      setState(() {
        isSubmitting = true;
      });

      context.read<AuthBloc>().add(
        ChangeEmailEvent(
          newEmail: _formController.newEmailController.text,
          oldPassword: _formController.oldPasswordController.text,
        ),
      );
    }
  }
}
