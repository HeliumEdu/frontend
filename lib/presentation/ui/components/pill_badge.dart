// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class PillBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const PillBadge({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.semanticColors.success;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveValue(context, mobile: 8, desktop: 10),
        vertical: Responsive.getResponsiveValue(context, mobile: 3, desktop: 4),
      ),
      decoration: BoxDecoration(
        color: BadgeColors.background(context, effectiveColor),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: BadgeColors.border(context, effectiveColor),
        ),
      ),
      child: Text(
        text,
        style: AppStyles.smallSecondaryText(context).copyWith(
          color: BadgeColors.foreground(context, effectiveColor),
        ),
      ),
    );
  }
}
