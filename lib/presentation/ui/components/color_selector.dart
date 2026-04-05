// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/utils/app_style.dart';

/// A labeled color swatch that opens a [showColorPickerDialog] on tap.
///
/// If [label] is provided, renders as a [Row] with the label on the left
/// and the swatch on the right. If omitted, renders only the swatch.
class ColorSelector extends StatelessWidget {
  final String? label;
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorSelector({
    super.key,
    this.label,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = InkWell(
      onTap: () {
        Feedback.forTap(context);
        showColorPickerDialog(
          parentContext: context,
          initialColor: selectedColor,
          onSelected: onColorSelected,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 33,
        height: 33,
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
    );

    if (label == null) return swatch;

    return Row(
      children: [
        Text(label!, style: AppStyles.formLabel(context)),
        const SizedBox(width: 12),
        swatch,
      ],
    );
  }
}
