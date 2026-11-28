import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';

Future<bool> showConfirmDeleteDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required T item,
  required String label,
  required Function(T) onDelete,
  String? additionalWarning,
}) async {
  final l10n = AppLocalizations.of(parentContext);
  final materialL10n = MaterialLocalizations.of(parentContext);
  final name = label.trim();
  final hasWarning = additionalWarning?.isNotEmpty ?? false;
  final confirmed = await showConfirmActionDialog(
    context: parentContext,
    title: l10n.confirmDeleteTitle,
    message: name.isEmpty
        ? (hasWarning ? l10n.confirmDeleteUnnamedWarningMessage(additionalWarning!) : l10n.confirmDeleteUnnamedMessage)
        : (hasWarning
              ? l10n.confirmDeleteNamedWarningMessage(name, additionalWarning!)
              : l10n.confirmDeleteNamedMessage(name)),
    actionText: materialL10n.deleteButtonTooltip,
    cancelText: materialL10n.cancelButtonLabel,
  );
  if (confirmed) onDelete(item);
  return confirmed;
}
