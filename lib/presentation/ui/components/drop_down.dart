// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/app_style.dart';

class DropDown<T> extends StatelessWidget {
  static const _fieldBorderRadius = 8.0;
  static const _contentPadding = 12.0;
  static const _iconTextSpacing = 12.0;

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
        ? context.colorScheme.primary.withValues(alpha: 0.4)
        : context.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label!, style: AppStyles.formLabel(context)),
        if (label != null) const SizedBox(height: 9),
        Semantics(
          label: label,
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: isDisabled
                  ? context.theme.scaffoldBackgroundColor
                  : context.colorScheme.surface,
              borderRadius: BorderRadius.circular(_fieldBorderRadius),
            ),
            child: DropdownButtonFormField<DropDownItem<T>>(
            initialValue: initialValue,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: iconColor)
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _contentPadding,
                vertical: prefixIcon != null ? _contentPadding : 0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldBorderRadius),
                borderSide: BorderSide(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldBorderRadius),
                borderSide: BorderSide(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            style: AppStyles.formText(context),
            dropdownColor: context.colorScheme.surface,
            icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
            isExpanded: true,
            validator: validator,
            items: items.map((item) {
              if (item.isDivider) {
                return DropdownMenuItem<DropDownItem<T>>(
                  enabled: false,
                  value: item,
                  child: const Divider()
                );
              }
              return DropdownMenuItem<DropDownItem<T>>(
                value: item,
                child: Row(
                  children: [
                    if (item.iconData != null) ...[
                      Icon(item.iconData, color: item.iconColor ?? iconColor),
                      const SizedBox(width: _iconTextSpacing),
                    ],
                    Text(
                      item.label,
                      style: AppStyles.formText(context),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          ),
        ),
      ],
    );
  }
}
