import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';

Future<bool> showConfirmDeleteDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required T item,
  required String label,
  required Function(T) onDelete,
  String? additionalWarning,
}) async {
  final trimmed = label.trim();
  final quotedLabel = trimmed.isEmpty ? 'this item' : '"$trimmed"';
  final warning = (additionalWarning?.isNotEmpty ?? false)
      ? '$additionalWarning '
      : '';

  final confirmed = await showConfirmActionDialog(
    context: parentContext,
    title: 'Confirm Delete',
    message:
        'Are you sure you want to delete $quotedLabel? ${warning}This action cannot be undone.',
    actionText: 'Delete',
  );
  if (confirmed) onDelete(item);
  return confirmed;
}
