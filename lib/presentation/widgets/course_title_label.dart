// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class CourseTitleLabel extends StatelessWidget {
  final String title;
  final Color color;
  final bool showIcon;
  final bool compact;

  const CourseTitleLabel({
    super.key,
    required this.title,
    required this.color,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.school_outlined,
              color: color,
              size: Responsive.getIconSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              title,
              style:
                  (compact
                          ? AppStyles.smallSecondaryText(context)
                          : AppStyles.standardBodyText(context))
                      .copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
