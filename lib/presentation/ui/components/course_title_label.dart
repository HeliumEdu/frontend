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

class CourseTitleLabel extends StatelessWidget {
  final String title;
  final Color color;
  final bool showIcon;
  final bool compact;
  final IconData? icon;
  final VoidCallback? onDelete;

  const CourseTitleLabel({
    super.key,
    required this.title,
    required this.color,
    this.showIcon = true,
    this.compact = false,
    this.icon,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showIcon)
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
                  icon ?? Icons.school_outlined,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: BadgeColors.background(context, color),
                borderRadius: showIcon
                    ? const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      )
                    : BorderRadius.circular(10),
                border: Border.all(color: BadgeColors.border(context, color)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: (compact
                              ? AppStyles.smallSecondaryText(context)
                              : AppStyles.standardBodyText(context))
                          .copyWith(color: BadgeColors.foreground(context, color)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 2),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.close),
                      iconSize: Responsive.getIconSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: BadgeColors.foreground(context, color),
                      hoverColor: BadgeColors.border(context, color),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
