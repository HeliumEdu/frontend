// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class DiscardChangesScope extends StatelessWidget {
  final bool isDirty;
  final Widget child;

  const DiscardChangesScope({
    super.key,
    required this.isDirty,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // onPopInvoked fires on every PopScope on the route, not just the one
        // that blocked. Bail if we weren't the one blocking (i.e., not dirty).
        if (!isDirty) return;
        if (!context.mounted) return;
        final shouldDiscard = await confirmDiscardChanges(context);
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

Future<bool> confirmDiscardChanges(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Unsaved Changes', style: AppStyles.pageTitle(dialogContext)),
      content: SizedBox(
        width: Responsive.getDialogWidth(dialogContext),
        child: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: AppStyles.standardBodyText(dialogContext),
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(dialogContext),
          child: Row(
            children: [
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Keep Editing',
                  backgroundColor: dialogContext.colorScheme.outline,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Discard',
                  backgroundColor: dialogContext.colorScheme.error,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
