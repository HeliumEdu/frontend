// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_attachments.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_details.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_reminders.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

/// Shows planner item add/edit as a dialog on desktop, or navigates on mobile
Future<void> showPlannerItemAdd(
  BuildContext context, {
  int? eventId,
  int? homeworkId,
  DateTime? initialDate,
  bool isFromMonthView = false,
  required bool isEdit,
  required bool isNew,
  int initialStep = 0,
}) {
  AttachmentBloc? existingBloc;
  try {
    existingBloc = context.read<AttachmentBloc>();
  } catch (_) {}
  final attachmentBloc =
      existingBloc ?? ProviderHelpers().createAttachmentBloc()(context);

  if (Responsive.isMobile(context)) {
    final basePath = router.routerDelegate.currentConfiguration.uri.path;
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
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
      ),
    ).then((_) => clearRouteQueryParams(basePath));
  } else {
    final basePath = router.routerDelegate.currentConfiguration.uri.path;
    if (homeworkId != null) {
      context.setQueryParam(DeepLinkParam.homeworkId, homeworkId.toString());
    } else if (eventId != null) {
      context.setQueryParam(DeepLinkParam.eventId, eventId.toString());
    } else if (isNew) {
      // FAB case: entity type not yet chosen, default to homework
      context.setQueryParam(DeepLinkParam.homeworkId, 'new');
    }
    return showScreenAsDialog(
      context,
      barrierDismissible: false,
      child: MultiBlocProvider(
        providers: [
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
    ).then((_) => clearRouteQueryParams(basePath));
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
    // Note: Don't set isSubmitting here - let onActionStarted callback handle it
    // after validation passes. Otherwise, validation failures leave spinner stuck.
    return () {
      final detailsState = _detailsKey.currentState;
      if (detailsState == null) return;
      if (detailsState.isLoading || isSubmitting) return;
      detailsState.onSubmit();
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
            showSnackBar(context, state.message!, type: SnackType.error);
            _detailsKey.currentState?.resetSubmitting();
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

            // Check for notebook redirect from state
            final redirectToNotebook =
                (state is EventCreated && state.redirectToNotebook) ||
                (state is EventUpdated && state.redirectToNotebook) ||
                (state is HomeworkCreated && state.redirectToNotebook) ||
                (state is HomeworkUpdated && state.redirectToNotebook);

            if (isClone) {
              showSnackBar(
                context,
                '${state.isEvent ? 'Event' : 'Assignment'} cloned',
              );
              // Update state and load the cloned item
              _detailsKey.currentState?.resetSubmitting();
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
            } else if (redirectToNotebook) {
              final linkedNoteId = switch (state) {
                EventCreated(:final linkedNoteId) => linkedNoteId,
                EventUpdated(:final linkedNoteId) => linkedNoteId,
                HomeworkCreated(:final linkedNoteId) => linkedNoteId,
                HomeworkUpdated(:final linkedNoteId) => linkedNoteId,
                _ => null,
              };

              _detailsKey.currentState?.resetSubmitting();
              setState(() => isSubmitting = false);

              if (linkedNoteId != null) {
                navigateAndClearStack(context, '${AppRoute.notebookScreen}?id=$linkedNoteId');
              } else if (state.isEvent) {
                navigateAndClearStack(context, '${AppRoute.notebookScreen}?${DeepLinkParam.linkEventId}=${state.entityId}');
              } else {
                navigateAndClearStack(context, '${AppRoute.notebookScreen}?${DeepLinkParam.linkHomeworkId}=${state.entityId}');
              }
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

              // Update URL from id=new to the actual ID, clearing opposite param
              if (!Responsive.isMobile(context) &&
                  (state is HomeworkCreated || state is EventCreated)) {
                final removeKey = state.isEvent
                    ? DeepLinkParam.homeworkId
                    : DeepLinkParam.eventId;
                final setKey = state.isEvent
                    ? DeepLinkParam.eventId
                    : DeepLinkParam.homeworkId;
                context.replaceQueryParam(
                  removeKey,
                  setKey,
                  state.entityId.toString(),
                );
              }

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
          if (!Responsive.isMobile(context) && _currentEntityId == null) {
            if (isEvent) {
              context.replaceQueryParam(
                DeepLinkParam.homeworkId,
                DeepLinkParam.eventId,
                'new',
              );
            } else {
              context.replaceQueryParam(
                DeepLinkParam.eventId,
                DeepLinkParam.homeworkId,
                'new',
              );
            }
          }
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
