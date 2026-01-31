// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/app_style.dart';

class DropDown<T> extends StatelessWidget {
  final String? label;
  final IconData? prefixIcon;
  final DropDownItem<T>? initialValue;
  final List<DropDownItem<T>> items;
  final void Function(DropDownItem<T>?)? onChanged;
  final String? Function(DropDownItem<T>?)? validator;

  const DropDown({
    super.key,
    this.label,
    this.prefixIcon,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    final iconColor = isDisabled
        ? context.colorScheme.onSurface.withValues(alpha: 0.4)
        : context.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label!, style: context.formLabel),
        if (label != null) const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: isDisabled
                ? context.theme.scaffoldBackgroundColor
                : context.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<DropDownItem<T>>(
            initialValue: initialValue,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: iconColor)
                  : null,
              contentPadding: EdgeInsets.only(
                top: prefixIcon != null ? 12 : 0,
                left: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            style: context.formText,
            dropdownColor: context.colorScheme.surface,
            icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
            isExpanded: true,
            items: items.map((item) {
              return DropdownMenuItem<DropDownItem<T>>(
                value: item,
                child: Row(
                  children: [
                    if (item.iconData != null) ...[
                      Icon(item.iconData, color: item.iconColor ?? iconColor),
                      const SizedBox(width: 10),
                    ],
                    Text(item.value.toString(), style: context.formText),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
