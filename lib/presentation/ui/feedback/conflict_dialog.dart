import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum ConflictResolution { loadLatest, overwrite }

Future<void> resolveConflict(
  BuildContext context, {
  required VoidCallback onLoadLatest,
  required VoidCallback onOverwrite,
}) async {
  final resolution = await confirmConflictResolution(context);
  if (!context.mounted) return;

  switch (resolution) {
    case ConflictResolution.loadLatest:
      onLoadLatest();
    case ConflictResolution.overwrite:
      onOverwrite();
  }
}

Future<ConflictResolution> confirmConflictResolution(
  BuildContext context,
) async {
  final result = await showDialog<ConflictResolution>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          'Changed on Another Device',
          style: AppStyles.pageTitle(dialogContext),
        ),
        content: SizedBox(
          width: Responsive.getDialogWidth(dialogContext),
          child: Text(
            'This was changed on another device after you opened it. Load the '
            'latest version, or overwrite it with your changes?',
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
                    buttonText: 'Load Latest',
                    backgroundColor: dialogContext.colorScheme.outline,
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(ConflictResolution.loadLatest),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HeliumElevatedButton(
                    buttonText: 'Overwrite',
                    backgroundColor: dialogContext.colorScheme.error,
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(ConflictResolution.overwrite),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? ConflictResolution.loadLatest;
}
