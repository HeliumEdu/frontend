// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/config/app_theme.dart';

class _ConfirmDeleteWidget<T extends BaseModel> extends StatefulWidget {
  final T item;
  final Function(T) onDelete;
  final String? additionalWarning;

  const _ConfirmDeleteWidget({
    super.key,
    required this.item,
    required this.onDelete,
    this.additionalWarning,
  });

  @override
  State<_ConfirmDeleteWidget<T>> createState() => _ConfirmDeleteWidgetState<T>();
}

class _ConfirmDeleteWidgetState<T extends BaseModel> extends State<_ConfirmDeleteWidget<T>> {
  bool _isSubmitting = false;

  static String _withTrailingSpace(String? additionalWarning) {
    if (additionalWarning?.isNotEmpty ?? false) {
      return '$additionalWarning ';
    } else {
      return '';
    }
  }

  void _handleDelete() {
    setState(() {
      _isSubmitting = true;
    });

    Navigator.pop(context);
    widget.onDelete(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Delete', style: context.dialogTitle),
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: Text(
          'Are you sure you want to delete "${widget.item.title}"? ${_withTrailingSpace(widget.additionalWarning)}This action cannot be undone.',
          style: context.dialogText,
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(context),
          child: Row(
            children: [
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Cancel',
                  backgroundColor: context.colorScheme.outline,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Delete',
                  backgroundColor: context.colorScheme.error,
                  isLoading: _isSubmitting,
                  onPressed: _handleDelete,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showConfirmDeleteDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required T item,
  required Function(T) onDelete,
  String? additionalWarning,
}) {
  return showDialog(
    context: parentContext,
    builder: (BuildContext dialogContext) {
      return _ConfirmDeleteWidget<T>(
        item: item,
        onDelete: onDelete,
        additionalWarning: additionalWarning,
      );
    },
  );
}
