// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/material_group_model.dart';
import 'package:heliumapp/data/models/planner/material_group_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_state.dart'
    as material_state;
import 'package:heliumapp/presentation/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/controllers/materials/material_group_form_controller.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_style.dart';

class _MaterialGroupProvidedWidget extends StatefulWidget {
  final bool isEdit;
  final MaterialGroupModel? group;

  const _MaterialGroupProvidedWidget({required this.isEdit, this.group});

  @override
  State<_MaterialGroupProvidedWidget> createState() =>
      _MaterialGroupWidgetState();
}

class _MaterialGroupWidgetState
    extends BaseDialogState<_MaterialGroupProvidedWidget> {
  final MaterialGroupFormController _formController =
      MaterialGroupFormController();

  @override
  String get dialogTitle => 'Resource Group';

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _formController.titleController.text = widget.group!.title;
      _formController.shownOnCalendar = widget.group!.shownOnCalendar!;
    } else {
      _formController.titleController.clear();
      _formController.shownOnCalendar = true;
    }
  }

  @override
  void dispose() {
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<MaterialBloc, material_state.MaterialState>(
        listener: (context, state) {
          if (state is material_state.MaterialsError) {
            setState(() {
              errorMessage = state.message;
            });
          } else if (state is material_state.MaterialGroupCreated ||
              state is material_state.MaterialGroupUpdated) {
            Navigator.pop(context);
          }

          if (state is! material_state.MaterialsLoading) {
            setState(() {
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelAndTextFormField(
          label: 'Title',
          autofocus: kIsWeb || !widget.isEdit,
          controller: _formController.titleController,
          validator: BasicFormController.validateRequiredField,
          onFieldSubmitted: (value) => handleSubmit(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text(
                  "Hide this group's resources from Planner",
                  style: context.formLabel,
                ),
                value: !_formController.shownOnCalendar,
                onChanged: (value) {
                  setState(() {
                    _formController.shownOnCalendar = !value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void handleSubmit() {
    super.handleSubmit();

    if (_formController.formKey.currentState!.validate()) {
      final request = MaterialGroupRequestModel(
        title: _formController.titleController.text.trim(),
        shownOnCalendar: _formController.shownOnCalendar,
      );

      if (widget.isEdit) {
        context.read<MaterialBloc>().add(
          UpdateMaterialGroupEvent(
            origin: EventOrigin.dialog,
            materialGroupId: widget.group!.id,
            request: request,
          ),
        );
      } else {
        context.read<MaterialBloc>().add(
          CreateMaterialGroupEvent(
            origin: EventOrigin.dialog,
            request: request,
          ),
        );
      }
    }
  }
}

Future<void> showMaterialGroupDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required bool isEdit,
  MaterialGroupModel? group,
}) {
  final materialBloc = parentContext.read<MaterialBloc>();

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<MaterialBloc>.value(
        value: materialBloc,
        child: _MaterialGroupProvidedWidget(isEdit: isEdit, group: group),
      );
    },
  );
}
