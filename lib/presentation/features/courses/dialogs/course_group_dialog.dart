import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/courses/dialogs/course_exceptions_dialog.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/courses/controllers/course_group_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

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
  late List<DateTime> _groupExceptions;
  String? _version;

  /// Set when the user picks Overwrite, so the next save is unconditional.
  bool _overwriteNewer = false;

  @override
  String get dialogTitle => 'Group';

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _populateInitialStateData(widget.group!);
      isLoading = true;
      context.read<CourseBloc>().add(
        FetchCoursesScreenDataEvent(
          origin: EventOrigin.dialog,
          forceRefresh: true,
          passive: true,
        ),
      );
    } else {
      _formController.markChanged();
      _groupExceptions = [];
      _formController.titleController.clear();
      _formController.startDate = DateTime.now();
      _formController.endDate = DateTime.now().add(const Duration(days: 30));
      _formController.shownOnCalendar = true;
    }
  }

  void _populateInitialStateData(CourseGroupModel group) {
    _formController.titleController.text = group.title;
    _formController.startDate = group.startDate;
    _formController.endDate = group.endDate;
    _formController.shownOnCalendar = group.shownOnCalendar!;
    _groupExceptions = List<DateTime>.from(group.exceptions);
    _version = group.version;
  }

  Future<void> _resolveConflict(CourseGroupModel latest) async {
    final resolution = await confirmConflictResolution(context);
    if (!mounted) return;
    switch (resolution) {
      case ConflictResolution.loadLatest:
        setState(() {
          _populateInitialStateData(latest);
          _formController.isChanged = false;
          _formController.isUserDirty = false;
        });
      case ConflictResolution.overwrite:
        _overwriteNewer = true;
        handleSubmit();
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
            if (ModalRoute.of(context)?.isCurrent == false) return;
            setState(() {
              errorMessage = state.message;
              isLoading = false;
            });
          } else if (state is CourseGroupExceptionsUpdated &&
              state.courseGroup.id == widget.group?.id) {
            setState(() {
              _groupExceptions = state.courseGroup.exceptions;
              _version = state.courseGroup.version;
            });
          } else if (state is CoursesScreenDataFetched &&
              state.origin == EventOrigin.dialog &&
              isLoading) {
            final group = state.courseGroups
                .firstWhereOrNull((g) => g.id == widget.group!.id);
            setState(() {
              if (group == null) errorMessage = 'Group not found.';
              _populateInitialStateData(group ?? widget.group!);
              isLoading = false;
            });
          } else if (state is CourseGroupConflict) {
            _resolveConflict(state.latest);
          } else if (state is CourseGroupCreated ||
              state is CourseGroupUpdated ||
              state is CourseGroupDeleted) {
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
  Widget? buildLeadingAction() {
    if (!widget.isEdit) return null;
    return Semantics(
      label: 'Delete',
      button: true,
      child: HeliumIconButton(
        enabled: !isSubmitting,
        onPressed: () {
          showConfirmDeleteDialog(
            parentContext: context,
            item: widget.group!,
            label: widget.group!.title,
            additionalWarning:
                'Anything in this group, including classes and their assignments, attachments and other data, will also be deleted.',
            onDelete: (value) {
              setState(() => isSubmitting = true);
              context.read<CourseBloc>().add(
                DeleteCourseGroupEvent(
                  origin: EventOrigin.dialog,
                  courseGroupId: value.id,
                ),
              );
            },
          );
        },
        icon: Icons.delete_outlined,
        color: context.colorScheme.error,
        minimumSize: actionButtonSize,
      ),
    );
  }

  @override
  Widget? buildSecondaryActions() {
    if (!widget.isEdit) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: HeliumElevatedButton(
        buttonText: 'Holidays & Breaks',
        backgroundColor: context.colorScheme.onSurfaceVariant,
        enabled: !isLoading && !isSubmitting,
        onPressed: _showHolidaysAndBreaks,
      ),
    );
  }

  Future<void> _showHolidaysAndBreaks() {
    return showCourseGroupExceptionsDialog(
      context: context,
      courseGroupId: widget.group!.id,
      exceptions: _groupExceptions,
      firstDate: _formController.startDate!,
      lastDate: _formController.endDate!,
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelAndTextFormField(
          label: 'Title',
          autofocus: PlatformBehavior.autofocusesOnOpen || !widget.isEdit,
          controller: _formController.titleController,
          validator: BasicFormController.validateRequiredField,
          onChanged: (_) => _formController.markChanged(),
          onFieldSubmitted: (value) => handleSubmit(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From', style: AppStyles.formLabel(context)),
                  const SizedBox(height: 9),
                  Semantics(
                    label: 'Pick start date',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        Feedback.forTap(context);
                        _selectDate(context, true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.colorScheme.outline
                                .withValues(alpha: 0.2),
                          ),
                          color: context.colorScheme.surface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              HeliumDateTime.formatDate(
                                _formController.startDate!,
                              ),
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
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To', style: AppStyles.formLabel(context)),
                  const SizedBox(height: 9),
                  Semantics(
                    label: 'Pick end date',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        Feedback.forTap(context);
                        _selectDate(context, false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.colorScheme.outline
                                .withValues(alpha: 0.2),
                          ),
                          color: context.colorScheme.surface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              HeliumDateTime.formatDate(
                                _formController.endDate!,
                              ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: HeliumCheckboxListTile(
                title: Text(
                  "Hide this group's classes and assignments from the Planner and Resources",
                  style: AppStyles.formLabel(context),
                ),
                value: !_formController.shownOnCalendar,
                onChanged: (value) {
                  _formController.markChanged();
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
    if (!_formController.isChanged) {
      cancelAction();
      return;
    }
    super.handleSubmit();

    if (_formController.formKey.currentState!.validate()) {
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
            version: _overwriteNewer ? null : _version,
          ),
        );
        _overwriteNewer = false;
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
      confirmText: 'Select',
    );

    if (picked != null) {
      _formController.markChanged();
      setState(() {
        if (isStartDate) {
          _formController.startDate = picked;
          _formController.endDate = DateRangeEnforcer.adjustEndDate(
            picked,
            _formController.endDate!,
          );
        } else {
          _formController.endDate = picked;
          _formController.startDate = DateRangeEnforcer.adjustStartDate(
            _formController.startDate!,
            picked,
          );
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
