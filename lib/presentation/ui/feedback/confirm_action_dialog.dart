import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// How consequential a confirmed action is, which sets its button's color.
enum ConfirmActionStyle { destructive, warning, neutral }

/// Asks the user to confirm an action. Resolves true only when they do.
///
/// [style] colors the action button; [icon], when given, leads the title in
/// the same color.
Future<bool> showConfirmActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String actionText,
  String cancelText = 'Cancel',
  IconData? icon,
  ConfirmActionStyle style = ConfirmActionStyle.destructive,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: _buildTitle(dialogContext, title, icon, style),
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
                  backgroundColor: _styleColor(dialogContext, style),
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

Color? _styleColor(BuildContext context, ConfirmActionStyle style) =>
    switch (style) {
      ConfirmActionStyle.destructive => context.colorScheme.error,
      ConfirmActionStyle.warning => context.semanticColors.warning,
      ConfirmActionStyle.neutral => null,
    };

Widget _buildTitle(
  BuildContext context,
  String title,
  IconData? icon,
  ConfirmActionStyle style,
) {
  final text = Text(title, style: AppStyles.pageTitle(context));
  if (icon == null) return text;

  return Row(
    children: [
      Icon(
        icon,
        color: _styleColor(context, style) ?? context.colorScheme.primary,
        size: 24,
      ),
      const SizedBox(width: 12),
      Flexible(child: text),
    ],
  );
}
