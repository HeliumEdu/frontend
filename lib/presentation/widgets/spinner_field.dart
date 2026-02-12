// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class SpinnerField extends StatelessWidget {
  final String? label;
  final TextEditingController controller;
  final double minValue;
  final double? maxValue;
  final double step;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const SpinnerField({
    super.key,
    this.label,
    required this.controller,
    this.minValue = 0,
    this.maxValue,
    this.step = 1,
    this.allowDecimal = false,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label!, style: AppStyles.formLabel(context)),
        if (label != null) const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  border: Border.all(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: allowDecimal
                        ? [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ]
                        : [FilteringTextInputFormatter.digitsOnly],
                    style: AppStyles.formText(context),
                    validator: validator,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        controller.text = _formatValue(minValue);
                      }
                      onChanged?.call(value);
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      errorStyle: AppStyles.formErrorStyle(context),
                      errorMaxLines: 3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _increment(),
                  icon: const Icon(Icons.arrow_drop_up),
                  iconSize: Responsive.getIconSize(
                    context,
                    mobile: 24,
                    tablet: 26,
                    desktop: 28,
                  ),
                  color: context.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                IconButton(
                  onPressed: () => _decrement(),
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: Responsive.getIconSize(
                    context,
                    mobile: 24,
                    tablet: 26,
                    desktop: 28,
                  ),
                  color: context.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _increment() {
    final currentValue = double.tryParse(controller.text) ?? minValue;
    final newValue = currentValue + step;
    if (maxValue == null || newValue <= maxValue!) {
      controller.text = _formatValue(newValue);
      onChanged?.call(controller.text);
    }
  }

  void _decrement() {
    final currentValue = double.tryParse(controller.text) ?? minValue;
    final newValue = currentValue - step;
    if (newValue >= minValue) {
      controller.text = _formatValue(newValue);
      onChanged?.call(controller.text);
    }
  }

  String _formatValue(double value) {
    if (allowDecimal) {
      return value.toString().replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
    } else {
      return value.toInt().toString();
    }
  }
}
