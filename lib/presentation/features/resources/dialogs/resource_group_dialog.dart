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
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_group_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/resources/controllers/resource_group_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_style.dart';

class _ResourceGroupProvidedWidget extends StatefulWidget {
  final bool isEdit;
  final ResourceGroupModel? group;

  const _ResourceGroupProvidedWidget({required this.isEdit, this.group});

  @override
  State<_ResourceGroupProvidedWidget> createState() =>
      _ResourceGroupWidgetState();
}

class _ResourceGroupWidgetState
    extends BaseDialogState<_ResourceGroupProvidedWidget> {
  final ResourceGroupFormController _formController =
      ResourceGroupFormController();

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
      BlocListener<ResourceBloc, ResourceState>(
        listener: (context, state) {
          if (state is ResourcesError) {
            setState(() {
              errorMessage = state.message;
            });
          } else if (state is ResourceGroupCreated ||
              state is ResourceGroupUpdated) {
            Navigator.pop(context);
          }

          if (state is! ResourcesLoading) {
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
                  style: AppStyles.formLabel(context),
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
      final request = ResourceGroupRequestModel(
        title: _formController.titleController.text.trim(),
        shownOnCalendar: _formController.shownOnCalendar,
      );

      if (widget.isEdit) {
        context.read<ResourceBloc>().add(
          UpdateResourceGroupEvent(
            origin: EventOrigin.dialog,
            resourceGroupId: widget.group!.id,
            request: request,
          ),
        );
      } else {
        context.read<ResourceBloc>().add(
          CreateResourceGroupEvent(
            origin: EventOrigin.dialog,
            request: request,
          ),
        );
      }
    }
  }
}

Future<void> showResourceGroupDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required bool isEdit,
  ResourceGroupModel? group,
}) {
  final resourceBloc = parentContext.read<ResourceBloc>();

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<ResourceBloc>.value(
        value: resourceBloc,
        child: _ResourceGroupProvidedWidget(isEdit: isEdit, group: group),
      );
    },
  );
}
