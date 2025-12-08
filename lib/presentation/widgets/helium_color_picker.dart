// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:helium_mobile/utils/app_colors.dart';

class HeliumColorPickerWidget extends StatefulWidget {
  final Color? initialColor;
  final Function(Color) onColorSelected;

  const HeliumColorPickerWidget({
    super.key,
    this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<HeliumColorPickerWidget> createState() =>
      _HeliumColorPickerWidgetState();
}

class _HeliumColorPickerWidgetState extends State<HeliumColorPickerWidget> {
  late Color pickerColor;

  @override
  void initState() {
    super.initState();
    pickerColor = widget.initialColor ?? Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: blackColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
                widget.onColorSelected(color);
              },
              availableColors: preferredColors,
              itemBuilder: (color, isCurrentColor, changeColor) {
                return GestureDetector(
                  onTap: changeColor,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: greyColor, width: 1),
                    ),
                    child: isCurrentColor
                        ? const Icon(Icons.check, color: whiteColor, size: 15)
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
        ],
      ),
    );
  }
}
