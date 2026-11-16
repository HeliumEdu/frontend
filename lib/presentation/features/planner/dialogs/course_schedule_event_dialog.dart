import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/planner_item_action_dialog.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

/// Options presented when a user taps a course schedule event on the planner
class CourseScheduleEventActions {
  /// Called when the user skips every meeting the class has that day. Receives
  /// the occurrence date.
  final Future<void> Function(DateTime date)? onSkip;

  final Future<void> Function(DateTime date)? onSkipMeeting;

  /// If non-null, an "Open class website" option is shown
  final String? websiteUrl;

  /// Called when the user taps "Edit class schedule"
  final VoidCallback onEditSchedule;

  const CourseScheduleEventActions({
    this.onSkip,
    this.onSkipMeeting,
    this.websiteUrl,
    required this.onEditSchedule,
  });
}

/// Shows an adaptive action menu for a course schedule event.
void showCourseScheduleEventDialog({
  required BuildContext context,
  required String courseTitle,
  required Color courseColor,
  required DateTime occurrenceDate,
  required String whenLabel,
  required CourseScheduleEventActions actions,
}) {
  final meetsMoreThanOnce = actions.onSkipMeeting != null;
  showPlannerItemActionDialog(
    context: context,
    icon: AppConstants.courseScheduleIcon,
    title: courseTitle,
    color: courseColor,
    whenLabel: whenLabel,
    actions: [
      if (meetsMoreThanOnce)
        PlannerItemAction(
          icon: Icons.block_outlined,
          label: 'Skip this meeting',
          iconColor: context.colorScheme.error,
          onTap: () => actions.onSkipMeeting!(occurrenceDate),
        ),
      if (actions.onSkip != null)
        PlannerItemAction(
          icon: meetsMoreThanOnce
              ? Icons.event_busy_outlined
              : Icons.block_outlined,
          label: meetsMoreThanOnce
              ? 'Skip all meetings on ${HeliumDateTime.formatDate(occurrenceDate, showYear: false)}'
              : 'Skip this class',
          iconColor: context.colorScheme.error,
          onTap: () => actions.onSkip!(occurrenceDate),
        ),
      PlannerItemAction(
        icon: Icons.edit_outlined,
        label: 'Edit class schedule',
        onTap: actions.onEditSchedule,
      ),
      if (actions.websiteUrl != null && actions.websiteUrl!.isNotEmpty)
        PlannerItemAction(
          icon: Icons.launch_outlined,
          label: 'Open class website',
          iconColor: context.semanticColors.success,
          onTap: () => UrlHelpers.launchWebUrl(actions.websiteUrl!),
        ),
    ],
  );
}
