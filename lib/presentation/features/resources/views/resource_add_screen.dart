// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:logging/logging.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/dirty_dialog_registry.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/features/resources/widgets/resource_details.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

final _log = Logger('presentation.views');

/// Pushes the resource editor route on the resources shell.
///
/// Step navigation and dialog dismissal are URL-driven; callers only need to
/// specify which resource (or 'new') and, for the create flow, which
/// resource group to attach it to. The group rides along as GoRouter `extra`
/// so the URL stays focused on the entity, not its containing group.
Future<void> showResourceAdd(
  BuildContext context, {
  required int resourceGroupId,
  int? resourceId,
  bool isEdit = false,
  String initialStep = 'details',
}) {
  final id = resourceId?.toString() ?? 'new';
  final target = '${AppRoute.resourcesScreen}/$id/$initialStep';
  final currentPath =
      router.routerDelegate.currentConfiguration.uri.path;
  if (currentPath == target) {
    // Already on this exact route; avoid duplicate push that would stack
    // a second dialog page with the same shared key.
    return Future.value();
  }
  return context.push<void>(
    target,
    extra: ResourceDialogExtra(resourceGroupId: resourceGroupId),
  );
}

class ResourceAddScreen extends MultiStepContainer {
  /// Shell path the dialog is overlaying — used to build sub-step URLs.
  final String shellPath;

  /// Resource group containing the resource. Required for the create flow
  /// and the multi-step widgets that consume it.
  final int? resourceGroupId;

  /// Resource primary key. Null when creating a new resource
  /// (`isNew == true`).
  final int? resourceId;

  /// URL step segment to render on initial mount.
  final String initialStepName;

  /// Full URL the route was matched at — passed in from the pageBuilder so
  /// the dialog's dirty-guard registration captures the active path without
  /// racing against `routerDelegate.currentConfiguration`, which lags push.
  final String initialFullPath;

  ResourceAddScreen({
    super.key,
    required this.shellPath,
    required super.isNew,
    required this.initialFullPath,
    this.resourceId,
    this.resourceGroupId,
    this.initialStepName = 'details',
  }) : super(
          isEdit: !isNew,
          initialStep: _resolveStepIndex(initialStepName),
        );

  static int _resolveStepIndex(String name) {
    final idx = resourceDialogSteps.indexOf(name);
    return idx >= 0 ? idx : 0;
  }

  @override
  State<ResourceAddScreen> createState() => _ResourceAddScreenState();
}

