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
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/planner_item_base_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/planner/controllers/planner_item_form_controller.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/ui/components/select_field.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'dart:async';

import 'package:heliumapp/utils/quill_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart' as tz;

final _log = Logger('presentation.widgets');

class PlannerItemDetails extends StatefulWidget {
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel? userSettings;
  final ValueChanged<bool>? onIsEventChanged;
  final VoidCallback? onActionStarted;
  final VoidCallback? onSubmitRequested;

  const PlannerItemDetails({
    super.key,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    this.isFromMonthView = false,
    required this.isEdit,
    required this.isNew,
    this.userSettings,
    this.onIsEventChanged,
    this.onActionStarted,
    this.onSubmitRequested,
  });

  @override
  State<PlannerItemDetails> createState() => PlannerItemDetailsState();
}

class PlannerItemDetailsState extends State<PlannerItemDetails> {
  final PlannerItemFormController formController = PlannerItemFormController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  // Entity IDs (can be updated for clone)
  int? _eventId;
  int? _homeworkId;

  StreamSubscription<DocChange>? _notesSubscription;

  bool isLoading = true;
  bool _isSubmitting = false;
  bool _hasRequestedInitialFocus = false;
  bool _isEvent = false;
  PlannerItemBaseModel? _plannerItem;
  List<CourseGroupModel> _courseGroups = [];
  List<CourseModel> _courses = [];
  List<DropDownItem<CourseModel>> _courseItems = [];
  List<CourseScheduleModel> _courseSchedules = [];
  List<CategoryModel> _categories = [];
  List<DropDownItem<CategoryModel>> _categoryItems = [];
  List<ResourceModel> _resources = [];
  String? _preferredCategoryName;
  List<String> _preferredResourceNames = [];

  @override
  void initState() {
    super.initState();

    _eventId = widget.eventId;
    _homeworkId = widget.homeworkId;

    if (!widget.isEdit) formController.markChanged();

    formController.gradeFocusNode.addListener(() {
      if (!formController.gradeFocusNode.hasFocus) {
        setState(() {});
      }
    });

    context.read<PlannerItemBloc>().add(
      FetchPlannerItemScreenDataEvent(
        origin: EventOrigin.subScreen,
        eventId: _eventId,
        homeworkId: _homeworkId,
      ),
    );
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _titleFocusNode.dispose();
    _notesFocusNode.dispose();
    formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlannerItemBloc, PlannerItemState>(
      listener: (context, state) {
        if (state is PlannerItemScreenDataFetched) {
          _populateInitialPlannerItemStateData(state);
        }
      },
      child: _buildContent(context),
    );
  }

