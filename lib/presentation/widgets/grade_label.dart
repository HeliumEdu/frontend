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

  const GradeLabel({
    super.key,
    required this.grade,
    required this.userSettings,
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
            width: 65,
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
              child: Text(
                grade,
                style: context.cTextStyle.copyWith(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 14,
                    tablet: 14,
                    desktop: 14,
                  ),
                  color: userSettings.gradeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
