// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';

class HeliumElevatedButton extends StatelessWidget {
  static const _buttonBorderRadius = 6.0;
  static const _buttonMinHeight = 45.0;
  static const _buttonHorizontalPadding = 12.0;
  static const _iconSize = 16.0;
  static const _loadingIndicatorSize = 20.0;
  static const _loadingIndicatorStrokeWidth = 2.5;

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

  static ButtonStyle baseStyle(
    ColorScheme colorScheme, {
    Color? backgroundColor,
    double minimumWidth = double.infinity,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        backgroundColor ?? colorScheme.primary,
      ),
      foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
      minimumSize: WidgetStatePropertyAll(Size(minimumWidth, _buttonMinHeight)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: _buttonHorizontalPadding),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonBorderRadius)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.colorScheme.onPrimary;
    final effectiveBg = !isLoading && enabled
        ? backgroundColor ?? context.colorScheme.primary
        : context.colorScheme.onSurface.withValues(alpha: 0.12);

    return ElevatedButton.icon(
      onPressed: isLoading || !enabled ? null : () => {onPressed()},
      icon: !isLoading && icon != null
          ? Icon(icon, size: _iconSize, color: effectiveIconColor)
          : null,
      style: baseStyle(
        context.colorScheme,
        backgroundColor: effectiveBg,
      ).copyWith(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      label: isLoading
          ? LoadingIndicator(
              size: _loadingIndicatorSize,
              strokeWidth: _loadingIndicatorStrokeWidth,
              expanded: false,
              color: context.colorScheme.onSurface.withValues(alpha: 0.38),
            )
          : Text(
              buttonText,
              style: enabled
                  ? AppStyles.buttonText(context)
                  : AppStyles.buttonText(context).copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                    ),
            ),
    );
  }
}
