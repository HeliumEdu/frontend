// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'app_colors.dart';

class CustomColorPickerWidget extends StatefulWidget {
  final Color? initialColor;
  final Function(Color) onColorSelected;

  const CustomColorPickerWidget({
    super.key,
    this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<CustomColorPickerWidget> createState() =>
      _CustomColorPickerWidgetState();
}

class _CustomColorPickerWidgetState extends State<CustomColorPickerWidget> {
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
            color: blackColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Color',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: blackColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 240,
            height: 140, // Fixed height to prevent intrinsic dimension issues
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                setState(() {
                  pickerColor = color;
                });
                widget.onColorSelected(color);
              },
              // HeliumEdu API valid colors (Google Calendar palette - lowercase hex)
              availableColors: const [
                Color(0xFFac725e), // #ac725e - Brown
                Color(0xFFd06b64), // #d06b64 - Light Red
                Color(0xFFf83a22), // #f83a22 - Red
                Color(0xFFfa573c), // #fa573c - Orange Red
                Color(0xFFffad46), // #ffad46 - Orange
                Color(0xFF42d692), // #42d692 - Mint Green
                Color(0xFF16a765), // #16a765 - Green
                Color(0xFF7bd148), // #7bd148 - Light Green
                Color(0xFFb3dc6c), // #b3dc6c - Yellow Green
                Color(0xFFfad165), // #fad165 - Light Yellow
                Color(0xFF92e1c0), // #92e1c0 - Turquoise
                Color(0xFF9fe1e7), // #9fe1e7 - Light Cyan
                Color(0xFF9fc6e7), // #9fc6e7 - Sky Blue
                Color(0xFF4986e7), // #4986e7 - Blue
                Color(0xFF9a9cff), // #9a9cff - Periwinkle
                Color(0xFFb99aff), // #b99aff - Light Purple
                Color(0xFFc2c2c2), // #c2c2c2 - Gray
                Color(0xFFcabdbf), // #cabdbf - Beige
                Color(0xFFcca6ac), // #cca6ac - Pink Gray
                Color(0xFFf691b2), // #f691b2 - Pink
                Color(0xFFcd74e6), // #cd74e6 - Purple
                Color(0xFFa47ae2), // #a47ae2 - Lavender
              ],
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
                        ? const Icon(Icons.check, color: whiteColor, size: 20)
                        : null,
                  ),
                );
              },
              layoutBuilder: (context, colors, child) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
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
