// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';

class HeliumElevatedButton extends StatelessWidget {
  final String buttonText;
  final IconData? icon;
  final Color? iconColor;
  final Function onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? backgroundColor;

  const HeliumElevatedButton({
    super.key,
    required this.buttonText,
    this.icon,
    this.iconColor,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.colorScheme.onPrimary;

    return ElevatedButton.icon(
      onPressed: isLoading || !enabled ? null : () => {onPressed()},
      icon: icon != null
          ? Icon(icon, size: 16, color: effectiveIconColor)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: !isLoading && enabled
            ? backgroundColor ?? context.colorScheme.primary
            : context.colorScheme.onSurface.withValues(alpha: 0.12),
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      label: isLoading
          ? LoadingIndicator(
              small: true,
              color: context.colorScheme.onSurface.withValues(alpha: 0.38),
            )
          : Text(
              buttonText,
              style: enabled
                  ? AppStyles.buttonText(context)
                  : AppStyles.buttonText(context).copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
            ),
    );
  }
}
