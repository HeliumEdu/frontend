import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';

Future<bool> confirmClearExampleData(BuildContext context) {
  return showConfirmActionDialog(
    context: context,
    title: 'Clear Example Data?',
    message:
        "This removes the example schedule. Anything you've added or changed stays.",
    actionText: 'Clear',
    style: ConfirmActionStyle.neutral,
  );
}
