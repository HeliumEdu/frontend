// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class _ColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onSelect;
  final VoidCallback onCancel;

  const _ColorPickerWidget({
    required this.initialColor,
    required this.onSelect,
    required this.onCancel,
  });

  @override
  State<_ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<_ColorPickerWidget> {
  late Color pickerColor;
  late bool _isExpanded;

  bool _isPresetColor(Color color) {
    return HeliumColors.preferredColors.any(
      (preset) => preset.toARGB32() == color.toARGB32(),
    );
  }

  @override
  void initState() {
    super.initState();

    pickerColor = widget.initialColor;
    _isExpanded = !_isPresetColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colorScheme.surface,
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isExpanded
            ? _buildFullPicker(context)
            : _buildPresetPicker(context),
      ),
    );
  }

  Widget _buildPresetPicker(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 255,
          height: 295,
          child: BlockPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              setState(() {
                pickerColor = color;
              });
              widget.onSelect(color);
            },
            availableColors: HeliumColors.preferredColors,
            itemBuilder: (color, isCurrentColor, changeColor) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Feedback.forTap(context);
                    changeColor();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: context.colorScheme.outline.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: isCurrentColor
                        ? Icon(
                            Icons.check,
                            color: context.colorScheme.onPrimary,
                            size: 15,
                          )
                        : null,
                  ),
                ),
              );
            },
            layoutBuilder: (context, colors, child) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 6,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                children: [for (Color color in colors) child(color)],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _isExpanded = true;
              });
            },
            icon: Icon(
              Icons.color_lens_outlined,
              size: 18,
              color: context.colorScheme.primary,
            ),
            label: Text(
              'Custom color...',
              style: TextStyle(color: context.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullPicker(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              setState(() {
                pickerColor = color;
              });
            },
            enableAlpha: false,
            hexInputBar: true,
            displayThumbColor: true,
            portraitOnly: true,
            labelTypes: const [],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              icon: Icon(
                Icons.arrow_back,
                size: 18,
                color: context.colorScheme.primary,
              ),
              label: Text(
                'Presets',
                style: TextStyle(color: context.colorScheme.primary),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => widget.onSelect(pickerColor),
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> showColorPickerDialog({
  required BuildContext parentContext,
  required Function(Color) onSelected,
  required Color initialColor,
}) {
  return showDialog(
    context: parentContext,
    builder: (BuildContext dialogContext) {
      return _ColorPickerWidget(
        initialColor: initialColor,
        onSelect: (color) {
          Navigator.of(dialogContext).pop();
          onSelected(color);
        },
        onCancel: () {
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );
}
