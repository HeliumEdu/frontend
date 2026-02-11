// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_bloc.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_event.dart';
import 'package:heliumapp/presentation/bloc/reminder/reminder_state.dart';
import 'package:heliumapp/presentation/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/controllers/core/reminder_form_controller.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class _ReminderProvidedWidget extends StatefulWidget {
  final bool isEdit;
  final UserSettingsModel userSettings;
  final Function createReminderRequest;
  final ReminderModel? reminder;

  const _ReminderProvidedWidget({
    required this.isEdit,
    required this.userSettings,
    required this.createReminderRequest,
    this.reminder,
  });

  @override
  State<_ReminderProvidedWidget> createState() => _ReminderWidgetState();
}

class _ReminderWidgetState extends BaseDialogState<_ReminderProvidedWidget> {
  final ReminderFormController _formController = ReminderFormController();

  @override
  String get dialogTitle => 'Reminder';

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _formController.messageController.text = widget.reminder!.message;
      _formController.offsetController.text = widget.reminder!.offset
          .toString();
      _formController.reminderType = widget.reminder!.type;
      _formController.reminderOffsetType = widget.reminder!.offsetType;
    } else {
      _formController.messageController.clear();
      _formController.offsetController.text = widget
          .userSettings
          .defaultReminderOffset
          .toString();
      _formController.reminderType = widget.userSettings.defaultReminderType;
      _formController.reminderOffsetType =
          widget.userSettings.defaultReminderOffsetType;
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
      BlocListener<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is RemindersError) {
            setState(() {
              errorMessage = state.message;
            });
          } else if (state is ReminderCreated || state is ReminderUpdated) {
            Navigator.pop(context);
          }

          if (state is! RemindersLoading) {
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
          label: 'Message',
          autofocus: kIsWeb || !widget.isEdit,
          maxLines: 3,
          controller: _formController.messageController,
          validator: BasicFormController.validateRequiredField,
          onFieldSubmitted: (value) => handleSubmit(),
        ),
        const SizedBox(height: 14),
        DropDown(
          label: 'Default reminder type',
          initialValue: ReminderConstants.typeItems.firstWhere(
            (rt) => rt.id == _formController.reminderType,
          ),
          items: ReminderConstants.typeItems
              .where((t) =>
                  t.id == _formController.reminderType ||
                  (t.id != 2 && t.id != 0))
              .toList(),
          onChanged: (value) {
            setState(() {
              _formController.reminderType = value!.id;
            });
          },
        ),
        const SizedBox(height: 12),
        Text('When', style: AppStyles.formLabel(context)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: LabelAndTextFormField(
                controller: _formController.offsetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isEmpty) {
                    _formController.offsetController.text = '0';
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: DropDown(
                initialValue: ReminderConstants.offsetTypeItems.firstWhere(
                  (ot) => ot.id == _formController.reminderOffsetType,
                ),
                items: ReminderConstants.offsetTypeItems,
                onChanged: (value) {
                  setState(() {
                    _formController.reminderOffsetType = value!.id;
                  });
                },
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
      final request = widget.createReminderRequest(
        _formController.messageController.text.trim(),
        HeliumConversion.toInt(_formController.offsetController.text.trim())!,
        _formController.reminderOffsetType,
        _formController.reminderType,
      );

      if (widget.isEdit) {
        context.read<ReminderBloc>().add(
          UpdateReminderEvent(
            origin: EventOrigin.dialog,
            id: widget.reminder!.id,
            request: request,
          ),
        );
      } else {
        context.read<ReminderBloc>().add(
          CreateReminderEvent(origin: EventOrigin.dialog, request: request),
        );
      }
    }
  }
}

Future<void> showReminderDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required bool isEdit,
  required UserSettingsModel userSettings,
  required Function createReminderRequest,
  ReminderModel? reminder,
}) {
  final reminderBloc = parentContext.read<ReminderBloc>();

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<ReminderBloc>.value(
        value: reminderBloc,
        child: _ReminderProvidedWidget(
          isEdit: isEdit,
          userSettings: userSettings,
          createReminderRequest: createReminderRequest,
          reminder: reminder,
        ),
      );
    },
  );
}
