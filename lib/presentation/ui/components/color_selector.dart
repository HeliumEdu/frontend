import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/utils/app_style.dart';

/// A labeled color swatch that opens a [showColorPickerDialog] on tap.
///
/// If [label] is provided, renders as a [Row] with the label on the left
/// and the swatch on the right, the label in a [labelWidth] column when given
/// so a stack of selectors lines up. If omitted, renders only the swatch.
class ColorSelector extends StatelessWidget {
  final String? label;
  final double? labelWidth;
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorSelector({
    super.key,
    this.label,
    this.labelWidth,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: () {
          showColorPickerDialog(
            parentContext: context,
            initialColor: selectedColor,
            onSelected: onColorSelected,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selectedColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );

    if (label == null) return swatch;

    final labelText = ExcludeSemantics(
      child: Text(label!, style: AppStyles.formLabel(context)),
    );

    return Row(
      children: [
        if (labelWidth != null)
          SizedBox(width: labelWidth, child: labelText)
        else ...[
          labelText,
          const SizedBox(width: 12),
        ],
        swatch,
      ],
    );
  }
}
