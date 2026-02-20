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
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/features/resources/widgets/resource_details.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Shows resource add/edit as a dialog on desktop, or navigates on mobile
void showResourceAdd(
  BuildContext context, {
  required int resourceGroupId,
  int? resourceId,
  bool isEdit = false,
}) {
  final resourceBloc = context.read<ResourceBloc>();

  if (Responsive.isMobile(context)) {
    context.push(
      AppRoute.resourcesAddScreen,
      extra: ResourceAddArgs(
        resourceBloc: resourceBloc,
        resourceGroupId: resourceGroupId,
        resourceId: resourceId,
        isEdit: isEdit,
      ),
    );
  } else {
    showScreenAsDialog(
      context,
      child: BlocProvider<ResourceBloc>.value(
        value: resourceBloc,
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
    return () {
      final detailsState = _detailsKey.currentState;
      if (detailsState == null) return;
      if (detailsState.isLoading || isSubmitting) return;
      setState(() => isSubmitting = true);
      detailsState.onSubmit();
    };
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ResourceBloc, ResourceState>(
        listener: (context, state) {
          if (state is ResourcesError) {
            showSnackBar(context, state.message!, isError: true);
            setState(() => isSubmitting = false);
          } else if (state is ResourceCreated ||
              state is ResourceUpdated) {
            // Only show snackbar for creates
            if (state is ResourceCreated) {
              showSnackBar(context, 'Resource created', useRootMessenger: true);
            }
            cancelAction();
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
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}

