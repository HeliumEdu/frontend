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

class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String title;
  final bool expanded;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.message,
    this.title = 'Nothing to see here',
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = context.colorScheme.onSurface;
    final content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Responsive.getIconSize(
                context,
                mobile: 60,
                tablet: 64,
                desktop: 68,
              ),
              color: onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: context.pageTitle.copyWith(
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.bodyText.copyWith(
                color: onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}
