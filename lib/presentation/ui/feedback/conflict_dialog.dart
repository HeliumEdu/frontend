import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum ConflictResolution { loadLatest, overwrite }

/// Shown when a form's linked note changed elsewhere and this device's text
/// was kept as a standalone note instead.
const noteSavedAsCopyMessage =
    'The note was changed on another device, so your changes were saved as a '
    'separate note.';

/// Asks how to resolve a save that lost to a change made on another device.
///
/// The user must pick one; the dialog can't be dismissed, so nothing is
/// resolved silently.
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
