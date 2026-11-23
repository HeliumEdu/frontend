import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/dirty_dialog_registry.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_attachments.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_details.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_reminders.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_attachments.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/linked_note_form.dart';
import 'package:heliumapp/presentation/ui/feedback/discard_changes_scope.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/utils/attachment_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
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
  DateTime? occurrenceStart,
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
      occurrenceStart: occurrenceStart,
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

  final DateTime? occurrenceStart;

  PlannerItemAddScreen({
    super.key,
    required super.shellPath,
    required this.isHomework,
    required super.isNew,
    required this.initialFullPath,
    this.entityId,
    this.initialStepName = 'details',
    this.initialDate,
    this.isFromMonthView = false,
    this.occurrenceStart,
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
  bool _dataLoaded = false;
  final _attachmentsKey = GlobalKey<BaseAttachmentsState>();

  int? _currentEntityId;
  bool? _currentIsEvent;
  int? _targetStep;
  String? _registeredPrefix;
  HomeworkModel? _savedHomework;
  bool _itemRepeats = false;

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
    if (!widget.isNew && widget.isHomework && widget.initialStep != 0) {
      context.read<PlannerItemBloc>().add(
            FetchPlannerItemScreenDataEvent(
              origin: EventOrigin.dialog,
              homeworkId: _currentEntityId,
              forceRefresh: true,
            ),
          );
    }
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_syncFromUrl);
    if (_registeredPrefix != null) {
      DirtyDialogRegistry.unregister(_registeredPrefix!);
    }
    super.dispose();
  }

  /// Registers this dialog with the dirty-dialog guard so URL-driven
  /// dismissals can't silently lose unsaved changes. [fullPath] is the URL
  /// the dialog is moving to when it re-registers under a new entity path.
  void _registerDirtyGuard({String? fullPath}) {
    final entityPath = _activeEntityPath;
    final prefix =
        '${widget.shellPath}/$entityPath/${_currentEntityId?.toString() ?? 'new'}';
    final routerPath =
        router.routerDelegate.currentConfiguration.uri.path;
    // Prefer the routerDelegate's settled path if it already matches our
    // dialog; otherwise fall back to the URL the pageBuilder matched on,
    // which is authoritative for the active route even when the
    // routerDelegate hasn't caught up yet.
    fullPath ??= DirtyDialogRegistry.isWithin(routerPath, prefix)
        ? routerPath
        : widget.initialFullPath;
    DirtyDialogRegistry.register(
      prefix: prefix,
      fullPath: fullPath,
      isDirty: () => isDirty,
      deferNavigation: deferNavigationDismissal,
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
    final location = router.routerDelegate.currentConfiguration.uri;
    final path = location.path;
    final prefix = _registeredPrefix;
    if (prefix == null) return;
    if (!DirtyDialogRegistry.isWithin(path, prefix)) {
      if (DeepLinkParam.namesSavedEntity(location, plannerItemHomeworkPath) ||
          DeepLinkParam.namesSavedEntity(location, plannerItemEventPath)) {
        reopenAt(location.toString());
      }
      return;
    }
    DirtyDialogRegistry.updateFullPath(prefix: prefix, fullPath: path);
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
        occurrenceStart: widget.occurrenceStart,
      ),
    );
  }

  /// Replaces the URL with the other entity-type variant (homework ↔ event)
  /// without changing the step or losing the dialog's extra payload.
  void _swapEntityVariant(bool isEvent) {
    if (!mounted) return;
    final newEntityPath =
        isEvent ? plannerItemEventPath : plannerItemHomeworkPath;
    final id = _currentEntityId?.toString() ?? 'new';
    _currentIsEvent = isEvent;
    _replaceEntityRoute(
      '${widget.shellPath}/$newEntityPath/$id/${plannerItemDialogSteps[currentStep]}',
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
  String? get entityName => switch (_currentIsEvent) {
        null => null,
        true => 'Event',
        false => 'Assignment',
      };

  @override
  bool get hasSavedEntity => _currentEntityId != null;

  @override
  IconData? get icon => _currentIsEvent == null ? null : Icons.calendar_month;

  @override
  bool get deferDismissal =>
      _attachmentsKey.currentState?.isSubmitting ?? false;

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
      HeliumIconButton(
        enabled: !isSubmitting,
        onPressed: () => _detailsKey.currentState?.onDelete(),
        icon: Icons.delete_outline,
        showTooltip: false,
        label: 'Delete',
        color: context.colorScheme.error,
      ),
      const SizedBox(width: 8),
      HeliumIconButton(
        enabled: !isSubmitting,
        onPressed: () => _detailsKey.currentState?.onClone(),
        icon: Icons.copy_outlined,
        label: _itemRepeats ? 'Clone this occurrence' : 'Clone',
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

  void _resolveConflict({
    PlannerItemBaseModel? savedItem,
    String? latestVersion,
    LinkedNoteSave? linkedNoteSave,
  }) {
    setState(() => isSubmitting = false);
    resolveLinkedNoteConflict(
      context,
      _detailsKey.currentState,
      savedEntity: savedItem,
      latestVersion: latestVersion,
      linkedNoteSave: linkedNoteSave,
    );
  }

  (PlannerItemBaseModel, LinkedNoteSave)? _savedWithUnsavedNote(
    PlannerItemState state,
  ) =>
      switch (state) {
        EventCreated(
          origin: EventOrigin.subScreen,
          :final event,
          :final linkedNoteSave?,
        ) ||
        EventUpdated(
          origin: EventOrigin.subScreen,
          :final event,
          :final linkedNoteSave?,
        )
            when !linkedNoteSave.isSaved =>
          (event, linkedNoteSave),
        HomeworkCreated(
          origin: EventOrigin.subScreen,
          :final homework,
          :final linkedNoteSave?,
        ) ||
        HomeworkUpdated(
          origin: EventOrigin.subScreen,
          :final homework,
          :final linkedNoteSave?,
        )
            when !linkedNoteSave.isSaved =>
          (homework, linkedNoteSave),
        _ => null,
      };

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<PlannerItemBloc, PlannerItemState>(
        listener: (context, state) {
          if (state is PlannerItemScreenDataFetched) {
            _dataLoaded = true;
            if (state.plannerItem case final item?
                when item.id == _currentEntityId) {
              setState(() => _itemRepeats = PlannerHelper.isRepeatingItem(item));
            }
            if (state.plannerItem case final HomeworkModel homework
                when homework.id == _currentEntityId) {
              setState(() => _savedHomework = homework);
            }
          }
          if (state case HomeworkCreated(:final homework) ||
              HomeworkUpdated(:final homework)
              when state.origin == EventOrigin.subScreen ||
                  homework.id == _currentEntityId) {
            setState(() => _savedHomework = homework);
          }
          if (state case EventCreated(event: final PlannerItemBaseModel item) ||
              EventUpdated(event: final PlannerItemBaseModel item) ||
              HomeworkCreated(homework: final PlannerItemBaseModel item) ||
              HomeworkUpdated(homework: final PlannerItemBaseModel item)
              when item.id == _currentEntityId) {
            setState(() => _itemRepeats = PlannerHelper.isRepeatingItem(item));
          }

          if (state is PlannerItemScreenDataFailed &&
              state.origin == EventOrigin.dialog) {
            return;
          }
          if (state is PlannerItemsError) {
            if (!_dataLoaded) {
              showSnackBar(
                context,
                state.message!,
                type: SnackType.error,
                useRootMessenger: true,
              );
              closeWithoutPrompt();
              return;
            }
            if (!isShowingErrorCard) {
              showSnackBar(context, state.message!, type: SnackType.error);
            }
            if (state.linkedNoteSave case final linkedNoteSave?
                when state.origin == EventOrigin.subScreen) {
              _detailsKey.currentState?.linkedNoteFields.applyLinkedNoteSave(
                linkedNoteSave,
              );
            }
            _detailsKey.currentState?.resetSubmitting();
            setState(() => isSubmitting = false);
          } else if (state is PlannerItemConflict &&
              state.origin == EventOrigin.subScreen) {
            _resolveConflict(
              latestVersion: state.latestVersion,
              linkedNoteSave: state.linkedNoteSave,
            );
          } else if (_savedWithUnsavedNote(state)
              case (final savedItem, final linkedNoteSave)) {
            if (state is EventCreated || state is HomeworkCreated) {
              setState(() {
                _currentEntityId = savedItem.id;
                _currentIsEvent = state is EventCreated;
              });
              _useCreatedEntityRoute(
                isEvent: state is EventCreated,
                entityId: savedItem.id,
              );
            }
            _resolveConflict(
              savedItem: savedItem,
              linkedNoteSave: linkedNoteSave,
            );
          } else if (state is EventDeleted || state is HomeworkDeleted) {
            // Always closes after delete, show on root
            showSnackBar(
              context,
              '${state is EventDeleted ? 'Event' : 'Assignment'} deleted.',
              useRootMessenger: true,
            );
            closeWithoutPrompt();
          } else if ((state is HomeworkCreated ||
                  state is HomeworkUpdated ||
                  state is EventCreated ||
                  state is EventUpdated) &&
              state.origin == EventOrigin.subScreen) {
            state as BaseEntityState;

            if (state
                case EventUpdated(
                      linkedNoteSave: LinkedNoteSave(isRecreated: true),
                    ) ||
                    HomeworkUpdated(
                      linkedNoteSave: LinkedNoteSave(isRecreated: true),
                    )) {
              showSnackBar(
                context,
                noteRecreatedMessage,
                useRootMessenger: true,
              );
            }

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
              _useCreatedEntityRoute(
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

              openInNotebook(
                context,
                noteId: linkedNoteId,
                eventId: state.isEvent ? state.entityId : null,
                homeworkId: state.isEvent ? null : state.entityId,
              );
            } else {
              _log.info(
                'Planner item saved normally (entityId=${state.entityId}, isEvent=${state.isEvent}, isNew=${state is HomeworkCreated || state is EventCreated})',
              );
              final outsideTodos =
                  _detailsKey.currentState?.isOutsideTodosWindow ?? false;
              if (state is HomeworkCreated || state is EventCreated) {
                final created = '${state.isEvent ? 'Event' : 'Assignment'} created.';
                showSnackBar(
                  context,
                  outsideTodos ? '$created $outsideTodosWindowNote' : created,
                  useRootMessenger: _willCloseAfterSave(),
                );
              } else if (outsideTodos) {
                showSnackBar(
                  context,
                  'Assignment saved. $outsideTodosWindowNote',
                  useRootMessenger: _willCloseAfterSave(),
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
                _useCreatedEntityRoute(
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

  /// Moves the screen to a just-created (or cloned) entity's own path.
  void _useCreatedEntityRoute({required bool isEvent, required int entityId}) {
    if (!mounted) return;
    final entityPath =
        isEvent ? plannerItemEventPath : plannerItemHomeworkPath;
    _replaceEntityRoute(
      '${widget.shellPath}/$entityPath/$entityId/${plannerItemDialogSteps[currentStep]}',
    );
  }

  /// Replaces the URL with [route], a new path for this dialog, without a
  /// back-history entry. The dirty-dialog guard is re-keyed to [route] first,
  /// so a later link elsewhere is guarded against the dialog's actual URL.
  void _replaceEntityRoute(String route) {
    if (_registeredPrefix != null) {
      DirtyDialogRegistry.unregister(_registeredPrefix!);
    }
    _registerDirtyGuard(fullPath: route);
    router.replace(
      route,
      extra: PlannerItemDialogExtra(
        initialDate: widget.initialDate,
        isFromMonthView: widget.isFromMonthView,
        occurrenceStart: widget.occurrenceStart,
      ),
    );
  }

  List<AttachmentGroup> Function(List<AttachmentModel>)?
      _pulledThroughGroupsFrom() {
    final homework = _savedHomework;
    if (_currentIsEvent != false || homework == null) return null;
    return (attachments) =>
        AttachmentGroups.pulledThroughForHomework(homework, attachments);
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
        initialIsEvent: widget.isNew ? !widget.isHomework : null,
        initialDate: widget.initialDate,
        occurrenceStart: _currentEntityId == widget.entityId ? widget.occurrenceStart : null,
        isFromMonthView: widget.isFromMonthView,
        isEdit: widget.isEdit || _currentEntityId != null,
        isNew: widget.isNew,
        userSettings: userSettings,
        onNavigateRequested: (route) async {
          if (isDirty && !await confirmDiscardChanges(context)) return;
          reopenAt(route);
        },
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
        onUploadsSettled: resumeDeferredDismissal,
        pulledThroughGroupsFrom: _pulledThroughGroupsFrom(),
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}
