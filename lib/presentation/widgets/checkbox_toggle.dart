// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/app_style.dart';

class CheckboxToggle extends StatelessWidget {
  final bool isChecked;
  final bool isToggleOn;
  final String baseLabel;
  final String toggleOnLabel;
  final String toggleOffLabel;
  final ValueChanged<bool?> onCheckedChanged;
  final ValueChanged<bool> onToggleChanged;
  final VoidCallback onToggleTapWhenDisabled;

  const CheckboxToggle({
    super.key,
    required this.isChecked,
    required this.isToggleOn,
    required this.baseLabel,
    required this.toggleOnLabel,
    required this.toggleOffLabel,
    required this.onCheckedChanged,
    required this.onToggleChanged,
    required this.onToggleTapWhenDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final label = isChecked
        ? (isToggleOn ? toggleOnLabel : toggleOffLabel)
        : baseLabel;

    return CheckboxListTile(
      title: Text(label, style: AppStyles.formText(context)),
      value: isChecked,
      onChanged: onCheckedChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Only',
            style: AppStyles.smallSecondaryTextLight(
              context,
            ).copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: !isChecked ? onToggleTapWhenDisabled : null,
            child: Switch(
              value: isToggleOn,
              onChanged: isChecked ? onToggleChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
