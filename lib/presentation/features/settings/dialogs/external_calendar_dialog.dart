import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/models/planner/request/external_calendar_request_model.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_state.dart';
import 'package:heliumapp/presentation/features/settings/controllers/external_calendar_form_controller.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/components/color_selector.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

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

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _populateInitialStateData(widget.externalCalendar!);
      isLoading = true;
      context.read<ExternalCalendarBloc>().add(
        FetchExternalCalendarsEvent(
          origin: EventOrigin.dialog,
          forceRefresh: true,
          passive: true,
        ),
      );
    } else {
      _formController.markChanged();
      _formController.selectedColor = HeliumColors.getRandomColor();
      _formController.shownOnCalendar = true;
    }
  }

  void _populateInitialStateData(ExternalCalendarModel externalCalendar) {
    _formController.titleController.text = externalCalendar.title;
    _formController.urlController.text = externalCalendar.url.toString();
    _formController.selectedColor = externalCalendar.color;
    _formController.shownOnCalendar = externalCalendar.shownOnCalendar!;
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
              isLoading = false;
            });
          } else if (state is ExternalCalendarsFetched &&
              state.origin == EventOrigin.dialog &&
              isLoading) {
            final externalCalendar = state.externalCalendars.firstWhereOrNull(
              (c) => c.id == widget.externalCalendar!.id,
            );
            setState(() {
              if (externalCalendar == null) {
                errorMessage = 'External calendar not found.';
              }
              _populateInitialStateData(
                externalCalendar ?? widget.externalCalendar!,
              );
              isLoading = false;
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
          autofocus: PlatformBehavior.autofocusesOnOpen || !widget.isEdit,
          controller: _formController.titleController,
          validator: BasicFormController.validateRequiredField,
          onChanged: (_) => _formController.markChanged(),
          onFieldSubmitted: (value) => handleSubmit(),
        ),
        const SizedBox(height: 14),
        LabelAndTextFormField(
          label: 'URL (iCal)',
          controller: _formController.urlController,
          validator: BasicFormController.validateRequiredUrl,
          keyboardType: TextInputType.url,
          onChanged: (_) => _formController.markChanged(),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ColorSelector(
              label: 'Color',
              selectedColor: _formController.selectedColor,
              onColorSelected: (color) {
                _formController.markChanged();
                setState(() {
                  _formController.selectedColor = color;
                });
              },
            ),
            Row(
              children: [
                Text('Show on calendar', style: AppStyles.formLabel(context)),
                const SizedBox(width: 4),
                Switch.adaptive(
                  value: _formController.shownOnCalendar,
                  activeTrackColor: context.colorScheme.primary,
                  onChanged: (value) {
                    _formController.markChanged();
                    Feedback.forTap(context);
                    setState(() {
                      _formController.shownOnCalendar = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  void handleSubmit() {
    if (!_formController.isChanged) {
      cancelAction();
      return;
    }
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
  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _ExternalCalendarProvidedWidget(
        isEdit: isEdit,
        externalCalendar: externalCalendar,
      );
    },
  );
}
