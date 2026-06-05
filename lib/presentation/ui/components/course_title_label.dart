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
  final String onDeleteLabel;

  const CourseTitleLabel({
    super.key,
    required this.title,
    required this.color,
    this.showIcon = true,
    this.compact = false,
    this.icon,
    this.onDelete,
    this.onDeleteLabel = 'Remove',
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
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.getResponsiveValue(
                  context,
                  mobile: 6,
                  desktop: 5,
                ),
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
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
              decoration: BoxDecoration(
                color: BadgeColors.background(context, color),
                borderRadius: showIcon
                    ? const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      )
                    : BorderRadius.circular(20),
                border: Border.all(color: BadgeColors.border(context, color)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 10,
                        vertical: compact ? 2 : 6,
                      ),
                      child: Text(
                        title,
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
                  ),
                  if (onDelete != null) ...[
                    Container(
                      width: 1,
                      color: BadgeColors.border(context, color),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDelete,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Semantics(
                          label: onDeleteLabel,
                          button: true,
                          child: Tooltip(
                            message: onDeleteLabel,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Center(
                                child: Icon(
                                  Icons.close,
                                  size: Responsive.getIconSize(
                                    context,
                                    mobile: 16,
                                    tablet: 18,
                                    desktop: 20,
                                  ),
                                  color: BadgeColors.foreground(context, color),
                                ),
                              ),
                            ),
                          ),
                        ),
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
