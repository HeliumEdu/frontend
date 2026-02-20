// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_attachments.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_details.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_reminders.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Shows planner item add/edit as a dialog on desktop, or navigates on mobile
void showPlannerItemAdd(
  BuildContext context, {
  int? eventId,
  int? homeworkId,
  DateTime? initialDate,
  bool isFromMonthView = false,
  required bool isEdit,
  required bool isNew,
  int initialStep = 0,
  required AttachmentBloc attachmentBloc,
}) {
  final plannerItemBloc = context.read<PlannerItemBloc>();
  if (Responsive.isMobile(context)) {
    context.push(
      AppRoute.plannerItemAddScreen,
      extra: PlannerItemAddArgs(
        attachmentBloc: attachmentBloc,
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
          BlocProvider<PlannerItemBloc>.value(value: plannerItemBloc),
          BlocProvider<AttachmentBloc>.value(value: attachmentBloc),
        ],
        child: PlannerItemAddScreen(
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

class PlannerItemAddScreen extends MultiStepContainer {
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;

  const PlannerItemAddScreen({
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
  State<PlannerItemAddScreen> createState() => _PlannerItemAddScreenState();
}

class _PlannerItemAddScreenState
    extends MultiStepContainerState<PlannerItemAddScreen> {
  final _detailsKey = GlobalKey<PlannerItemDetailsState>();

  // State
  int? _currentEntityId;
  bool? _currentIsEvent;
  int? _targetStep;

  @override
  void initState() {
    super.initState();
    _currentEntityId = widget.eventId ?? widget.homeworkId;
    if (_currentEntityId != null) {
      _currentIsEvent = widget.eventId != null;
    }
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
      if (isSubmitting) return;
      final widgetSubmit = _detailsKey.currentState?.onSubmit;
      if (widgetSubmit != null) {
        setState(() => isSubmitting = true);
        widgetSubmit();
      }
    };
  }

  bool _willCloseAfterSave() {
    if (_targetStep != null) {
      return _targetStep! >= steps.length;
    }
    return !widget.isNew || currentStep + 1 >= steps.length;
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
      BlocListener<PlannerItemBloc, PlannerItemState>(
        listener: (context, state) {
          if (state is PlannerItemsError) {
            showSnackBar(context, state.message!, isError: true);
            setState(() => isSubmitting = false);
          } else if (state is EventDeleted || state is HomeworkDeleted) {
            // Always closes after delete, show on root
            showSnackBar(
              context,
              '${state is EventDeleted ? 'Event' : 'Assignment'} deleted',
              useRootMessenger: true,
            );
            cancelAction();
          } else if (state is HomeworkCreated ||
              state is HomeworkUpdated ||
              state is EventCreated ||
              state is EventUpdated) {
            state as BaseEntityState;

            final isClone =
                (state is EventCreated && state.isClone) ||
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
              if (state is HomeworkCreated || state is EventCreated) {
                final willClose = _willCloseAfterSave();
                showSnackBar(
                  context,
                  '${state.isEvent ? 'Event' : 'Assignment'} created',
                  useRootMessenger: willClose,
                );
              }

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
      builder: (context) => PlannerItemDetails(
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
        onSubmitRequested: () => saveAction?.call(),
      ),
    ),
    MultiStepDefinition(
      icon: Icons.notifications_outlined,
      tooltip: 'Reminders',
      stepScreenType: ScreenType.subPage,
      builder: (context) => PlannerItemReminders(
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
      builder: (context) => PlannerItemAttachments(
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