  /// Loads a different entity (used after clone)
  void loadEntity({int? eventId, int? homeworkId}) {
    setState(() {
      _eventId = eventId;
      _homeworkId = homeworkId;
      isLoading = true;
      _plannerItem = null;
      formController.isChanged = false;
    });

    context.read<PlannerItemBloc>().add(
      FetchPlannerItemScreenDataEvent(
        origin: EventOrigin.subScreen,
        eventId: eventId,
        homeworkId: homeworkId,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading || widget.userSettings == null) {
      return const Center(child: LoadingIndicator(expanded: false));
    }

    final List<ResourceModel> filteredResources = _resources.where((resource) {
      return resource.courses.isNotEmpty &&
          resource.courses.any((c) => c == formController.selectedCourse);
    }).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: formController.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Details', style: AppStyles.featureText(context)),
                      if (widget.isEdit && _plannerItem != null)
                          Row(
                            children: [
                              HeliumIconButton(
                                onPressed: _onClone,
                                icon: Icons.copy_outlined,
                                tooltip: 'Clone',
                              ),
                              const SizedBox(width: 8),
                              HeliumIconButton(
                                onPressed: _onDelete,
                                icon: Icons.delete_outline,
                                tooltip: 'Delete',
                                color: context.colorScheme.error,
                              ),
                            ],
                          ),
                      if (!widget.isEdit && _courses.isNotEmpty)
                        Row(
                          children: [
                            SegmentedButton<bool>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment<bool>(
                                  value: false,
                                  tooltip: 'Assignment',
                                  icon: Icon(AppConstants.assignmentIcon),
                                ),
                                ButtonSegment<bool>(
                                  value: true,
                                  tooltip: 'Event',
                                  icon: Icon(AppConstants.eventIcon),
                                ),
                              ],
                              selected: {_isEvent},
                              onSelectionChanged: (Set<bool> selected) {
                                setState(() {
                                  _isEvent = selected.first;
                                });
                                widget.onIsEventChanged?.call(_isEvent);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    key: const Key(PlannerItemFormController.titleField),
                    label: 'Title',
                    autofocus: kIsWeb,
                    focusNode: _titleFocusNode,
                    controller: formController.titleController,
                    validator: BasicFormController.validateRequiredField,
                    fieldKey: formController.getFieldKey('title'),
                    onChanged: (_) => formController.markChanged(),
                    onFieldSubmitted: (value) =>
                        (widget.onSubmitRequested ?? onSubmit).call(),
                  ),
                  const SizedBox(height: 14),
                  if (!_isEvent) ...[
                    DropDown(
                      label: 'Class',
                      initialValue: _courseItems.firstWhere(
                        (c) => c.id == formController.selectedCourse,
                      ),
                      items: _courseItems,
                      onChanged: (value) {
                        formController.markChanged();
                        _selectCourse(value!.id);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: Text(
                            'All Day',
                            style: AppStyles.formLabel(context),
                          ),
                          value: formController.isAllDay,
                          onChanged: (value) {
                            formController.markChanged();
                            setState(() {
                              formController.isAllDay = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: Text(
                            'Show End',
                            style: AppStyles.formLabel(context),
                          ),
                          value: formController.showEndDateTime,
                          onChanged: (value) {
                            formController.markChanged();
                            setState(
                              () => formController.showEndDateTime =
                                  value ?? false,
                            );
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _buildDateTimeSection(context),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  if (!_isEvent) ...[
                    _buildHomeworkFields(context, filteredResources),
                  ],
                  _buildPrioritySlider(context),
                  if (!_isEvent) ...[_buildCompletionSection(context)],
                  const SizedBox(height: 14),
                  NotesEditor(
                    key: ObjectKey(formController.notesController),
                    controller: formController.notesController,
                    focusNode: _notesFocusNode,
                    onOpenInNotes: widget.isEdit ? () => onSubmit(redirectToNotebook: true) : null,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                context,
                'Start Date',
                formController.startDate,
                () => _selectDate(context, true),
              ),
            ),
            if (formController.showEndDateTime) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  context,
                  'End Date',
                  formController.endDate,
                  () => _selectDate(context, false),
                ),
              ),
            ],
          ],
        ),
        if (!formController.isAllDay) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  context,
                  'Start Time',
                  formController.startTime,
                  () => _selectTime(context, true),
                ),
              ),
              if (formController.showEndDateTime) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePicker(
                    context,
                    'End Time',
                    formController.endTime,
                    () => _selectTime(context, false),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        GestureDetector(
          onTap: onTap,
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
                  HeliumDateTime.formatDate(date),
                  style: AppStyles.formText(context),
                ),
                Icon(
                  Icons.calendar_today,
                  color: context.colorScheme.primary,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    TimeOfDay time,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        GestureDetector(
          onTap: onTap,
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
                  HeliumTime.format(time),
                  style: AppStyles.formText(context),
                ),
                Icon(
                  Icons.access_time,
                  color: context.colorScheme.primary,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworkFields(
    BuildContext context,
    List<ResourceModel> filteredResources,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropDown(
          label: 'Category',
          initialValue: _categoryItems.isNotEmpty
              ? _categoryItems.firstWhere(
                  (c) => c.id == formController.selectedCategory,
                )
              : null,
          items: _categoryItems
              .where(
                (category) =>
                    category.value?.course == formController.selectedCourse,
              )
              .toList(),
          onChanged: (value) {
            formController.markChanged();
            _selectCategory(value!.id);
          },
        ),
        const SizedBox(height: 14),
        Text('Resources', style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        SelectField<ResourceModel>(
          items: filteredResources,
          selectedIds: formController.selectedResources,
          onChanged: (selected) {
            formController.markChanged();
            _updateSelectedResources(selected);
          },
          enabled: formController.selectedCourse != null &&
              filteredResources.isNotEmpty,
          buttonLabel: 'Select resources',
          labelBuilder: (item, onDelete) => ResourceTitleLabel(
            title: item.title,
            userSettings: widget.userSettings!,
            onDelete: onDelete,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildPrioritySlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: HeliumColors.getColorForPriority(
              formController.priorityValue,
            ),
            thumbColor: HeliumColors.getColorForPriority(
              formController.priorityValue,
            ),
            overlayColor: HeliumColors.getColorForPriority(
              formController.priorityValue,
            ).withValues(alpha: 0.2),
            valueIndicatorTextStyle: AppStyles.buttonText(context),
          ),
          child: Slider(
            value: formController.priorityValue,
            min: 0,
            max: 100,
            divisions: 10,
            label: '${(formController.priorityValue / 10).round()}',
            onChanged: (value) {
              formController.markChanged();
              Feedback.forTap(context);
              setState(() {
                formController.priorityValue = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 2),
        SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                child: CheckboxListTile(
                  key: const Key(PlannerItemFormController.completeField),
                  title: Text('Complete', style: AppStyles.formLabel(context)),
                  value: formController.isCompleted,
                  onChanged: (value) {
                    formController.markChanged();
                    setState(() {
                      formController.isCompleted = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (formController.isCompleted) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: LabelAndTextFormField(
                    key: const Key(PlannerItemFormController.gradeField),
                    hintText: 'Grade',
                    controller: formController.gradeController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\./]')),
                    ],
                    focusNode: formController.gradeFocusNode,
                    onChanged: (_) => formController.markChanged(),
                    onFieldSubmitted: _onGradeFieldSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 98,
                  child: GradeLabel(
                    grade: GradeHelper.gradeForDisplay(
                      formController.gradeController.text.trim(),
                    ),
                    userSettings: widget.userSettings!,
                    compact: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }

  Future<void> onSubmit({bool redirectToNotebook = false}) async {
    if (isLoading || _isSubmitting) return;
    _log.info('Submitting planner item (isEvent=$_isEvent, isEdit=${widget.isEdit}, redirectToNotebook=$redirectToNotebook)');
    if (formController.validateAndScrollToError()) {
      // Warn if homework dates fall outside the course's date range
      if (!_isEvent && formController.selectedCourse != null) {
        final selectedCourse = _courses.firstWhere(
          (c) => c.id == formController.selectedCourse,
        );

        final courseStart = HeliumDateTime.dateOnly(selectedCourse.startDate);
        final courseEnd = HeliumDateTime.dateOnly(selectedCourse.endDate);
        final homeworkStart = HeliumDateTime.dateOnly(formController.startDate);
        final homeworkEnd = HeliumDateTime.dateOnly(formController.endDate);

        if (homeworkStart.isBefore(courseStart) ||
            homeworkEnd.isAfter(courseEnd)) {
          _log.info('Assignment dates fall outside course date range (courseId=${selectedCourse.id}, courseStart=$courseStart, courseEnd=$courseEnd, homeworkStart=$homeworkStart, homeworkEnd=$homeworkEnd)');
          SnackBarHelper.show(
            context,
            "This assignment won't appear in the Todos view, since it is now outside the class's date range",
            seconds: 5,
            type: SnackType.info,
          );
        }
      }

      // Notify parent that action is starting (validation passed)
      setState(() => _isSubmitting = true);
      widget.onActionStarted?.call();

      // Get note content for bloc
      final noteContent = buildNotesDelta(formController.notesController);

      final start = HeliumDateTime.formatDateAndTimeForApi(
        formController.startDate,
        formController.isAllDay ? null : formController.startTime,
        widget.userSettings!.timeZone,
      );

      String end;
      if (formController.showEndDateTime) {
        final endDateForApi = formController.isAllDay
            ? formController.endDate.add(const Duration(days: 1))
            : formController.endDate;
        end = HeliumDateTime.formatDateAndTimeForApi(
          endDateForApi,
          formController.isAllDay ? null : formController.endTime,
          widget.userSettings!.timeZone,
        );
      } else {
        if (formController.isAllDay) {
          final endDate = formController.startDate.add(
            const Duration(days: 1),
          );
          end = HeliumDateTime.formatDateAndTimeForApi(
            endDate,
            null,
            widget.userSettings!.timeZone,
          );
        } else {
          end = start;
        }
      }

      if (_isEvent) {
        final request = EventRequestModel(
          title: formController.titleController.text.trim(),
          allDay: formController.isAllDay,
          showEndTime: formController.showEndDateTime,
          start: start,
          end: end,
          priority: _getPriorityValue(),
          comments: _plannerItem?.comments ?? '',
        );

        if (!mounted) return;
        if (widget.isEdit && widget.eventId != null) {
          context.read<PlannerItemBloc>().add(
            UpdateEventEvent(
              origin: EventOrigin.subScreen,
              id: widget.eventId!,
              request: request,
              linkedNoteId: formController.linkedNoteId,
              noteContent: noteContent,
              redirectToNotebook: redirectToNotebook,
            ),
          );
        } else {
          context.read<PlannerItemBloc>().add(
            CreateEventEvent(
              origin: EventOrigin.subScreen,
              request: request,
              noteContent: noteContent,
              redirectToNotebook: redirectToNotebook,
            ),
          );
        }
      } else {
        final selectedCourse = _courses.firstWhere(
          (c) => c.id == formController.selectedCourse,
        );

        String gradeValue;
        if (!formController.isCompleted) {
          gradeValue = '-1/100';
        } else {
          final gradeText = formController.gradeController.text.trim();
          gradeValue = gradeText.isEmpty ? '-1/100' : gradeText;
        }

        final request = HomeworkRequestModel(
          title: formController.titleController.text.trim(),
          allDay: formController.isAllDay,
          showEndTime: formController.showEndDateTime,
          start: start,
          end: end,
          priority: _getPriorityValue(),
          currentGrade: gradeValue,
          completed: formController.isCompleted,
          category: formController.selectedCategory,
          resources: formController.selectedResources,
          course: formController.selectedCourse!,
        );

        if (!mounted) return;
        if (widget.isEdit && widget.homeworkId != null) {
          // Use original course for URL path (backend filters by URL course_id)
          final originalHomework = _plannerItem as HomeworkModel;
          final originalCourse = _courses.firstWhere(
            (c) => c.id == originalHomework.course.id,
          );
          context.read<PlannerItemBloc>().add(
            UpdateHomeworkEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: originalCourse.courseGroup,
              courseId: originalCourse.id,
              homeworkId: widget.homeworkId!,
              request: request,
              linkedNoteId: formController.linkedNoteId,
              noteContent: noteContent,
              redirectToNotebook: redirectToNotebook,
            ),
          );
        } else {
          context.read<PlannerItemBloc>().add(
            CreateHomeworkEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: selectedCourse.courseGroup,
              courseId: selectedCourse.id,
              request: request,
              noteContent: noteContent,
              redirectToNotebook: redirectToNotebook,
            ),
          );
        }
      }
    } else {
      SnackBarHelper.show(
        context,
        'Fix the highlighted fields, then try again.',
        type: SnackType.error,
      );
    }
  }

  void _setupNotesListener() {
    _notesSubscription?.cancel();
    _notesSubscription = formController.notesController.document.changes.listen((change) {
      if (isNoteEdited(change)) formController.markChanged();
    });
  }

  Future<void> _populateInitialPlannerItemStateData(
    PlannerItemScreenDataFetched state,
  ) async {
    setState(() {
      _courseGroups = state.courseGroups;
      _courses = state.courses;
      final sortedCourses = PlannerHelper.sortByGroupStartThenByTitle(
        _courses,
        _courseGroups,
      );
      _courseItems = [];
      for (int i = 0; i < sortedCourses.length; i++) {
        final course = sortedCourses[i];
        if (i > 0 && course.courseGroup != sortedCourses[i - 1].courseGroup) {
          _courseItems.add(DropDownItem(id: -1, isDivider: true));
        }
        _courseItems.add(
          DropDownItem(
            id: course.id,
            value: course,
            iconData: Icons.school_outlined,
            iconColor: course.color,
          ),
        );
      }
      _courseSchedules = state.courseSchedules;
      _categories = state.categories;
      _categoryItems = _categories
          .map(
            (c) => DropDownItem(
              id: c.id,
              value: c,
              iconData: Icons.category_outlined,
              iconColor: c.color,
            ),
          )
          .toList();
      _resources = state.resources;

      if (_courses.isEmpty) {
        _isEvent = true;
      }
      if (!widget.isEdit) {
        widget.onIsEventChanged?.call(_isEvent);
      }
    });

    if (widget.isEdit) {
      final plannerItem = state.plannerItem!;
      _plannerItem = plannerItem;

      setState(() {
        formController.titleController.text = plannerItem.title;
        formController.isAllDay = plannerItem.allDay;
        formController.showEndDateTime = plannerItem.showEndTime;
        formController.priorityValue = plannerItem.priority.toDouble();

        final startDateTime = HeliumDateTime.toLocal(
          plannerItem.start,
          widget.userSettings!.timeZone,
        );
        formController.startDate = startDateTime;
        if (!formController.isAllDay) {
          formController.startTime = TimeOfDay.fromDateTime(startDateTime);
        }

        final endDateTime = HeliumDateTime.toLocal(
          plannerItem.end,
          widget.userSettings!.timeZone,
        );
        if (formController.isAllDay) {
          formController.endDate = endDateTime.subtract(
            const Duration(days: 1),
          );
        } else {
          formController.endDate = endDateTime;
          formController.endTime = TimeOfDay.fromDateTime(endDateTime);
        }

        if (plannerItem is HomeworkModel) {
          formController.selectedCourse = plannerItem.course.id;
          formController.isCompleted = plannerItem.completed;
          if (plannerItem.currentGrade != null &&
              plannerItem.currentGrade!.isNotEmpty) {
            if (plannerItem.currentGrade == '-1/100') {
              formController.gradeController.text = '';
            } else {
              formController.gradeController.text = plannerItem.currentGrade!;
            }
          }

          formController.selectedCategory = plannerItem.category.id;

          if (plannerItem.resources.isNotEmpty) {
            formController.selectedResources = plannerItem.resources
                .where((e) => _resources.any((m) => m.id == e.id))
                .map((e) => e.id)
                .toList();
          } else {
            formController.selectedResources = [];
          }
        }
      });

      // Update _isEvent based on entity type
      _isEvent = widget.eventId != null;
    } else {
      if (widget.initialDate != null) {
        formController.startDate = widget.initialDate!;
        formController.endDate = widget.initialDate!;
      }

      if (!_isEvent && _courses.isNotEmpty) {
        _selectCourse(_courses.first.id);
      }

      if (widget.initialDate != null && !widget.isFromMonthView) {
        final tzDateTime = tz.TZDateTime.from(
          widget.initialDate!,
          widget.userSettings!.timeZone,
        );
        setState(() {
          formController.startTime = TimeOfDay.fromDateTime(tzDateTime);
          formController.endTime = TimeOfDay.fromDateTime(tzDateTime);
        });
      }
    }

    if (widget.isEdit && state.linkedNote != null) {
      formController.linkedNoteId = state.linkedNote!.id;
      formController.notesController.dispose();
      formController.notesController = state.linkedNote!.content != null
          ? QuillController(
              document: Document.fromJson(state.linkedNote!.content!['ops'] as List),
              selection: const TextSelection.collapsed(offset: 0),
            )
          : QuillController.basic();
    }

    setState(() {
      isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupNotesListener();
    });

    // Request focus once on mobile for create mode
    if (!_hasRequestedInitialFocus && !kIsWeb && !widget.isEdit) {
      _hasRequestedInitialFocus = true;
      // Defer focus request so the text field is attached to the tree before
      // requestFocus is called; BLoC listeners fire during the build pipeline
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocusNode.requestFocus();
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    CourseModel? selectedCourse;
    if (!_isEvent && formController.selectedCourse != null) {
      selectedCourse = _courses.where((c) => c.id == formController.selectedCourse).firstOrNull;
    }

    final firstDate = selectedCourse?.startDate ?? DateTime.now().subtract(const Duration(days: 365 * 10));
    final lastDate = selectedCourse?.endDate ?? DateTime.now().add(const Duration(days: 365 * 10));
    final rawInitial = isStartDate ? formController.startDate : formController.endDate;
    final initialDate = rawInitial.isBefore(firstDate) ? firstDate
        : (rawInitial.isAfter(lastDate) ? lastDate : rawInitial);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      confirmText: 'Select',
    );

    if (picked != null) {
      formController.markChanged();
      setState(() {
        if (isStartDate) {
          formController.startDate = picked;
          if (formController.isAllDay) {
            formController.endDate = DateRangeEnforcer.adjustEndDate(
              picked,
              formController.endDate,
            );
          } else {
            final adjusted = DateRangeEnforcer.adjustEnd(
              startDate: picked,
              startTime: formController.startTime,
              endDate: formController.endDate,
              endTime: formController.endTime,
            );
            formController.endDate = adjusted.date;
            if (adjusted.time != null) {
              formController.endTime = adjusted.time!;
            }
          }
        } else {
          formController.endDate = picked;
          if (formController.isAllDay) {
            formController.startDate = DateRangeEnforcer.adjustStartDate(
              formController.startDate,
              picked,
            );
          } else {
            final adjusted = DateRangeEnforcer.adjustStart(
              startDate: formController.startDate,
              startTime: formController.startTime,
              endDate: picked,
              endTime: formController.endTime,
            );
            formController.startDate = adjusted.date;
            if (adjusted.time != null) {
              formController.startTime = adjusted.time!;
            }
          }
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? formController.startTime
          : formController.endTime,
      initialEntryMode: Responsive.isTouchDevice(context)
          ? TimePickerEntryMode.dial
          : TimePickerEntryMode.input,
      confirmText: 'Select',
    );

    if (picked != null) {
      formController.markChanged();
      setState(() {
        if (isStartTime) {
          formController.startTime = picked;
          final adjusted = DateRangeEnforcer.adjustEnd(
            startDate: formController.startDate,
            startTime: picked,
            endDate: formController.endDate,
            endTime: formController.endTime,
          );
          formController.endDate = adjusted.date;
          if (adjusted.time != null) {
            formController.endTime = adjusted.time!;
          }
        } else {
          formController.endTime = picked;
          final adjusted = DateRangeEnforcer.adjustStart(
            startDate: formController.startDate,
            startTime: formController.startTime,
            endDate: formController.endDate,
            endTime: picked,
          );
          formController.startDate = adjusted.date;
          if (adjusted.time != null) {
            formController.startTime = adjusted.time!;
          }
        }
      });
    }
  }

  String _resourceTitleById(int id) {
    return _resources.firstWhere((m) => m.id == id).title;
  }

  int _getPriorityValue() {
    return formController.priorityValue.round();
  }

  void _onGradeFieldSubmitted(String _) {
    _submitAfterGradeBlur();
  }

  Future<void> _submitAfterGradeBlur() async {
    if (formController.gradeFocusNode.hasFocus) {
      formController.gradeFocusNode.unfocus();
      // Let blur listeners normalize grade input before form validation runs.
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;
    await onSubmit();
  }

  void _selectCourse(int courseId) {
    setState(() {
      if (_preferredCategoryName == null &&
          formController.selectedCategory != null) {
        _preferredCategoryName = _categories
            .where((c) => c.id == formController.selectedCategory)
            .firstOrNull
            ?.title;
      }
      if (_preferredResourceNames.isEmpty &&
          formController.selectedResources.isNotEmpty) {
        _preferredResourceNames = formController.selectedResources
            .map((id) => _resources.where((m) => m.id == id).firstOrNull?.title)
            .whereType<String>()
            .toList();
      }

      formController.selectedCourse = courseId;

      if (_categories.isNotEmpty) {
        final categoriesForCourse = _categories
            .where((c) => c.course == formController.selectedCourse)
            .toList();

        final matchingCategory = _preferredCategoryName != null
            ? categoriesForCourse
                  .where((c) => c.title == _preferredCategoryName)
                  .firstOrNull
            : null;

        formController.selectedCategory =
            matchingCategory?.id ?? categoriesForCourse.first.id;
      }

      final resourcesForCourse = _resources
          .where((m) => m.courses.contains(formController.selectedCourse))
          .toList();

      formController.selectedResources = resourcesForCourse
          .where((m) => _preferredResourceNames.contains(m.title))
          .map((m) => m.id)
          .toList();

      if (!widget.isEdit) {
        final matchingSchedule = _courseSchedules
            .where((cs) => cs.course == formController.selectedCourse)
            .firstOrNull;

        if (matchingSchedule != null) {
          formController.startTime = matchingSchedule.getStartTimeForDay(
            HeliumDateTime.formatDayNameShort(formController.startDate),
          );
          formController.endTime = matchingSchedule.getEndTimeForDay(
            HeliumDateTime.formatDayNameShort(formController.endDate),
          );
        } else {
          const noon = TimeOfDay(hour: 12, minute: 0);
          formController.startTime = noon;
          formController.endTime = noon;
        }
      }
    });
  }

  void _selectCategory(int categoryId) {
    setState(() {
      formController.selectedCategory = categoryId;
      _preferredCategoryName = _categories
          .where((c) => c.id == categoryId)
          .firstOrNull
          ?.title;
    });
  }

  void _updateSelectedResources(List<int> resourceIds) {
    setState(() {
      formController.selectedResources = resourceIds;
      _preferredResourceNames = resourceIds
          .map((id) => _resourceTitleById(id))
          .toList();
    });
  }

  void _onDelete() {
    if (_plannerItem == null) return;

    final CourseModel? course;
    if (_plannerItem is HomeworkModel) {
      course = _courses.firstWhere(
        (c) => c.id == (_plannerItem as HomeworkModel).course.id,
      );
    } else {
      course = null;
    }

    final Function(PlannerItemBaseModel) onDelete;
    if (_plannerItem is HomeworkModel) {
      onDelete = (item) {
        widget.onActionStarted?.call();
        context.read<PlannerItemBloc>().add(
          DeleteHomeworkEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: course!.courseGroup,
            courseId: course.id,
            homeworkId: item.id,
          ),
        );
      };
    } else if (_plannerItem is EventModel) {
      onDelete = (item) {
        widget.onActionStarted?.call();
        context.read<PlannerItemBloc>().add(
          DeleteEventEvent(origin: EventOrigin.subScreen, id: item.id),
        );
      };
    } else {
      return;
    }

    showConfirmDeleteDialog(
      parentContext: context,
      item: _plannerItem!,
      additionalWarning: 'Its attachments and note will also be deleted.',
      onDelete: onDelete,
    );
  }

  Future<void> _onClone() async {
    if (_plannerItem == null) return;

    widget.onActionStarted?.call();

    final clonedTitle = PlannerHelper.generateClonedTitle(_plannerItem!.title);

    final start = HeliumDateTime.formatDateAndTimeForApi(
      formController.startDate,
      formController.isAllDay ? null : formController.startTime,
      widget.userSettings!.timeZone,
    );

    String end;
    if (formController.showEndDateTime) {
      final endDateForApi = formController.isAllDay
          ? formController.endDate.add(const Duration(days: 1))
          : formController.endDate;
      end = HeliumDateTime.formatDateAndTimeForApi(
        endDateForApi,
        formController.isAllDay ? null : formController.endTime,
        widget.userSettings!.timeZone,
      );
    } else {
      if (formController.isAllDay) {
        final endDate = formController.startDate.add(const Duration(days: 1));
        end = HeliumDateTime.formatDateAndTimeForApi(
          endDate,
          null,
          widget.userSettings!.timeZone,
        );
      } else {
        end = start;
      }
    }

    if (_plannerItem is EventModel) {
      final request = EventRequestModel(
        title: clonedTitle,
        allDay: formController.isAllDay,
        showEndTime: formController.showEndDateTime,
        start: start,
        end: end,
        priority: _getPriorityValue(),
        comments: widget.isEdit ? null : '',
      );

      if (!mounted) return;
      context.read<PlannerItemBloc>().add(
        CreateEventEvent(
          origin: EventOrigin.subScreen,
          request: request,
          isClone: true,
        ),
      );
    } else if (_plannerItem is HomeworkModel) {
      final homework = _plannerItem as HomeworkModel;
      final selectedCourse = _courses.firstWhere(
        (c) => c.id == homework.course.id,
      );

      final request = HomeworkRequestModel(
        title: clonedTitle,
        allDay: formController.isAllDay,
        showEndTime: formController.showEndDateTime,
        start: start,
        end: end,
        priority: _getPriorityValue(),
        comments: widget.isEdit ? null : '',
        currentGrade: '-1/100',
        completed: false,
        category: formController.selectedCategory,
        resources: formController.selectedResources,
        course: homework.course.id,
      );

      if (!mounted) return;
      context.read<PlannerItemBloc>().add(
        CreateHomeworkEvent(
          origin: EventOrigin.subScreen,
          courseGroupId: selectedCourse.courseGroup,
          courseId: selectedCourse.id,
          request: request,
          isClone: true,
        ),
      );
    }
  }
}
