// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/url_helpers.dart';

class SupportHeliumCard extends StatelessWidget {
  static const _cardBorderRadius = 16.0;
  static const _cardPadding = 16.0;
  static const _iconSize = 32.0;
  static const _arrowIconSize = 16.0;

  const SupportHeliumCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary.withValues(alpha: 0.08),
            context.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => UrlHelpers.launchWebUrl(AppConstants.patreonUrl),
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: Row(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: context.colorScheme.primary,
                  size: _iconSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep Helium Free',
                        style: AppStyles.menuItem(
                          context,
                        ).copyWith(color: context.colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        compact
                            ? 'A passion project, free for everyone—made '
                                  'possible by supporters like you.'
                            : 'A passion project, free for everyone. '
                                  'Supporters like you are what make that '
                                  'possible, covering real costs like hosting '
                                  'and app store fees.',
                        style: AppStyles.menuItemHint(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: _arrowIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
