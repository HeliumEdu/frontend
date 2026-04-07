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
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

/// Options presented when a user taps a course schedule event on the planner
class CourseScheduleEventActions {
  /// Called when the user taps "Skip this class". Receives the occurrence date.
  final Future<void> Function(DateTime date)? onSkip;

  /// If non-null, an "Open class website" option is shown
  final String? websiteUrl;

  /// Called when the user taps "Edit class schedule"
  final VoidCallback onEditSchedule;

  const CourseScheduleEventActions({
    this.onSkip,
    this.websiteUrl,
    required this.onEditSchedule,
  });
}

/// Shows an adaptive action menu for a course schedule event.
///
/// On mobile this uses a bottom sheet. On desktop a centered dialog is used
/// because SfCalendar's onTap callback provides no pixel position for the
/// tapped tile, making a reliably-anchored popup menu impossible.
void showCourseScheduleEventDialog({
  required BuildContext context,
  required String courseTitle,
  required Color courseColor,
  required DateTime occurrenceDate,
  required CourseScheduleEventActions actions,
}) {
  final isMobile = Responsive.isMobile(context);

  Widget buildContent(BuildContext menuContext, StateSetter setMenuState) {
    return Material(
      color: menuContext.colorScheme.surface,
      borderRadius: isMobile
          ? const BorderRadius.vertical(top: Radius.circular(16))
          : BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppConstants.courseScheduleIcon,
                        size: 14,
                        color: courseColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          courseTitle,
                          style: AppStyles.formText(menuContext).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isMobile)
                        IconButton(
                          onPressed: () => Navigator.of(menuContext).pop(),
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: menuContext.colorScheme.primary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: menuContext.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        HeliumDateTime.formatDate(occurrenceDate),
                        style: AppStyles.formText(menuContext).copyWith(
                          color: menuContext.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            if (actions.onSkip != null)
              _buildMenuItem(
                context: menuContext,
                icon: Icons.block_outlined,
                label: 'Skip this class',
                iconColor: menuContext.colorScheme.error,
                onTap: () async {
                  Navigator.pop(menuContext);
                  await actions.onSkip!(occurrenceDate);
                },
              ),
            _buildMenuItem(
              context: menuContext,
              icon: Icons.edit_outlined,
              label: 'Edit class schedule',
              onTap: () {
                Navigator.pop(menuContext);
                actions.onEditSchedule();
              },
            ),
            if (actions.websiteUrl != null && actions.websiteUrl!.isNotEmpty)
              _buildMenuItem(
                context: menuContext,
                icon: Icons.launch_outlined,
                label: 'Open class website',
                iconColor: menuContext.semanticColors.success,
                onTap: () {
                  Navigator.pop(menuContext);
                  UrlHelpers.launchWebUrl(actions.websiteUrl!);
                },
              ),
            if (isMobile) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(builder: buildContent),
    );
  } else {
    // SfCalendar's onTap callback provides no pixel position for the tapped
    // tile, so anchoring a popup menu is not reliable. A centered dialog is
    // the appropriate pattern here.
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 320,
          child: StatefulBuilder(builder: buildContent),
        ),
      ),
    );
  }
}

Widget _buildMenuItem({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  Color? iconColor,
}) {
  return ListTile(
    leading: Icon(
      icon,
      color: iconColor ?? context.colorScheme.primary,
      size: 20,
    ),
    title: Text(label, style: AppStyles.formText(context)),
    onTap: onTap,
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
