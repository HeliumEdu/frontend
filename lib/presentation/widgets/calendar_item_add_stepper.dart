// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_attachment_screen.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_reminder_screen.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_add_screen.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/views/core/dialog_step_navigation.dart';
import 'package:heliumapp/presentation/widgets/shadow_container.dart';

enum CalendarItemAddSteps {
  details(Icons.list, AppRoutes.plannerItemAddScreen),
  reminders(
    Icons.notifications_active_outlined,
    AppRoutes.plannerItemAddRemindersScreen,
  ),
  attachments(
    Icons.attachment_outlined,
    AppRoutes.plannerItemAddAttachmentsScreen,
  );

  final IconData icon;
  final String route;

  const CalendarItemAddSteps(this.icon, this.route);

  /// Builds the widget for this step
  Widget buildWidget({
    int? eventId,
    int? homeworkId,
    DateTime? initialDate,
    bool isFromMonthView = false,
    required bool isEdit,
    required bool isNew,
  }) {
    final int? entityId = eventId ?? homeworkId;
    final bool isEvent = eventId != null;

    switch (this) {
      case CalendarItemAddSteps.details:
        return CalendarItemAddProvidedScreen(
          eventId: eventId,
          homeworkId: homeworkId,
          initialDate: initialDate,
          isFromMonthView: isFromMonthView,
          isEdit: isEdit,
          isNew: isNew,
        );
      case CalendarItemAddSteps.reminders:
        return CalendarItemAddReminderScreen(
          isEvent: isEvent,
          entityId: entityId!,
          isEdit: isEdit,
          isNew: isNew,
        );
      case CalendarItemAddSteps.attachments:
        return CalendarItemAddAttachmentScreen(
          isEvent: isEvent,
          entityId: entityId!,
          isEdit: isEdit,
          isNew: isNew,
        );
    }
  }
}

class CalendarItemStepper extends StatelessWidget {
  final int selectedIndex;
  final int? eventId;
  final int? homeworkId;
  final bool isEdit;
  final bool isNew;
  final void Function()? onStep;

  const CalendarItemStepper({
    super.key,
    required this.selectedIndex,
    this.eventId,
    this.homeworkId,
    required this.isEdit,
    required this.isNew,
    this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final dialogProvider = DialogModeProvider.maybeOf(context);

    // Use dialog width if available, otherwise use screen width
    final availableWidth = dialogProvider?.width ?? MediaQuery.sizeOf(context).width;
    final lineLength = (availableWidth - 275) / 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        child: EasyStepper(
          showTitle: false,
          lineStyle: LineStyle(
            lineLength: lineLength,
            lineThickness: 3.0,
            lineSpace: 4,
            lineType: LineType.normal,
            defaultLineColor: context.colorScheme.outline.withValues(
              alpha: 0.1,
            ),
            finishedLineColor: context.colorScheme.primary,
            activeLineColor: context.colorScheme.primary.withValues(alpha: 0.5),
          ),
          activeStepIconColor: context.colorScheme.surface,
          activeStepTextColor: context.colorScheme.primary,
          finishedStepBorderColor: context.colorScheme.primary,
          finishedStepBackgroundColor: context.colorScheme.primary.withValues(
            alpha: 0.1,
          ),
          finishedStepIconColor: context.colorScheme.primary,
          unreachedStepBorderColor: context.colorScheme.outline.withValues(
            alpha: 0.1,
          ),
          unreachedStepBackgroundColor: Theme.of(
            context,
          ).scaffoldBackgroundColor,
          unreachedStepIconColor: context.colorScheme.outline,
          unreachedStepTextColor: context.colorScheme.onSurface.withValues(
            alpha: 0.1,
          ),
          internalPadding: 12,
          showLoadingAnimation: false,
          stepRadius: 30,
          showStepBorder: true,
          disableScroll: true,
          activeStep: selectedIndex,
          onStepReached: (index) => _onStepReached(context, index),
          steps: _buildSteps(context, 25),
        ),
      ),
    );
  }

  void _onStepReached(BuildContext context, int index) {
    if (index == selectedIndex) return;

    onStep?.call();

    // Try to navigate within dialog first
    if (navigateStepInDialog(context, index)) {
      return;
    }

    // Fall back to router navigation for non-dialog mode
    final step = CalendarItemAddSteps.values[index];
    final calendarItemBloc = context.read<CalendarItemBloc>();
    final attachmentBloc = context.read<AttachmentBloc>();
    final entityId = eventId ?? homeworkId;

    // Can't navigate to reminders/attachments without an entity
    if (index != CalendarItemAddSteps.details.index && entityId == null) {
      return;
    }

    if (index == CalendarItemAddSteps.details.index) {
      context.pushReplacement(
        step.route,
        extra: CalendarItemAddArgs(
          calendarItemBloc: calendarItemBloc,
          eventId: eventId,
          homeworkId: homeworkId,
          isEdit: isEdit,
          isNew: isNew,
        ),
      );
    } else if (index == CalendarItemAddSteps.reminders.index) {
      context.pushReplacement(
        step.route,
        extra: CalendarItemReminderArgs(
          calendarItemBloc: calendarItemBloc,
          isEvent: eventId != null,
          entityId: entityId!,
          isEdit: isEdit,
          isNew: isNew,
        ),
      );
    } else if (index == CalendarItemAddSteps.attachments.index) {
      context.pushReplacement(
        step.route,
        extra: CalendarItemAttachmentArgs(
          calendarItemBloc: calendarItemBloc,
          attachmentBloc: attachmentBloc,
          isEvent: eventId != null,
          entityId: entityId!,
          isEdit: isEdit,
          isNew: isNew,
        ),
      );
    }
  }

  List<EasyStep> _buildSteps(BuildContext context, double iconSize) {
    return [
      EasyStep(
        customStep: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary.withValues(
              alpha: selectedIndex == CalendarItemAddSteps.details.index
                  ? 1
                  : 0.1,
            ),
            border: Border.all(color: context.colorScheme.primary, width: 2),
          ),
          child: Center(
            child: Icon(
              CalendarItemAddSteps.details.icon,
              color: selectedIndex == CalendarItemAddSteps.details.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary,
              size: iconSize,
            ),
          ),
        ),
      ),
      EasyStep(
        enabled: isEdit,
        customStep: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary.withValues(
              alpha: selectedIndex == CalendarItemAddSteps.reminders.index
                  ? 1
                  : 0.1,
            ),
            border: Border.all(
              color: context.colorScheme.primary.withValues(
                alpha: isEdit ? 1 : 0.3,
              ),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              CalendarItemAddSteps.reminders.icon,
              color: selectedIndex == CalendarItemAddSteps.reminders.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
              size: iconSize,
            ),
          ),
        ),
      ),
      EasyStep(
        enabled: isEdit,
        customStep: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary.withValues(
              alpha: selectedIndex == CalendarItemAddSteps.attachments.index
                  ? 1
                  : 0.1,
            ),
            border: Border.all(
              color: context.colorScheme.primary.withValues(
                alpha: isEdit ? 1 : 0.3,
              ),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              CalendarItemAddSteps.attachments.icon,
              color: selectedIndex == CalendarItemAddSteps.attachments.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary.withValues(
                      alpha: isEdit ? 1 : 0.3,
                    ),
              size: iconSize,
            ),
          ),
        ),
      ),
    ];
  }
}
