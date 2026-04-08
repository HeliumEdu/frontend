// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:logging/logging.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/features/resources/widgets/resource_details.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

final _log = Logger('presentation.views');

/// Shows resource add/edit screen (responsive: dialog on desktop, full-screen on mobile)
Future<void> showResourceAdd(
  BuildContext context, {
  required int resourceGroupId,
  int? resourceId,
  bool isEdit = false,
  int initialStep = 0,
}) {
  final resourceBloc = context.read<ResourceBloc>();
  final noteBloc = context.read<NoteBloc>();
  final basePath = router.routerDelegate.currentConfiguration.uri.path;
  final idValue = resourceId?.toString() ?? 'new';

  context.setQueryParam(DeepLinkParam.id, idValue);

  final useCompact = Responsive.useCompactLayout(context);

  return showScreenAsDialog(
    context,
    barrierDismissible: false,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ResourceBloc>.value(value: resourceBloc),
        BlocProvider<NoteBloc>.value(value: noteBloc),
      ],
      child: ResourceAddScreen(
        resourceGroupId: resourceGroupId,
        resourceId: resourceId,
        isEdit: isEdit,
        isNew: !isEdit,
        initialStep: initialStep,
      ),
    ),
    width: useCompact ? double.infinity : AppConstants.centeredDialogWidth,
    insetPadding: useCompact ? EdgeInsets.zero : const EdgeInsets.all(16),
    alignment: Alignment.center,
  ).then((_) => clearRouteQueryParams(basePath));
}

class ResourceAddScreen extends MultiStepContainer {
  final int resourceGroupId;
  final int? resourceId;

  const ResourceAddScreen({
    super.key,
    required this.resourceGroupId,
    this.resourceId,
    required super.isEdit,
    required super.isNew,
    super.initialStep = 0,
  });

  @override
  State<ResourceAddScreen> createState() => _ResourceAddScreenState();
}

class _ResourceAddScreenState
    extends MultiStepContainerState<ResourceAddScreen> {
  final _detailsKey = GlobalKey<ResourceDetailsState>();

  bool _pendingRedirectToNotebook = false;

  @override
  String get screenTitle => widget.isEdit ? 'Edit Resource' : 'Add Resource';

  @override
  IconData? get icon => Icons.book;

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
            setState(() => isSubmitting = false);
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
                navigateAndClearStack(context, '${AppRoute.notebookScreen}?${DeepLinkParam.linkResourceId}=${state.resource.id}');
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
              if (!Responsive.isMobile(context)) {
                context.setQueryParam(
                  DeepLinkParam.id,
                  state.resource.id.toString(),
                );
              }
              showSnackBar(context, 'Resource created', useRootMessenger: true);
              cancelAction();
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
                navigateAndClearStack(context, '${AppRoute.notebookScreen}?id=$linkedNoteId');
              } else if (linkedNoteId == null && noteContent != null) {
                // New note being created by NoteBloc; wait for NoteCreated
                _pendingRedirectToNotebook = true;
              } else {
                // No note content; navigate with linkResourceId to create one in notebook
                navigateAndClearStack(context, '${AppRoute.notebookScreen}?${DeepLinkParam.linkResourceId}=${state.resource.id}');
              }
            } else {
              cancelAction();
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
            navigateAndClearStack(context, '${AppRoute.notebookScreen}?id=${state.note.id}');
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
      builder: (context) => ResourceDetails(
        key: _detailsKey,
        resourceGroupId: widget.resourceGroupId,
        resourceId: widget.resourceId,
        isEdit: widget.isEdit,
        onSubmitRequested: () => saveAction?.call(),
        onActionStarted: () => setState(() => isSubmitting = true),
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}

