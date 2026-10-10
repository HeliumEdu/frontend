import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

Future<bool> confirmClearExampleData(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Clear Example Data?', style: AppStyles.pageTitle(dialogContext)),
      content: SizedBox(
        width: Responsive.getDialogWidth(dialogContext),
        child: Text(
          'This removes the example schedule. Anything you\'ve added or '
          'changed stays.',
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
                  buttonText: 'Cancel',
                  backgroundColor: dialogContext.colorScheme.outline,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Clear',
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
