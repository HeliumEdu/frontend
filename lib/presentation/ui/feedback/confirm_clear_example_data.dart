import 'package:flutter/material.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';

Future<bool> confirmClearExampleData(BuildContext context) {
  return showConfirmActionDialog(
    context: context,
    title: AppLocalizations.of(context).clearExampleDataTitle,
    message: AppLocalizations.of(context).clearExampleDataMessage,
    actionText: AppLocalizations.of(context).clearExampleDataButton,
    cancelText: AppLocalizations.of(context).commonCancelButton,
    style: ConfirmActionStyle.neutral,
  );
}
