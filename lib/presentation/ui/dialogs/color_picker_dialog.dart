// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
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
  static const _containerBorderRadius = 8.0;
  static const _containerPadding = 12.0;
  static const _shadowBlurRadius = 10.0;
  static const _shadowOffset = Offset(0, 2);
  static const _presetPickerWidth = 255.0;
  static const _presetPickerHeight = 295.0;
  static const _presetCheckIconSize = 15.0;
  static const _buttonIconSize = 18.0;
  static const _swatchBorderRadius = 4.0;
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
        padding: const EdgeInsets.all(_containerPadding),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(_containerBorderRadius),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: _shadowBlurRadius,
              offset: _shadowOffset,
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
          width: _presetPickerWidth,
          height: _presetPickerHeight,
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
              return InkWell(
                onTap: () {
                  Feedback.forTap(context);
                  changeColor();
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(_swatchBorderRadius),
                      border: Border.all(
                        color: context.colorScheme.outline.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: isCurrentColor
                        ? Icon(
                            Icons.check,
                            color: HeliumColors.contrastingTextColor(color),
                            size: _presetCheckIconSize,
                          )
                        : null,
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
          child: TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = true;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.color_lens_outlined,
                  size: 18,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Custom color',
                  style: TextStyle(color: context.colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: context.colorScheme.primary),
              ],
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
                size: _buttonIconSize,
                color: context.colorScheme.primary,
              ),
              label: Text(
                'Presets',
                style: TextStyle(color: context.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HeliumElevatedButton(
                onPressed: widget.onCancel,
                backgroundColor: context.colorScheme.outline,
                buttonText: 'Cancel',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HeliumElevatedButton(
                onPressed: () => widget.onSelect(pickerColor),
                buttonText: 'Select',
              ),
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
