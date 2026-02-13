// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_state.dart';
import 'package:heliumapp/presentation/views/core/multi_step_container.dart';
import 'package:heliumapp/presentation/widgets/calendar/calendar_item_attachments_widget.dart';
import 'package:heliumapp/presentation/widgets/calendar/calendar_item_details_widget.dart';
import 'package:heliumapp/presentation/widgets/calendar/calendar_item_reminders_widget.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Shows calendar item add/edit as a dialog on desktop, or navigates on mobile
void showCalendarItemAdd(
  BuildContext context, {
  int? eventId,
  int? homeworkId,
  DateTime? initialDate,
  bool isFromMonthView = false,
  required bool isEdit,
  required bool isNew,
  int initialStep = 0,
  CalendarItemBloc? calendarItemBloc,
  AttachmentBloc? attachmentBloc,
}) {
  final calBloc = calendarItemBloc ?? context.read<CalendarItemBloc>();
  final attBloc = attachmentBloc ?? context.read<AttachmentBloc>();

  if (Responsive.isMobile(context)) {
    context.push(
      AppRoutes.plannerItemAddScreen,
      extra: CalendarItemAddArgs(
        calendarItemBloc: calBloc,
        attachmentBloc: attBloc,
        eventId: eventId,
        homeworkId: homeworkId,
        initialDate: initialDate,
        isFromMonthView: isFromMonthView,
        isEdit: isEdit,
        isNew: isNew,
      ),
    );
  } else {
    showScreenAsDialog(
      context,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CalendarItemBloc>.value(value: calBloc),
          BlocProvider<AttachmentBloc>.value(value: attBloc),
        ],
        child: CalendarItemAddScreen(
          eventId: eventId,
          homeworkId: homeworkId,
          initialDate: initialDate,
          isFromMonthView: isFromMonthView,
          isEdit: isEdit,
          isNew: isNew,
          initialStep: initialStep,
        ),
      ),
      width: AppConstants.centeredDialogWidth,
      alignment: Alignment.center,
    );
  }
}

class CalendarItemAddScreen extends MultiStepContainer {
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;

  const CalendarItemAddScreen({
    super.key,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    this.isFromMonthView = false,
    required super.isEdit,
    required super.isNew,
    super.initialStep = 0,
  });

  @override
  State<CalendarItemAddScreen> createState() => _CalendarItemAddScreenState();
}

class _CalendarItemAddScreenState
    extends MultiStepContainerState<CalendarItemAddScreen> {
  final _detailsKey = GlobalKey<CalendarItemDetailsWidgetState>();

  // State
  int? _currentEntityId;
  bool? _currentIsEvent;
  int? _targetStep;

  @override
  void initState() {
    super.initState();
    _currentEntityId = widget.eventId ?? widget.homeworkId;
    _currentIsEvent = widget.eventId != null;
  }

  @override
  bool get enableNextSteps => _currentEntityId != null;

  @override
  void onStepRequested(int step) {
    if (step == currentStep) return;

    if (saveAction != null) {
      _targetStep = step;
      saveAction!();

      // BlocListener will handle state transition after save
      return;
    }

    navigateToStep(step);
  }

  @override
  String get screenTitle {
    if (_currentIsEvent == null) return '';
    final itemType = _currentIsEvent! ? 'Event' : 'Assignment';
    return widget.isNew ? 'Add $itemType' : 'Edit $itemType';
  }

  @override
  IconData? get icon => _currentIsEvent == null ? null : Icons.calendar_month;

  @override
  Function? get saveAction {
    if (steps[currentStep].stepScreenType != ScreenType.entityPage) {
      return null;
    }
    if (currentStep != 0) return null;
    // Return function that evaluates widget state when called, not when getter runs
    return () {
      final widgetSubmit = _detailsKey.currentState?.onSubmit;
      if (widgetSubmit != null) {
        setState(() => isSubmitting = true);
        widgetSubmit();
      }
    };
  }

  void _navigateAfterSave() {
    if (_targetStep != null) {
      // User explicitly requested a specific step (clicked step icon)
      final step = _targetStep!;
      _targetStep = null;
      if (step < steps.length) {
        navigateToStep(step);
      } else {
        cancelAction();
      }
    } else if (widget.isNew && currentStep + 1 < steps.length) {
      // In create mode, auto-advance to next step
      navigateToStep(currentStep + 1);
    } else {
      cancelAction();
    }
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CalendarItemBloc, CalendarItemState>(
        listener: (context, state) {
          if (state is CalendarItemsError) {
            showSnackBar(context, state.message!, isError: true);
            setState(() => isSubmitting = false);
          } else if (state is EventDeleted || state is HomeworkDeleted) {
            showSnackBar(
              context,
              '${state is EventDeleted ? 'Event' : 'Assignment'} deleted',
            );
            cancelAction();
          } else if (state is HomeworkCreated ||
              state is HomeworkUpdated ||
              state is EventCreated ||
              state is EventUpdated) {
            state as BaseEntityState;

            final isClone = (state is EventCreated && state.isClone) ||
                (state is HomeworkCreated && state.isClone);

            if (isClone) {
              showSnackBar(
                context,
                '${state.isEvent ? 'Event' : 'Assignment'} cloned',
              );
              // Update state and load the cloned item
              setState(() {
                _currentEntityId = state.entityId;
                _currentIsEvent = state.isEvent;
                isSubmitting = false;
              });
              // Tell child widget to load the cloned entity
              _detailsKey.currentState?.loadEntity(
                eventId: state.isEvent ? state.entityId : null,
                homeworkId: !state.isEvent ? state.entityId : null,
              );
            } else {
              showSnackBar(
                context,
                '${state.isEvent ? 'Event' : 'Assignment'} saved',
              );

              setState(() {
                _currentEntityId = state.entityId;
                _currentIsEvent = state.isEvent;
                isSubmitting = false;
              });

              _navigateAfterSave();
            }
          }
        },
      ),
    ];
  }

  late final List<MultiStepDefinition> _steps = [
    MultiStepDefinition(
      icon: Icons.list,
      tooltip: 'Details',
      stepScreenType: ScreenType.entityPage,
      builder: (context) => CalendarItemDetailsWidget(
        key: _detailsKey,
        eventId: _currentIsEvent == true ? _currentEntityId : null,
        homeworkId: _currentIsEvent == false ? _currentEntityId : null,
        initialDate: widget.initialDate,
        isFromMonthView: widget.isFromMonthView,
        isEdit: widget.isEdit || _currentEntityId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
        onIsEventChanged: (isEvent) {
          setState(() {
            _currentIsEvent = isEvent;
          });
        },
        onActionStarted: () => setState(() => isSubmitting = true),
      ),
    ),
    MultiStepDefinition(
      icon: Icons.notifications_active_outlined,
      tooltip: 'Reminders',
      stepScreenType: ScreenType.subPage,
      builder: (context) => CalendarItemRemindersWidget(
        isEvent: _currentIsEvent ?? false,
        entityId: _currentEntityId!,
        isEdit: widget.isEdit || _currentEntityId != null,
        userSettings: userSettings,
      ),
    ),
    MultiStepDefinition(
      icon: Icons.attachment_outlined,
      tooltip: 'Attachments',
      stepScreenType: ScreenType.subPage,
      builder: (context) => CalendarItemAttachmentsWidget(
        isEvent: _currentIsEvent ?? false,
        entityId: _currentEntityId!,
        isEdit: widget.isEdit || _currentEntityId != null,
        userSettings: userSettings,
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}
