// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_event.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_state.dart';
import 'package:heliumapp/presentation/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/presentation/forms/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/forms/settings/external_calendar_form_controller.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class _ExternalCalendarProvidedWidget extends StatefulWidget {
  final bool isEdit;
  final ExternalCalendarModel? externalCalendar;

  const _ExternalCalendarProvidedWidget({
    required this.isEdit,
    this.externalCalendar,
  });

  @override
  State<_ExternalCalendarProvidedWidget> createState() =>
      _ExternalCalendarWidgetState();
}

class _ExternalCalendarWidgetState
    extends BaseDialogState<_ExternalCalendarProvidedWidget> {
  final ExternalCalendarFormController _formController =
      ExternalCalendarFormController();

  @override
  String get dialogTitle => 'External Calendar';

  static const String _defaultTitle = 'Holidays';
  static const String _defaultUrl =
      'https://calendar.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics';

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _formController.titleController.text = widget.externalCalendar!.title;
      _formController.urlController.text = widget.externalCalendar!.url;
      _formController.selectedColor = widget.externalCalendar!.color;
      _formController.shownOnCalendar =
          widget.externalCalendar!.shownOnCalendar!;
    } else {
      _formController.titleController.text = _defaultTitle;
      _formController.urlController.text = _defaultUrl;
      _formController.selectedColor = HeliumColors.getRandomColor();
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
      BlocListener<ExternalCalendarBloc, ExternalCalendarState>(
        listener: (context, state) {
          if (state is ExternalCalendarsError) {
            setState(() {
              errorMessage = state.message;
            });
          } else if (state is ExternalCalendarCreated ||
              state is ExternalCalendarUpdated) {
            Navigator.pop(context);
          }

          if (state is! ExternalCalendarsLoading) {
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
          label: 'Name',
          autofocus: true,
          controller: _formController.titleController,
          validator: BasicFormController.validateRequiredField,
          onFieldSubmitted: (value) => handleSubmit(),
        ),
        const SizedBox(height: 14),
        LabelAndTextFormField(
          label: 'URL',
          controller: _formController.urlController,
          validator: BasicFormController.validateRequiredUrl,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Color', style: context.formLabel),
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Feedback.forTap(context);
                  showColorPickerDialog(
                    parentContext: context,
                    initialColor: _formController.selectedColor,
                    onSelected: (color) {
                      setState(() {
                        _formController.selectedColor = color;
                        Navigator.pop(context);
                      });
                    },
                  );
                },
                child: Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    color: _formController.selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show on calendar', style: context.formLabel),
            Switch.adaptive(
              value: _formController.shownOnCalendar,
              activeTrackColor: context.colorScheme.primary,
              onChanged: (value) {
                Feedback.forTap(context);
                setState(() {
                  _formController.shownOnCalendar = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void handleSubmit() {
    super.handleSubmit();

    // Clean URL field before validation
    _formController.urlController.text = BasicFormController.cleanUrl(
      _formController.urlController.text.trim(),
    );

    if (_formController.formKey.currentState!.validate()) {
      final request = ExternalCalendarRequestModel(
        title: _formController.titleController.text.trim(),
        url: _formController.urlController.text.trim(),
        color: HeliumColors.colorToHex(_formController.selectedColor),
        shownOnCalendar: _formController.shownOnCalendar,
      );

      if (widget.isEdit) {
        context.read<ExternalCalendarBloc>().add(
          UpdateExternalCalendarEvent(
            origin: EventOrigin.dialog,
            id: widget.externalCalendar!.id,
            request: request,
          ),
        );
      } else {
        context.read<ExternalCalendarBloc>().add(
          CreateExternalCalendarEvent(
            origin: EventOrigin.dialog,
            request: request,
          ),
        );
      }
    }
  }
}

Future<void> showExternalCalendarDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required bool isEdit,
  ExternalCalendarModel? externalCalendar,
}) {
  final externalCalendarBloc = parentContext.read<ExternalCalendarBloc>();

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<ExternalCalendarBloc>.value(
        value: externalCalendarBloc,
        child: _ExternalCalendarProvidedWidget(
          isEdit: isEdit,
          externalCalendar: externalCalendar,
        ),
      );
    },
  );
}
