// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class GenericLabel extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool compact;

  const GenericLabel({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: HeliumColors.contrastingTextColor(color),
                size: Responsive.getIconSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 10,
                vertical: compact ? 2 : 6,
              ),
              decoration: BoxDecoration(
                color: BadgeColors.background(context, color),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border.all(color: BadgeColors.border(context, color)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style:
                          (compact
                                  ? AppStyles.smallSecondaryText(context)
                                  : AppStyles.standardBodyText(context))
                              .copyWith(
                                color: BadgeColors.foreground(context, color),
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
