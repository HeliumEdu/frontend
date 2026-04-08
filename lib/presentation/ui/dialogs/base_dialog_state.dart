// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/feedback/error_container.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:meta/meta.dart';

abstract class BaseDialogState<T extends StatefulWidget> extends State<T> {
  static const _dialogBorderRadius = 12.0;
  static const _dialogPadding = 20.0;
  static const _buttonSpacing = 12.0;
  @mustBeOverridden
  String get dialogTitle;

  @mustBeOverridden
  BasicFormController get formController;

  bool isSubmitting = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final listeners = buildListeners(context);
    if (listeners.isNotEmpty) {
      return MultiBlocListener(
        listeners: buildListeners(context),
        child: buildDialog(context),
      );
    } else {
      return buildDialog(context);
    }
  }

  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [];
  }

  Dialog buildDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.isMobile(context)
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: SingleChildScrollView(
          child: Material(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(_dialogBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(_dialogPadding),
              child: Form(
                key: formController.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDialogHeader(),

                    buildMainArea(context),

                    if (errorMessage != null) buildErrorArea(),

                    const SizedBox(height: 12),

                    buildButtonArea(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDialogHeader() {
    return Column(
      children: [
        Center(child: Text(dialogTitle, style: AppStyles.pageTitle(context))),
        const SizedBox(height: 12),
      ],
    );
  }

  @mustBeOverridden
  Widget buildMainArea(BuildContext context);

  Widget buildErrorArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ErrorContainer(
        text: errorMessage!,
        onDismiss: () {
          setState(() {
            errorMessage = null;
          });
        },
      ),
    );
  }

  void cancelAction() => Navigator.pop(context);

  Widget buildButtonArea() {
    return Row(
      children: [
        Expanded(
          child: HeliumElevatedButton(
            buttonText: 'Cancel',
            backgroundColor: context.colorScheme.outline,
            onPressed: cancelAction,
          ),
        ),
        const SizedBox(width: _buttonSpacing),
        Expanded(
          child: HeliumElevatedButton(
            buttonText: 'Save',
            isLoading: isSubmitting,
            onPressed: handleSubmit,
          ),
        ),
      ],
    );
  }

  @mustBeOverridden
  @mustCallSuper
  void handleSubmit() {
    if (formController.formKey.currentState!.validate()) {
      setState(() {
        isSubmitting = true;
      });
    }
  }
}