class _ResourceAddScreenState
    extends MultiStepContainerState<ResourceAddScreen> {
  final _detailsKey = GlobalKey<ResourceDetailsState>();

  int? _currentResourceId;
  int? _currentResourceGroupId;
  String? _registeredPrefix;

  bool _pendingRedirectToNotebook = false;

  @override
  void initState() {
    super.initState();
    _currentResourceId = widget.resourceId;
    _currentResourceGroupId = widget.resourceGroupId;
    _registerDirtyGuard();
    // The modal scope does not rebuild on Page swap, so the URL is the
    // source of truth for the active step.
    router.routerDelegate.addListener(_syncStepFromUrl);

    if (_currentResourceGroupId == null) {
      if (widget.isNew) {
        // Create flow refreshed without the in-app `extra`. We have no
        // group to attach the new resource to — drop back to the index.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(widget.shellPath);
        });
      } else if (_currentResourceId != null) {
        // Edit flow without a hint — try the BLoC's cache, otherwise
        // request a fetch and wait for the listener below.
        _resolveGroupFromBlocState(context.read<ResourceBloc>().state);
        if (_currentResourceGroupId == null) {
          context.read<ResourceBloc>().add(
                FetchResourcesScreenDataEvent(origin: EventOrigin.dialog),
              );
        }
      }
    }
  }

  void _resolveGroupFromBlocState(ResourceState state) {
    if (state is! ResourcesScreenDataFetched) return;
    final match = state.resources
        .firstWhereOrNull((r) => r.id == _currentResourceId);
    if (match != null) {
      _currentResourceGroupId = match.resourceGroup;
    }
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_syncStepFromUrl);
    if (_registeredPrefix != null) {
      DirtyDialogRegistry.unregister(_registeredPrefix!);
    }
    super.dispose();
  }

  /// Registers (or re-registers, after a new-resource save mints a real
  /// ID) this dialog with the dirty-dialog guard so URL-driven dismissals
  /// can't silently lose unsaved changes.
  void _registerDirtyGuard() {
    final prefix =
        '${widget.shellPath}/${_currentResourceId?.toString() ?? 'new'}';
    final routerPath =
        router.routerDelegate.currentConfiguration.uri.path;
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

  void _syncStepFromUrl() {
    if (!mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final prefix = _registeredPrefix;
    if (prefix != null && path.startsWith(prefix)) {
      DirtyDialogRegistry.updateFullPath(prefix: prefix, fullPath: path);
    }
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final resourcesIdx = segments.indexOf('resources');
    if (resourcesIdx < 0 || segments.length < resourcesIdx + 3) return;
    final stepName = segments[resourcesIdx + 2];
    final newStep = resourceDialogSteps.indexOf(stepName);
    if (newStep >= 0 && newStep != currentStep) {
      super.navigateToStep(newStep);
    }
  }

  @override
  void navigateToStep(int step) {
    if (step < 0 || step >= steps.length) return;
    if (!mounted) return;
    final id = _currentResourceId?.toString() ?? 'new';
    final stepName = resourceDialogSteps[step];
    final groupId = _currentResourceGroupId;
    context.go(
      '${widget.shellPath}/$id/$stepName',
      extra: groupId != null
          ? ResourceDialogExtra(resourceGroupId: groupId)
          : null,
    );
  }

  @override
  String get screenTitle => widget.isEdit ? 'Edit Resource' : 'Add Resource';

  @override
  IconData? get icon => Icons.book;

  @override
  bool get isDirty =>
      _detailsKey.currentState?.formController.isUserDirty ?? false;

  @override
  Function? get saveAction {
    if (steps[currentStep].stepScreenType != ScreenType.entityPage) {
      return null;
    }
    // Return function that evaluates widget state when called, not when getter runs
    // Note: Don't set isSubmitting here - let validation complete first.
    // Otherwise, validation failures leave spinner stuck.
    return () {
      final detailsState = _detailsKey.currentState;
      if (detailsState == null) return;
      if (detailsState.isLoading || isSubmitting) return;
      if (!detailsState.formController.isChanged) {
        cancelAction();
        return;
      }
      detailsState.onSubmit();
    };
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ResourceBloc, ResourceState>(
        listener: (context, state) {
          if (state is ResourcesError) {
            showSnackBar(context, state.message!, type: SnackType.error);
            _detailsKey.currentState?.resetSubmitting();
            setState(() { isLoading = false; isSubmitting = false; });
          } else if (state is ResourcesScreenDataFetched &&
              _currentResourceGroupId == null &&
              _currentResourceId != null) {
            final match = state.resources
                .firstWhereOrNull((r) => r.id == _currentResourceId);
            if (match != null) {
              setState(() => _currentResourceGroupId = match.resourceGroup);
            } else {
              // Resource not found after fetch; back out to the index.
              context.go(widget.shellPath);
            }
          } else if (state is ResourceCreated) {
            final noteContent = _detailsKey.currentState?.noteContent;

            if (state.redirectToNotebook) {
              _detailsKey.currentState?.resetSubmitting();
              setState(() => isSubmitting = false);

              // CREATE + redirect: note content must be created first to get its ID
              if (noteContent != null) {
                _log.info('Resource created with note content; creating note before notebook redirect (resourceId=${state.resource.id})');
                _pendingRedirectToNotebook = true;
                context.read<NoteBloc>().add(CreateNoteEvent(
                  origin: EventOrigin.subScreen,
                  request: NoteRequestModel(
                    content: noteContent,
                    resourceId: state.resource.id,
                  ),
                ));
              } else {
                DirtyDialogRegistry.releaseActive();
                navigateAndClearStack(
                  context,
                  '${AppRoute.notebookScreen}/new'
                  '?${DeepLinkParam.linkResourceId}=${state.resource.id}',
                );
              }
            } else {
              _log.info('Resource created without notebook redirect (resourceId=${state.resource.id}, hasNoteContent=${noteContent != null})');
              if (noteContent != null) {
                context.read<NoteBloc>().add(CreateNoteEvent(
                  origin: EventOrigin.subScreen,
                  request: NoteRequestModel(
                    content: noteContent,
                    resourceId: state.resource.id,
                  ),
                ));
              }
              setState(() {
                _currentResourceId = state.resource.id;
                _currentResourceGroupId = state.resource.resourceGroup;
              });
              // New resource minted its real ID — the URL prefix that the
              // dirty-dialog guard owns has changed
              // (`/resources/new` → `/resources/<id>`), so swap the
              // registration before triggering the URL update.
              if (_registeredPrefix != null) {
                DirtyDialogRegistry.unregister(_registeredPrefix!);
              }
              _registerDirtyGuard();
              showSnackBar(context, 'Resource created.', useRootMessenger: true);
              closeWithoutPrompt();
            }
          } else if (state is ResourceUpdated) {
            if (state.redirectToNotebook) {
              _log.info('Resource updated with notebook redirect (resourceId=${state.resource.id})');
              _detailsKey.currentState?.resetSubmitting();
              setState(() => isSubmitting = false);

              final linkedNoteId = _detailsKey.currentState?.linkedNoteId;
              final noteContent = _detailsKey.currentState?.noteContent;

              if (linkedNoteId != null && noteContent != null) {
                // Existing note being updated; ID is already known
                DirtyDialogRegistry.releaseActive();
                navigateAndClearStack(
                  context,
                  '${AppRoute.notebookScreen}/$linkedNoteId',
                );
              } else if (linkedNoteId == null && noteContent != null) {
                // New note being created by NoteBloc; wait for NoteCreated
                _pendingRedirectToNotebook = true;
              } else {
                // No note content; navigate to the new-note dialog with the
                // resource link riding via extra so it isn't in the URL.
                DirtyDialogRegistry.releaseActive();
                navigateAndClearStack(
                  context,
                  '${AppRoute.notebookScreen}/new'
                  '?${DeepLinkParam.linkResourceId}=${state.resource.id}',
                );
              }
            } else {
              closeWithoutPrompt();
            }
          }
        },
      ),
      BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NotesError) {
            showSnackBar(context, state.message!, type: SnackType.error);
            _detailsKey.currentState?.resetSubmitting();
            setState(() => isSubmitting = false);
          } else if (state is NoteCreated && _pendingRedirectToNotebook) {
            _pendingRedirectToNotebook = false;
            DirtyDialogRegistry.releaseActive();
            navigateAndClearStack(
              context,
              '${AppRoute.notebookScreen}/${state.note.id}',
            );
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    if (_currentResourceGroupId == null) {
      return const Expanded(
        child: Center(child: LoadingIndicator(expanded: false)),
      );
    }
    return super.buildMainArea(context);
  }

  late final List<MultiStepDefinition> _steps = [
    MultiStepDefinition(
      icon: Icons.list,
      tooltip: 'Details',
      stepScreenType: ScreenType.entityPage,
      builder: (context) => ResourceDetails(
        key: _detailsKey,
        resourceGroupId: _currentResourceGroupId!,
        resourceId: _currentResourceId,
        isEdit: widget.isEdit || _currentResourceId != null,
        onSubmitRequested: () => saveAction?.call(),
        onActionStarted: () => setState(() => isSubmitting = true),
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}
