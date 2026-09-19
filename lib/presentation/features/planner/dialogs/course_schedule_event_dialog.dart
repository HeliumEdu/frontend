import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/planner_item_action_dialog.dart';
import 'package:heliumapp/utils/app_globals.dart';
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
void showCourseScheduleEventDialog({
  required BuildContext context,
  required String courseTitle,
  required Color courseColor,
  required DateTime occurrenceDate,
  required CourseScheduleEventActions actions,
}) {
  showPlannerItemActionDialog(
    context: context,
    icon: AppConstants.courseScheduleIcon,
    title: courseTitle,
    color: courseColor,
    occurrenceDate: occurrenceDate,
    actions: [
      if (actions.onSkip != null)
        PlannerItemAction(
          icon: Icons.block_outlined,
          label: 'Skip this class',
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
