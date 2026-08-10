// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// A tappable field showing the selected date with a trailing calendar icon.
/// [onTap] owns the `showDatePicker` call, so each caller keeps its own bounds.
class HeliumDateField extends StatelessWidget {
  final String? label;
  final DateTime? date;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String? semanticsLabel;

  const HeliumDateField({
    super.key,
    required this.onTap,
    this.label,
    this.date,
    this.backgroundColor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerFieldBox(
      label: label,
      valueText: date != null ? HeliumDateTime.formatDate(date!) : '',
      icon: Icons.calendar_today,
      semanticsLabel:
          semanticsLabel ?? (label != null ? 'Pick $label date' : 'Pick date'),
      backgroundColor: backgroundColor,
      onTap: onTap,
    );
  }
}

/// A tappable field showing the selected time with a trailing clock icon.
/// [onTap] owns the `showTimePicker` call, so each caller keeps its own bounds.
class HeliumTimeField extends StatelessWidget {
  final String? label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String? semanticsLabel;

  const HeliumTimeField({
    super.key,
    required this.onTap,
    this.label,
    this.time,
    this.backgroundColor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerFieldBox(
      label: label,
      valueText: time != null ? HeliumTime.format(time!) : '',
      icon: Icons.access_time,
      semanticsLabel:
          semanticsLabel ?? (label != null ? 'Pick $label time' : 'Pick time'),
      backgroundColor: backgroundColor,
      onTap: onTap,
    );
  }
}

class _PickerFieldBox extends StatelessWidget {
  final String? label;
  final String valueText;
  final IconData icon;
  final String semanticsLabel;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const _PickerFieldBox({
    required this.label,
    required this.valueText,
    required this.icon,
    required this.semanticsLabel,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final field = Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: () {
          Feedback.forTap(context);
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
            color: backgroundColor ?? context.colorScheme.surface,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(valueText, style: AppStyles.formText(context)),
              Icon(
                icon,
                color: context.colorScheme.primary,
                size: Responsive.getIconSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        field,
      ],
    );
  }
}
