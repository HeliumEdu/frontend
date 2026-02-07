// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class ErrorContainer extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const ErrorContainer({
    super.key,
    required this.text,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = context.colorScheme.error.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.error_outline_rounded,
            color: errorColor,
            size: Responsive.getIconSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppStyles.standardBodyText(
                context,
              ).copyWith(color: errorColor),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: errorColor,
                size: Responsive.getIconSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
