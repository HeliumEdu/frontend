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
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/courses/controllers/course_group_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class _CourseGroupProvidedWidget extends StatefulWidget {
  final bool isEdit;
  final CourseGroupModel? group;

  const _CourseGroupProvidedWidget({required this.isEdit, this.group});

  @override
  State<_CourseGroupProvidedWidget> createState() => _CourseGroupWidgetState();
}

class _CourseGroupWidgetState
    extends BaseDialogState<_CourseGroupProvidedWidget> {
  final CourseGroupFormController _formController = CourseGroupFormController();

  @override
  String get dialogTitle => 'Class Group';

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _formController.titleController.text = widget.group!.title;
      _formController.startDate = widget.group!.startDate;
      _formController.endDate = widget.group!.endDate;
      _formController.shownOnCalendar = widget.group!.shownOnCalendar!;
    } else {
      _formController.titleController.clear();
      _formController.startDate = DateTime.now();
      _formController.endDate = DateTime.now().add(const Duration(days: 30));
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
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CoursesError) {
            setState(() {
              errorMessage = state.message;
            });
          } else if (state is CourseGroupCreated ||
              state is CourseGroupUpdated) {
            Navigator.pop(context);
          }

          if (state is! CoursesLoading) {
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
        Text('From', style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        GestureDetector(
          onTap: () => _selectDate(context, true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: context.colorScheme.outline.withValues(alpha: 0.2),
              ),
              color: context.colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  HeliumDateTime.formatDate(_formController.startDate!),
                  style: AppStyles.formText(context),
                ),
                Icon(
                  Icons.calendar_today,
                  color: context.colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('To', style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        GestureDetector(
          onTap: () => _selectDate(context, false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: context.colorScheme.outline.withValues(alpha: 0.2),
              ),
              color: context.colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  HeliumDateTime.formatDate(_formController.endDate!),
                  style: AppStyles.formText(context),
                ),
                Icon(
                  Icons.calendar_today,
                  color: context.colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text(
                  "Hide this group's classes and assignments from the Planner",
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
      if (_formController.endDate!.isBefore(_formController.startDate!)) {
        setState(() {
          errorMessage = '"To" date must come after "From" date';
          isSubmitting = false;
        });
        return;
      }

      final request = CourseGroupRequestModel(
        title: _formController.titleController.text.trim(),
        startDate: HeliumDateTime.formatDateForApi(_formController.startDate!),
        endDate: HeliumDateTime.formatDateForApi(_formController.endDate!),
        shownOnCalendar: _formController.shownOnCalendar,
      );

      if (widget.isEdit) {
        context.read<CourseBloc>().add(
          UpdateCourseGroupEvent(
            origin: EventOrigin.dialog,
            courseGroupId: widget.group!.id,
            request: request,
          ),
        );
      } else {
        context.read<CourseBloc>().add(
          CreateCourseGroupEvent(origin: EventOrigin.dialog, request: request),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_formController.startDate ?? DateTime.now())
          : (_formController.endDate ??
                DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _formController.startDate = picked;
        } else {
          _formController.endDate = picked;
        }
      });
    }
  }
}

Future<void> showCourseGroupDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required bool isEdit,
  CourseGroupModel? group,
}) {
  final courseBloc = parentContext.read<CourseBloc>();

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<CourseBloc>.value(
        value: courseBloc,
        child: _CourseGroupProvidedWidget(isEdit: isEdit, group: group),
      );
    },
  );
}
