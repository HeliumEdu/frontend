// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';

class PillBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const PillBadge({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? context.semanticColors.success).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: (color ?? context.semanticColors.success).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.smallSecondaryText(context).copyWith(
          color: color ?? context.semanticColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
