import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';

Future<bool> confirmDiscardChanges(BuildContext context) {
  return showConfirmActionDialog(
    context: context,
    title: 'Unsaved Changes',
    message: 'You have unsaved changes. Are you sure you want to discard them?',
    actionText: 'Discard',
    cancelText: 'Keep Editing',
  );
}
