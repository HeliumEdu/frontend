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
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/dirty_dialog_registry.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_attachments.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_details.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_reminders.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_attachments.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.views');

/// Pushes the planner item editor route on the current shell.
///
/// Step navigation and dialog dismissal are URL-driven; callers only need to
/// specify which planner item (or 'new') and, for the create flow, the
/// originating calendar context. The `extra` payload survives in-app pushes
/// but not browser refresh, so deep-linked edits resolve the entity directly
/// from its ID.
///
/// When [homeworkId] and [eventId] are both null and [isNew] is true (FAB
/// case), the dialog defaults to the homework variant; the user can toggle
/// to event in the details step, which swaps the URL between
/// `/<shell>/homework/new` and `/<shell>/event/new`.
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
  final isHomework = homeworkId != null || eventId == null;
  final entityPath =
      isHomework ? plannerItemHomeworkPath : plannerItemEventPath;
  final id = (homeworkId ?? eventId)?.toString() ?? 'new';
  final stepName = initialStep >= 0 && initialStep < plannerItemDialogSteps.length
      ? plannerItemDialogSteps[initialStep]
      : plannerItemDialogSteps.first;
  final shellPath = _resolveShellPath();
  final target = '$shellPath/$entityPath/$id/$stepName';
  final currentPath =
      router.routerDelegate.currentConfiguration.uri.path;
  if (currentPath == target) {
    // Already on this exact route; avoid duplicate push that would stack
    // a second dialog page with the same shared key.
    return Future.value();
  }
  return context.push<void>(
    target,
    extra: PlannerItemDialogExtra(
      initialDate: initialDate,
      isFromMonthView: isFromMonthView,
    ),
  );
}

/// Determines the shell path the dialog should mount under from the current
/// URL. Defaults to the planner shell when the active route can't be mapped
/// to a known shell (e.g., a notifications overlay sitting above a stale
/// path during a logout race).
String _resolveShellPath() {
  final path = router.routerDelegate.currentConfiguration.uri.path;
  for (final shell in _validShellPaths) {
    if (path == shell || path.startsWith('$shell/')) {
      return shell;
    }
  }
  return AppRoute.plannerScreen;
}

const _validShellPaths = [
  AppRoute.plannerScreen,
  AppRoute.notebookScreen,
  AppRoute.coursesScreen,
  AppRoute.resourcesScreen,
  AppRoute.gradesScreen,
];

class PlannerItemAddScreen extends MultiStepContainer {
  /// Shell path the dialog is overlaying — used to build sub-step URLs and
  /// the dirty-guard prefix.
  final String shellPath;

  /// True when the URL mounted the homework variant, false for event. For
  /// the create flow this seeds the initial entity type; the user can
  /// toggle in details, which swaps the URL between variants.
  final bool isHomework;

  /// Planner item primary key. Null when creating a new item
  /// (`isNew == true`).
  final int? entityId;

  /// URL step segment to render on initial mount (`details`, `reminders`,
  /// `attachments`).
  final String initialStepName;

  /// Full URL the route was matched at — passed in from the pageBuilder so
  /// the dialog's dirty-guard registration captures the active path without
  /// racing against `routerDelegate.currentConfiguration`, which lags push.
  final String initialFullPath;

  /// Calendar context for the create flow. Survives in-app pushes via
  /// GoRouter `extra` but not browser refresh.
  final DateTime? initialDate;
  final bool isFromMonthView;

  PlannerItemAddScreen({
    super.key,
    required this.shellPath,
    required this.isHomework,
    required super.isNew,
    required this.initialFullPath,
    this.entityId,
    this.initialStepName = 'details',
    this.initialDate,
    this.isFromMonthView = false,
  }) : super(
          isEdit: !isNew,
          initialStep: _resolveStepIndex(initialStepName),
        );

  static int _resolveStepIndex(String name) {
    final idx = plannerItemDialogSteps.indexOf(name);
    return idx >= 0 ? idx : 0;
  }

  @override
  State<PlannerItemAddScreen> createState() => _PlannerItemAddScreenState();
}

