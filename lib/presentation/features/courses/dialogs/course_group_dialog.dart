import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/request/course_group_request_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/courses/dialogs/course_exceptions_dialog.dart';
import 'package:heliumapp/presentation/features/courses/widgets/grade_scale_field.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/dialogs/conflict_resolving_dialog.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/courses/controllers/course_group_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_picker_field.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/course_exception_helpers.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

class _CourseGroupProvidedWidget extends StatefulWidget {
  final bool isEdit;
  final CourseGroupModel? group;
  final CourseGroupModel? latestGroup;

  const _CourseGroupProvidedWidget({
    required this.isEdit,
    this.group,
    this.latestGroup,
  });

  @override
  State<_CourseGroupProvidedWidget> createState() => _CourseGroupWidgetState();
}

class _CourseGroupWidgetState
    extends BaseDialogState<_CourseGroupProvidedWidget>
    with ConflictResolvingDialog<_CourseGroupProvidedWidget, CourseGroupModel> {
  final CourseGroupFormController _formController = CourseGroupFormController();

  @override
  String get dialogTitle => 'Group';

  @override
  double get desktopWidth => 370;

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _populateScreenData(widget.group!);
      isLoading = true;
      context.read<CourseBloc>().add(
        FetchCoursesScreenDataEvent(
          origin: EventOrigin.dialog,
          forceRefresh: true,
          passive: true,
        ),
      );
    } else {
      _formController.markChanged(userInitiated: false);
      _formController.exceptions = const [];
      _formController.titleController.clear();
      _formController.startDate = DateTime.now();
      _formController.endDate = DateTime.now().add(const Duration(days: 30));
      _formController.shownOnCalendar = true;
      if (widget.latestGroup != null) {
        _populateGradeScale(widget.latestGroup!);
      }
    }
  }

  void _populateGradeScale(CourseGroupModel group) {
    final isKnownPreset = GradeScaleTemplate.labels.containsKey(
      group.gradeScaleTemplate,
    );
    _formController.gradeScaleTemplate = isKnownPreset
        ? group.gradeScaleTemplate!
        : GradeScaleTemplate.custom;
    _formController.customGradeScale = isKnownPreset
        ? const []
        : group.gradeScale;
  }

  void _populateScreenData(CourseGroupModel group) {
    _formController.titleController.text = group.title;
    _formController.startDate = group.startDate;
    _formController.endDate = group.endDate;
    _formController.shownOnCalendar = group.shownOnCalendar!;
    _formController.exceptions = List<DateTime>.unmodifiable(group.exceptions);
    _populateGradeScale(group);
    trackVersion(group);
  }

  @override
  void applyLatest(CourseGroupModel latest) {
    _populateScreenData(latest);
    _formController.isChanged = false;
    _formController.isUserDirty = false;
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
          } else if (state is CoursesScreenDataFetched &&
              state.origin == EventOrigin.dialog &&
              isLoading) {
            final group = state.courseGroups
                .firstWhereOrNull((g) => g.id == widget.group!.id);
            setState(() {
              if (group == null) errorMessage = 'Group not found.';
              _populateScreenData(group ?? widget.group!);
              isLoading = false;
            });
          } else if (state is CourseGroupConflict) {
            resolveDialogConflict(state.latest);
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
  List<Widget> get additionalHeaderButtons {
    if (!widget.isEdit) return const [];
    return [
      HeliumIconButton(
        enabled: !isSubmitting,
        onPressed: () {
          showConfirmDeleteDialog(
            parentContext: context,
            item: widget.group!,
            label: widget.group!.title,
            additionalWarning:
                'Anything in this group, including classes and their assignments, attachments, notes, and other data, will also be deleted.',
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
        showTooltip: false,
        label: 'Delete',
        color: context.colorScheme.error,
      ),
    ];
  }

  @override
  Widget? buildSecondaryActions() {
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

  Future<void> _showHolidaysAndBreaks() async {
    final exceptions = await showCourseGroupExceptionsDialog(
      context: context,
      exceptions: _formController.exceptions,
      firstDate: _formController.startDate!,
      lastDate: _formController.endDate!,
    );
    if (exceptions == null || !mounted) return;
    _formController.markChanged();
    setState(() => _formController.exceptions = exceptions);
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
        HeliumDateRangeFields(
          from: _formController.startDate!,
          to: _formController.endDate!,
          onFromTap: () => _selectDate(context, true),
          onToTap: () => _selectDate(context, false),
        ),
        const SizedBox(height: 14),
        _buildGradeScaleField(context),
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

  Widget _buildGradeScaleField(BuildContext context) {
    final selected = _formController.gradeScaleTemplate;
    return GradeScaleField(
      items: [
        for (final MapEntry(key: preset, value: label)
            in GradeScaleTemplate.labels.entries)
          GradeScaleField.option(
            id: preset,
            label: label,
            bands: GradeScaleTemplate.scales[preset]!,
          ),
        if (_formController.customGradeScale.isNotEmpty)
          GradeScaleField.option(
            id: GradeScaleTemplate.custom,
            label: GradeScaleTemplate.summaryLabel(GradeScaleTemplate.custom),
            bands: _formController.customGradeScale,
          ),
      ],
      selected: selected,
      bands: selected == GradeScaleTemplate.custom
          ? _formController.customGradeScale
          : GradeScaleTemplate.scales[selected]!,
      bandsTitle: GradeScaleTemplate.summaryLabel(selected),
      onChanged: _onGradeScaleChanged,
    );
  }

  void _onGradeScaleChanged(int template) {
    _formController.markChanged();
    setState(() => _formController.gradeScaleTemplate = template);
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
        gradeScaleTemplate: _selectedPresetToSend,
        exceptions: CourseExceptionHelpers.withinRange(
          _formController.exceptions,
          _formController.startDate!,
          _formController.endDate!,
        ),
      );

      if (widget.isEdit) {
        context.read<CourseBloc>().add(
          UpdateCourseGroupEvent(
            origin: EventOrigin.dialog,
            courseGroupId: widget.group!.id,
            request: request,
            version: versionToSend,
          ),
        );
      } else {
        context.read<CourseBloc>().add(
          CreateCourseGroupEvent(origin: EventOrigin.dialog, request: request),
        );
      }
    }
  }

  int? get _selectedPresetToSend {
    final selected = _formController.gradeScaleTemplate;
    return selected == GradeScaleTemplate.custom ? null : selected;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_formController.startDate ?? DateTime.now())
          : (_formController.endDate ??
                DateTime.now().add(const Duration(days: 30))),
      firstDate: HeliumDateTime.earliestPickableDate(),
      lastDate: HeliumDateTime.latestPickableDate(),
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
  CourseGroupModel? latestGroup,
}) {
  final courseBloc = parentContext.read<CourseBloc>();
  final dialog = BlocProvider<CourseBloc>.value(
    value: courseBloc,
    child: _CourseGroupProvidedWidget(
      isEdit: isEdit,
      group: group,
      latestGroup: latestGroup,
    ),
  );

  if (PlatformBehavior.showsDialogsFullScreen(parentContext)) {
    return showScreenAsDialog(
      parentContext,
      barrierDismissible: false,
      width: double.infinity,
      insetPadding: EdgeInsets.zero,
      child: dialog,
    );
  }

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => dialog,
  );
}
