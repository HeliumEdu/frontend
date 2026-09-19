import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/planner_item_action_dialog.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/url_helpers.dart';

/// Options presented when a user taps an external calendar event on the planner
class ExternalCalendarEventActions {
  /// Called when the user taps "Manage External Calendars"
  final VoidCallback onManageCalendars;

  /// If non-null, an "Open event link" option is shown
  final String? eventUrl;

  const ExternalCalendarEventActions({
    required this.onManageCalendars,
    this.eventUrl,
  });
}

/// Shows an adaptive action menu for an external calendar event.
void showExternalCalendarEventDialog({
  required BuildContext context,
  required String calendarTitle,
  required Color calendarColor,
  required DateTime occurrenceDate,
  required ExternalCalendarEventActions actions,
}) {
  showPlannerItemActionDialog(
    context: context,
    icon: AppConstants.externalCalendarIcon,
    title: calendarTitle,
    color: calendarColor,
    occurrenceDate: occurrenceDate,
    actions: [
      PlannerItemAction(
        icon: Icons.settings_outlined,
        label: 'Manage External Calendars',
        onTap: actions.onManageCalendars,
      ),
      if (actions.eventUrl != null && actions.eventUrl!.isNotEmpty)
        PlannerItemAction(
          icon: Icons.launch_outlined,
          label: 'Open event link',
          iconColor: context.semanticColors.success,
          onTap: () => UrlHelpers.launchWebUrl(actions.eventUrl!),
        ),
    ],
  );
}