class _PlannerItemAddScreenState
    extends MultiStepContainerState<PlannerItemAddScreen> {
  final _detailsKey = GlobalKey<PlannerItemDetailsState>();
  final _attachmentsKey = GlobalKey<BaseAttachmentsState>();

  int? _currentEntityId;
  bool? _currentIsEvent;
  int? _targetStep;
  String? _registeredPrefix;

  @override
  void initState() {
    super.initState();
    _currentEntityId = widget.entityId;
    // Edit flow: the URL's homework/event segment determines the entity type
    // up front. Create flow: the type is unknown until the user toggles, so
    // leave it null so the title and icon getters render their neutral state.
    _currentIsEvent = widget.isNew ? null : !widget.isHomework;
    _registerDirtyGuard();
    // The modal scope does not rebuild on Page swap, so the URL is the
    // source of truth for the active step and entity type.
    router.routerDelegate.addListener(_syncFromUrl);
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_syncFromUrl);
    if (_registeredPrefix != null) {
      DirtyDialogRegistry.unregister(_registeredPrefix!);
    }
    super.dispose();
  }

  /// Registers (or re-registers, after a new-item save mints a real ID or
  /// the create-flow toggle swaps the entity type) this dialog with the
  /// dirty-dialog guard so URL-driven dismissals can't silently lose
  /// unsaved changes.
  void _registerDirtyGuard() {
    final entityPath = _activeEntityPath;
    final prefix =
        '${widget.shellPath}/$entityPath/${_currentEntityId?.toString() ?? 'new'}';
    final routerPath =
        router.routerDelegate.currentConfiguration.uri.path;
    // Prefer the routerDelegate's settled path if it already matches our
    // dialog (e.g. after a new-item save); otherwise fall back to the URL
    // the pageBuilder matched on, which is authoritative for the active
    // route even when the routerDelegate hasn't caught up yet.
    final fullPath = routerPath.startsWith(prefix)
        ? routerPath
        : widget.initialFullPath;
    DirtyDialogRegistry.register(
      prefix: prefix,
      fullPath: fullPath,
      isDirty: () => isDirty,
    );
    _registeredPrefix = prefix;
  }

  /// URL segment for the entity type currently shown — uses the toggled
  /// state once the user picks one, falling back to the URL's seeded value
  /// until then.
  String get _activeEntityPath {
    final isEvent = _currentIsEvent ?? !widget.isHomework;
    return isEvent ? plannerItemEventPath : plannerItemHomeworkPath;
  }

  void _syncFromUrl() {
    if (!mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final prefix = _registeredPrefix;
    if (prefix != null && path.startsWith(prefix)) {
      DirtyDialogRegistry.updateFullPath(prefix: prefix, fullPath: path);
    }
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    // Find our entity segment in the URL — look for either homework or event
    // matching our shell. The dialog can swap entity type without unmounting
    // (FAB create flow toggle), so accept whichever one is present.
    final entityIdx = segments.indexWhere(
      (s) => s == plannerItemHomeworkPath || s == plannerItemEventPath,
    );
    if (entityIdx < 0 || segments.length < entityIdx + 3) return;
    final stepName = segments[entityIdx + 2];
    final newStep = plannerItemDialogSteps.indexOf(stepName);
    if (newStep >= 0 && newStep != currentStep) {
      super.navigateToStep(newStep);
    }
  }

  @override
  void navigateToStep(int step) {
    if (step < 0 || step >= steps.length) return;
    if (!mounted) return;
    final id = _currentEntityId?.toString() ?? 'new';
    final stepName = plannerItemDialogSteps[step];
    context.go(
      '${widget.shellPath}/$_activeEntityPath/$id/$stepName',
      extra: PlannerItemDialogExtra(
        initialDate: widget.initialDate,
        isFromMonthView: widget.isFromMonthView,
      ),
    );
  }

  /// Replaces the URL with the other entity-type variant (homework ↔ event)
  /// without changing the step or losing the dialog's extra payload.
  /// Re-keys the dirty-guard registration so the new URL prefix owns the
  /// active slot.
  void _swapEntityVariant(bool isEvent) {
    if (!mounted) return;
    final newEntityPath =
        isEvent ? plannerItemEventPath : plannerItemHomeworkPath;
    final id = _currentEntityId?.toString() ?? 'new';
    final stepName = plannerItemDialogSteps[currentStep];
    if (_registeredPrefix != null) {
      DirtyDialogRegistry.unregister(_registeredPrefix!);
    }
    _currentIsEvent = isEvent;
    _registerDirtyGuard();
    router.replace(
      '${widget.shellPath}/$newEntityPath/$id/$stepName',
      extra: PlannerItemDialogExtra(
        initialDate: widget.initialDate,
        isFromMonthView: widget.isFromMonthView,
      ),
    );
  }

  @override
  bool get enableNextSteps => _currentEntityId != null;

  @override
  void onStepRequested(int step) {
    if (step == currentStep) return;

    if (saveAction != null) {
      if (!(_detailsKey.currentState?.formController.isChanged ?? true)) {
        navigateToStep(step);
        return;
      }
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
  bool get isDirty {
    switch (currentStep) {
      case 0:
        return _detailsKey.currentState?.formController.isUserDirty ?? false;
      case 2:
        return _attachmentsKey.currentState?.hasUnsavedFiles ?? false;
      default:
        return false;
    }
  }

  @override
  List<Widget> get additionalHeaderButtons {
    if (currentStep != 0) return const [];
    if (_currentEntityId == null) return const [];
    return [
      Semantics(
        label: 'Delete',
        button: true,
        child: HeliumIconButton(
          onPressed: () => _detailsKey.currentState?.onDelete(),
          icon: Icons.delete_outline,
          color: context.colorScheme.error,
        ),
      ),
      const SizedBox(width: 8),
      HeliumIconButton(
        onPressed: () => _detailsKey.currentState?.onClone(),
        icon: Icons.copy_outlined,
        tooltip: 'Clone',
      ),
    ];
  }

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
      if (!detailsState.formController.isChanged) {
        _navigateAfterSave();
        return;
      }
      detailsState.onSubmit();
    };
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
              '${state is EventDeleted ? 'Event' : 'Assignment'} deleted.',
              useRootMessenger: true,
            );
            closeWithoutPrompt();
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
              _log.info(
                'Planner item cloned (entityId=${state.entityId}, isEvent=${state.isEvent})',
              );
              showSnackBar(
                context,
                '${state.isEvent ? 'Event' : 'Assignment'} cloned.',
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
              _replaceUrlForEntity(
                isEvent: state.isEvent,
                entityId: state.entityId,
              );
            } else if (redirectToNotebook) {
              _log.info(
                'Planner item saved with notebook redirect (entityId=${state.entityId}, isEvent=${state.isEvent})',
              );
              final linkedNoteId = switch (state) {
                EventCreated(:final linkedNoteId) => linkedNoteId,
                EventUpdated(:final linkedNoteId) => linkedNoteId,
                HomeworkCreated(:final linkedNoteId) => linkedNoteId,
                HomeworkUpdated(:final linkedNoteId) => linkedNoteId,
                _ => null,
              };

              _detailsKey.currentState?.resetSubmitting();
              setState(() => isSubmitting = false);

              // The save is the user's explicit intent — release the
              // dirty-guard before navigating so it doesn't intercept the
              // URL change with a "discard changes?" prompt.
              DirtyDialogRegistry.releaseActive();

              if (linkedNoteId != null) {
                navigateAndClearStack(
                  context,
                  '${AppRoute.notebookScreen}/notes/$linkedNoteId',
                );
              } else if (state.isEvent) {
                navigateAndClearStack(
                  context,
                  '${AppRoute.notebookScreen}/notes/new'
                  '?${DeepLinkParam.linkEventId}=${state.entityId}',
                );
              } else {
                navigateAndClearStack(
                  context,
                  '${AppRoute.notebookScreen}/notes/new'
                  '?${DeepLinkParam.linkHomeworkId}=${state.entityId}',
                );
              }
            } else {
              _log.info(
                'Planner item saved normally (entityId=${state.entityId}, isEvent=${state.isEvent}, isNew=${state is HomeworkCreated || state is EventCreated})',
              );
              if (state is HomeworkCreated || state is EventCreated) {
                final willClose = _willCloseAfterSave();
                showSnackBar(
                  context,
                  '${state.isEvent ? 'Event' : 'Assignment'} created.',
                  useRootMessenger: willClose,
                );
              }

              final wasCreate =
                  state is HomeworkCreated || state is EventCreated;

              setState(() {
                _currentEntityId = state.entityId;
                _currentIsEvent = state.isEvent;
                isSubmitting = false;
              });

              if (wasCreate) {
                // New entity minted its real ID — the URL prefix that the
                // dirty-dialog guard owns has changed (`/<entity>/new` →
                // `/<entity>/<id>`), so swap the registration before
                // `_navigateAfterSave` triggers the URL update.
                if (_registeredPrefix != null) {
                  DirtyDialogRegistry.unregister(_registeredPrefix!);
                }
                _registerDirtyGuard();
                _replaceUrlForEntity(
                  isEvent: state.isEvent,
                  entityId: state.entityId,
                );
              }

              _navigateAfterSave();
            }
          }
        },
      ),
    ];
  }

  /// Replaces the URL with the canonical entity path now that a real ID
  /// exists. Uses `router.replace` so the create URL doesn't accumulate a
  /// back-history entry.
  void _replaceUrlForEntity({required bool isEvent, required int entityId}) {
    if (!mounted) return;
    final entityPath =
        isEvent ? plannerItemEventPath : plannerItemHomeworkPath;
    final stepName = plannerItemDialogSteps[currentStep];
    router.replace(
      '${widget.shellPath}/$entityPath/$entityId/$stepName',
      extra: PlannerItemDialogExtra(
        initialDate: widget.initialDate,
        isFromMonthView: widget.isFromMonthView,
      ),
    );
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
        closeWithoutPrompt();
      }
    } else if (widget.isNew && currentStep + 1 < steps.length) {
      // In create mode, auto-advance to next step
      navigateToStep(currentStep + 1);
    } else {
      closeWithoutPrompt();
    }
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
            _swapEntityVariant(isEvent);
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
        contentKey: _attachmentsKey,
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
