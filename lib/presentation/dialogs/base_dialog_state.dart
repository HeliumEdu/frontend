// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/widgets/error_container.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:meta/meta.dart';

abstract class BaseDialogState<T extends StatefulWidget> extends State<T> {
  @mustBeOverridden
  String get dialogTitle;

  @mustBeOverridden
  BasicFormController get formController;

  // State
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

  // TODO: Cleanup: there's a keyboard gap on iOS (at the bottom) on taller dialogs, fix
  Dialog buildDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: SingleChildScrollView(
          child: Material(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formController.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDialogHeader(),

                    buildMainArea(context),

                    // TODO: Enhancement: probably a way to parse prefix before colon (if exists) and map the specific error to the relevant field
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

  Widget buildButtonArea() {
    return Row(
      children: [
        Expanded(
          child: HeliumElevatedButton(
            buttonText: 'Cancel',
            backgroundColor: context.colorScheme.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
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
