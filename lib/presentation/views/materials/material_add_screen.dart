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
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_state.dart'
    as material_state;
import 'package:heliumapp/presentation/views/core/multi_step_container.dart';
import 'package:heliumapp/presentation/widgets/materials/material_details_widget.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Shows material add/edit as a dialog on desktop, or navigates on mobile
void showMaterialAdd(
  BuildContext context, {
  required int materialGroupId,
  int? materialId,
  bool isEdit = false,
  MaterialBloc? materialBloc,
}) {
  final bloc = materialBloc ?? context.read<MaterialBloc>();

  if (Responsive.isMobile(context)) {
    context.push(
      AppRoutes.resourcesAddScreen,
      extra: MaterialAddArgs(
        materialBloc: bloc,
        materialGroupId: materialGroupId,
        materialId: materialId,
        isEdit: isEdit,
      ),
    );
  } else {
    showScreenAsDialog(
      context,
      child: BlocProvider<MaterialBloc>.value(
        value: bloc,
        child: MaterialAddScreen(
          materialGroupId: materialGroupId,
          materialId: materialId,
          isEdit: isEdit,
          isNew: !isEdit,
        ),
      ),
      width: AppConstants.centeredDialogWidth,
      alignment: Alignment.center,
    );
  }
}

class MaterialAddScreen extends MultiStepContainer {
  final int materialGroupId;
  final int? materialId;

  const MaterialAddScreen({
    super.key,
    required this.materialGroupId,
    this.materialId,
    required super.isEdit,
    required super.isNew,
  });

  @override
  State<MaterialAddScreen> createState() => _MaterialAddScreenState();
}

class _MaterialAddScreenState
    extends MultiStepContainerState<MaterialAddScreen> {
  final _detailsKey = GlobalKey<MaterialDetailsWidgetState>();

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
      final widgetSubmit = _detailsKey.currentState?.onSubmit;
      if (widgetSubmit != null) {
        setState(() => isSubmitting = true);
        widgetSubmit();
      }
    };
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<MaterialBloc, material_state.MaterialState>(
        listener: (context, state) {
          if (state is material_state.MaterialsError) {
            showSnackBar(context, state.message!, isError: true);
            setState(() => isSubmitting = false);
          } else if (state is material_state.MaterialCreated ||
              state is material_state.MaterialUpdated) {
            showSnackBar(context, 'Resource saved');
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
      builder: (context) => MaterialDetailsWidget(
        key: _detailsKey,
        materialGroupId: widget.materialGroupId,
        materialId: widget.materialId,
        isEdit: widget.isEdit,
      ),
    ),
  ];

  @override
  List<MultiStepDefinition> get steps => _steps;
}
