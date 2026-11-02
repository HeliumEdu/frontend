import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Asks the user to confirm an action. Resolves true only when they do.
///
/// [isDestructive] colors the action button as an error; [icon], when given,
/// leads the title in the same color.
Future<bool> showConfirmActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String actionText,
  String cancelText = 'Cancel',
  IconData? icon,
  bool isDestructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: _buildTitle(dialogContext, title, icon),
      content: SizedBox(
        width: Responsive.getDialogWidth(dialogContext),
        child: Text(message, style: AppStyles.standardBodyText(dialogContext)),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(dialogContext),
          child: Row(
            children: [
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: cancelText,
                  backgroundColor: dialogContext.colorScheme.outline,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: actionText,
                  backgroundColor: isDestructive
                      ? dialogContext.colorScheme.error
                      : null,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Widget _buildTitle(BuildContext context, String title, IconData? icon) {
  final text = Text(title, style: AppStyles.pageTitle(context));
  if (icon == null) return text;

  return Row(
    children: [
      Icon(icon, color: context.colorScheme.error, size: 24),
      const SizedBox(width: 12),
      Flexible(child: text),
    ],
  );
}
