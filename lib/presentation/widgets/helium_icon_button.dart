// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class HeliumIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;
  final double? size;

  const HeliumIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final useColor = color ?? context.colorScheme.primary;
    final useSize =
        size ??
        Responsive.getIconSize(context, mobile: 20, tablet: 22, desktop: 24);

    return IconButton.filled(
      style: ButtonStyle(
        shape: WidgetStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        backgroundColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return useColor.withValues(alpha: 0.4);
          }
          return useColor.withValues(alpha: 0.2);
        }),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: useColor, size: useSize),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
  }
}
