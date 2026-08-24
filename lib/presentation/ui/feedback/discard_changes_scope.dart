import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

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
