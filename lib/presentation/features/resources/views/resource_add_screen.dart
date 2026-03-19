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
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/features/resources/widgets/resource_details.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

/// Shows resource add/edit as a dialog on desktop, or navigates on mobile
void showResourceAdd(
  BuildContext context, {
  required int resourceGroupId,
  int? resourceId,
  bool isEdit = false,
}) {
  final resourceBloc = context.read<ResourceBloc>();
  final noteBloc = context.read<NoteBloc>();

  if (Responsive.isMobile(context)) {
    context.push(
      AppRoute.resourcesAddScreen,
      extra: ResourceAddArgs(
        resourceBloc: resourceBloc,
        noteBloc: noteBloc,
        resourceGroupId: resourceGroupId,
        resourceId: resourceId,
        isEdit: isEdit,
      ),
    );
  } else {
    showScreenAsDialog(
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
        ),
      ),
      width: AppConstants.centeredDialogWidth,
      alignment: Alignment.center,
    );
  }
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
            setState(() => isSubmitting = false);
          } else if (state is ResourceCreated) {
            final noteContent = _detailsKey.currentState?.noteContent;

            if (state.redirectToNotebook) {
              // CREATE + redirect: note content must be created first to get its ID
              if (noteContent != null) {
                _pendingRedirectToNotebook = true;
                context.read<NoteBloc>().add(CreateNoteEvent(
                  origin: EventOrigin.subScreen,
                  request: NoteRequestModel(
                    content: noteContent,
                    resourceId: state.resource.id,
                  ),
                ));
              } else {
                context.go('${AppRoute.notebookScreen}?resourceId=${state.resource.id}&resourceGroupId=${widget.resourceGroupId}');
              }
            } else {
              if (noteContent != null) {
                context.read<NoteBloc>().add(CreateNoteEvent(
                  origin: EventOrigin.subScreen,
                  request: NoteRequestModel(
                    content: noteContent,
                    resourceId: state.resource.id,
                  ),
                ));
              }
              showSnackBar(context, 'Resource created', useRootMessenger: true);
              cancelAction();
            }
          } else if (state is ResourceUpdated) {
            if (state.redirectToNotebook) {
              final linkedNoteId = _detailsKey.currentState?.linkedNoteId;
              final noteContent = _detailsKey.currentState?.noteContent;

              if (linkedNoteId != null && noteContent != null) {
                // Existing note being updated — ID is already known
                context.go('${AppRoute.notebookScreen}?id=$linkedNoteId');
              } else if (linkedNoteId == null && noteContent != null) {
                // New note being created by NoteBloc — wait for NoteCreated
                _pendingRedirectToNotebook = true;
              } else {
                // No note content — navigate with resourceId to create one in notebook
                context.go('${AppRoute.notebookScreen}?resourceId=${state.resource.id}&resourceGroupId=${widget.resourceGroupId}');
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
            setState(() => isSubmitting = false);
          } else if (state is NoteCreated && _pendingRedirectToNotebook) {
            _pendingRedirectToNotebook = false;
            context.go('${AppRoute.notebookScreen}?id=${state.note.id}');
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

