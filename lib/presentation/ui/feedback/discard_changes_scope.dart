import 'package:flutter/material.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';

Future<bool> confirmDiscardChanges(BuildContext context) {
  return showConfirmActionDialog(
    context: context,
    title: AppLocalizations.of(context).discardChangesTitle,
    message: AppLocalizations.of(context).discardChangesMessage,
    actionText: AppLocalizations.of(context).discardChangesButton,
    cancelText: AppLocalizations.of(context).commonKeepEditingButton,
  );
}
