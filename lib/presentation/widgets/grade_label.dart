// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class GradeLabel extends StatelessWidget {
  final String grade;
  final UserSettingsModel userSettings;
  final bool compact;

  const GradeLabel({
    super.key,
    required this.grade,
    required this.userSettings,
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
              color: userSettings.gradeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.assignment_turned_in_outlined,
                // TODO: Known Issues (6/Low): Use dynamic icon color based on gradeColor luminance to prevent visibility issues with light user-selected colors
                color: Colors.white,
                size: Responsive.getIconSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 16,
                ),
              ),
            ),
          ),
          Container(
            width: Responsive.isMobile(context) ? 64 : 70,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: userSettings.gradeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              border: Border.all(
                color: userSettings.gradeColor.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: SelectableText(
                grade,
                style:
                    (compact
                            ? AppStyles.smallSecondaryText(context)
                            : AppStyles.standardBodyText(context))
                        .copyWith(color: userSettings.gradeColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
