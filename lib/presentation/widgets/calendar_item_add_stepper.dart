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
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/config/app_theme.dart';

enum CalendarItemAddSteps {
  details('Details', Icons.menu_book),
  reminders('Reminders', Icons.notifications_active_outlined),
  attachments('Attachments', Icons.attachment_outlined);

  final String label;
  final IconData icon;

  const CalendarItemAddSteps(this.label, this.icon);
}

class CalendarItemStepper extends StatelessWidget {
  final int selectedIndex;
  final int? eventId;
  final int? homeworkId;
  final bool isEdit;
  final void Function()? onStep;

  const CalendarItemStepper({
    super.key,
    required this.selectedIndex,
    this.eventId,
    this.homeworkId,
    required this.isEdit,
    this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // TODO: migrate to ShadowContainer for consistent usage (that doesn't require Card's InkWell baggage)
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: EasyStepper(
          lineStyle: LineStyle(
            lineLength: (MediaQuery.sizeOf(context).width - 275) / 3,
            lineThickness: 3,
            lineSpace: 4,
            lineType: LineType.normal,
            defaultLineColor: context.colorScheme.outline.withValues(alpha: 0.1),
            finishedLineColor: context.colorScheme.primary,
            activeLineColor: context.colorScheme.primary.withValues(alpha: 0.5),
          ),
          activeStepIconColor: context.colorScheme.surface,
          activeStepTextColor: context.colorScheme.primary,
          finishedStepBorderColor: context.colorScheme.primary,
          finishedStepBackgroundColor: context.colorScheme.primary.withValues(alpha: 0.1),
          finishedStepIconColor: context.colorScheme.primary,
          unreachedStepBorderColor: context.colorScheme.outline.withValues(alpha: 0.1),
          unreachedStepBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          unreachedStepIconColor: context.colorScheme.outline,
          unreachedStepTextColor: context.colorScheme.onSurface.withValues(alpha: 0.1),
          internalPadding: 12,
          showLoadingAnimation: false,
          stepRadius: 24,
          showStepBorder: true,
          disableScroll: true,
          activeStep: selectedIndex,
          onStepReached: (index) => _onStepReached(context, index),
          steps: _buildSteps(context),
        ),
      ),
    );
  }

  void _onStepReached(BuildContext context, int index) {
    if (index == selectedIndex) return;

    onStep?.call();

    final calendarItemBloc = context.read<CalendarItemBloc>();
    final entityId = eventId ?? homeworkId;

    if (index == CalendarItemAddSteps.details.index) {
      context.pushReplacement(
        AppRoutes.calendarItemAddScreen,
        extra: CalendarItemAddArgs(
          calendarItemBloc: calendarItemBloc,
          eventId: eventId,
          homeworkId: homeworkId,
          isEdit: isEdit,
        ),
      );
      return;
    }

    // Can't navigate to reminders/attachments without an entity
    if (entityId == null) return;

    if (index == CalendarItemAddSteps.reminders.index) {
      context.pushReplacement(
        AppRoutes.calendarItemAddRemindersScreen,
        extra: CalendarItemReminderArgs(
          calendarItemBloc: calendarItemBloc,
          isEvent: eventId != null,
          entityId: entityId,
          isEdit: isEdit,
        ),
      );
    }

    if (index == CalendarItemAddSteps.attachments.index) {
      context.pushReplacement(
        AppRoutes.calendarItemAddAttachmentsScreen,
        extra: CalendarItemAttachmentArgs(
          calendarItemBloc: calendarItemBloc,
          isEvent: eventId != null,
          entityId: entityId,
          isEdit: isEdit,
        ),
      );
    }
  }

  List<EasyStep> _buildSteps(BuildContext context) {
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
              size: 20,
            ),
          ),
        ),
        customTitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            CalendarItemAddSteps.details.label,
            style: selectedIndex == CalendarItemAddSteps.details.index
                ? context.stepperTitleActive
                : context.stepperTitle,
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
              color: context.colorScheme.primary.withValues(alpha: isEdit ? 1 : 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              CalendarItemAddSteps.reminders.icon,
              color: selectedIndex == CalendarItemAddSteps.reminders.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary.withValues(alpha: isEdit ? 1 : 0.3),
              size: 20,
            ),
          ),
        ),
        customTitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            CalendarItemAddSteps.reminders.label,
            style: selectedIndex == CalendarItemAddSteps.reminders.index
                ? context.stepperTitleActive
                : context.stepperTitle.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: isEdit ? 1 : 0.3),
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
              color: context.colorScheme.primary.withValues(alpha: isEdit ? 1 : 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              CalendarItemAddSteps.attachments.icon,
              color: selectedIndex == CalendarItemAddSteps.attachments.index
                  ? context.colorScheme.surface
                  : context.colorScheme.primary.withValues(alpha: isEdit ? 1 : 0.3),
              size: 20,
            ),
          ),
        ),
        customTitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            CalendarItemAddSteps.attachments.label,
            style: selectedIndex == CalendarItemAddSteps.attachments.index
                ? context.stepperTitleActive
                : context.stepperTitle.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: isEdit ? 1 : 0.3),
                  ),
          ),
        ),
      ),
    ];
  }
}
