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

class SuccessContainer extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const SuccessContainer({
    super.key,
    required this.text,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final successColor = context.semanticColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.check_circle_outline_rounded,
            color: successColor,
            size: Responsive.getIconSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              text,
              style: AppStyles.standardBodyText(
                context,
              ).copyWith(color: successColor),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: successColor,
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
