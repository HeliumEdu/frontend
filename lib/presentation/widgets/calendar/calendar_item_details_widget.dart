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
import 'package:heliumapp/data/models/planner/calendar_item_base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/material_model.dart';
import 'package:heliumapp/data/models/planner/request/event_request_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_event.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_state.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/controllers/calendar/calendar_item_form_controller.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/dialogs/select_dialog.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/views/core/multi_step_container.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/grade_label.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/material_title_label.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:timezone/standalone.dart' as tz;

class CalendarItemDetailsWidget extends StatefulWidget {
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel? userSettings;
  final ValueChanged<bool>? onIsEventChanged;
  final VoidCallback? onActionStarted;

  const CalendarItemDetailsWidget({
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
  });

  @override
  State<CalendarItemDetailsWidget> createState() =>
      CalendarItemDetailsWidgetState();
}

class CalendarItemDetailsWidgetState extends State<CalendarItemDetailsWidget> {
  final CalendarItemFormController _formController =
      CalendarItemFormController();

  // Entity IDs (can be updated for clone)
  int? _eventId;
  int? _homeworkId;

  // State
  bool isLoading = true;
  bool isSubmitting = false;
  bool _isEvent = false;
  CalendarItemBaseModel? _calendarItem;
  List<CourseGroupModel> _courseGroups = [];
  List<CourseModel> _courses = [];
  List<DropDownItem<CourseModel>> _courseItems = [];
  List<CourseScheduleModel> _courseSchedules = [];
  List<CategoryModel> _categories = [];
  List<DropDownItem<CategoryModel>> _categoryItems = [];
  List<MaterialModel> _materials = [];
  String? _preferredCategoryName;
  List<String> _preferredMaterialNames = [];

  @override
  void initState() {
    super.initState();

    _eventId = widget.eventId;
    _homeworkId = widget.homeworkId;

    _formController.gradeFocusNode.addListener(() {
      if (!_formController.gradeFocusNode.hasFocus) {
        setState(() {});
      }
    });

    context.read<CalendarItemBloc>().add(
      FetchCalendarItemScreenDataEvent(
        origin: EventOrigin.subScreen,
        eventId: _eventId,
        homeworkId: _homeworkId,
      ),
    );
  }

  /// Loads a different entity (used after clone)
  void loadEntity({int? eventId, int? homeworkId}) {
    setState(() {
      _eventId = eventId;
      _homeworkId = homeworkId;
      isLoading = true;
      _calendarItem = null;
    });

    context.read<CalendarItemBloc>().add(
      FetchCalendarItemScreenDataEvent(
        origin: EventOrigin.subScreen,
        eventId: eventId,
        homeworkId: homeworkId,
      ),
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarItemBloc, CalendarItemState>(
      listener: (context, state) {
        if (state is CalendarItemScreenDataFetched) {
          _populateInitialCalendarItemStateData(state);
        }

        if (state is! CalendarItemsLoading) {
          setState(() {
            isSubmitting = false;
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading || widget.userSettings == null) {
      return const Center(child: LoadingIndicator(expanded: false));
    }

    final List<MaterialModel> filteredMaterials = _materials.where((material) {
      return material.courses.isNotEmpty &&
          material.courses.any((c) => c == _formController.selectedCourse);
    }).toList();

    return Column(
      children: [
        if (!widget.isEdit && _courses.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<bool>(value: false, icon: Icon(Icons.school)),
                  ButtonSegment<bool>(value: true, icon: Icon(Icons.event)),
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
          const SizedBox(height: 12),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formController.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Details', style: AppStyles.featureText(context)),
                      if (widget.isEdit && _calendarItem != null)
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
                    ],
                  ),
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    label: 'Title',
                    autofocus: kIsWeb || !widget.isEdit,
                    controller: _formController.titleController,
                    validator: BasicFormController.validateRequiredField,
                    fieldKey: _formController.getFieldKey('title'),
                    onFieldSubmitted: (value) => onSubmit(),
                  ),
                  const SizedBox(height: 14),
                  if (!_isEvent) ...[
                    DropDown(
                      label: 'Class',
                      initialValue: _courseItems.firstWhere(
                        (c) => c.id == _formController.selectedCourse,
                      ),
                      items: _courseItems,
                      onChanged: (value) {
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
                          value: _formController.isAllDay,
                          onChanged: (value) {
                            setState(() {
                              _formController.isAllDay = value!;
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
                          value: _formController.showEndDateTime,
                          onChanged: (value) {
                            setState(
                              () => _formController.showEndDateTime =
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
                    _buildHomeworkFields(context, filteredMaterials),
                  ],
                  _buildPrioritySlider(context),
                  if (!_isEvent) ...[_buildCompletionSection(context)],
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
                _formController.startDate,
                () => _selectDate(context, true),
              ),
            ),
            if (_formController.showEndDateTime) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  context,
                  'End Date',
                  _formController.endDate,
                  () => _selectDate(context, false),
                ),
              ),
            ],
          ],
        ),
        if (!_formController.isAllDay) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  context,
                  'Start Time',
                  _formController.startTime,
                  () => _selectTime(context, true),
                ),
              ),
              if (_formController.showEndDateTime) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePicker(
                    context,
                    'End Time',
                    _formController.endTime,
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
    List<MaterialModel> filteredMaterials,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropDown(
          label: 'Category',
          initialValue: _categoryItems.isNotEmpty
              ? _categoryItems.firstWhere(
                  (c) => c.id == _formController.selectedCategory,
                )
              : null,
          items: _categoryItems
              .where(
                (category) =>
                    category.value?.course == _formController.selectedCourse,
              )
              .toList(),
          onChanged: (value) {
            _selectCategory(value!.id);
          },
        ),
        const SizedBox(height: 14),
        Text('Resources', style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
            color: context.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formController.selectedMaterials.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: _formController.selectedMaterials.map((id) {
                    return MaterialTitleLabel(
                      title: _materialTitleById(id),
                      userSettings: widget.userSettings!,
                      onDelete: () => _removeMaterial(id),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: AbsorbPointer(
                  absorbing:
                      _formController.selectedCourse == null ||
                      filteredMaterials.isEmpty,
                  child: Opacity(
                    opacity:
                        _formController.selectedCourse == null ||
                            filteredMaterials.isEmpty
                        ? 0.5
                        : 1,
                    child: TextButton.icon(
                      onPressed: () => showSelectDialog<MaterialModel>(
                        parentContext: context,
                        items: filteredMaterials,
                        initialSelected: _formController.selectedMaterials
                            .toSet(),
                        onConfirm: (selected) =>
                            _updateSelectedMaterials(selected.toList()),
                      ),
                      icon: Icon(Icons.add, color: context.colorScheme.primary),
                      label: Text(
                        'Select resources',
                        style: AppStyles.formLabel(
                          context,
                        ).copyWith(color: context.colorScheme.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
              _formController.priorityValue,
            ),
            thumbColor: HeliumColors.getColorForPriority(
              _formController.priorityValue,
            ),
            overlayColor: HeliumColors.getColorForPriority(
              _formController.priorityValue,
            ).withValues(alpha: 0.2),
            valueIndicatorTextStyle: AppStyles.buttonText(context),
          ),
          child: Slider(
            value: _formController.priorityValue,
            min: 0,
            max: 100,
            divisions: 10,
            label: '${(_formController.priorityValue / 10).round()}',
            onChanged: (value) {
              Feedback.forTap(context);
              setState(() {
                _formController.priorityValue = value;
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
                  title: Text('Complete', style: AppStyles.formLabel(context)),
                  value: _formController.isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _formController.isCompleted = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_formController.isCompleted) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: LabelAndTextFormField(
                    hintText: 'Grade',
                    controller: _formController.gradeController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\./]')),
                    ],
                    focusNode: _formController.gradeFocusNode,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 98,
                  child: GradeLabel(
                    grade: Format.gradeForDisplay(
                      _formController.gradeController.text.trim(),
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

  Future<void> _populateInitialCalendarItemStateData(
    CalendarItemScreenDataFetched state,
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
      _materials = state.materials;

      if (_courses.isEmpty) {
        _isEvent = true;
      }
    });

    if (widget.isEdit) {
      final calendarItem = state.calendarItem!;
      _calendarItem = calendarItem;

      setState(() {
        _formController.titleController.text = calendarItem.title;
        _formController.isAllDay = calendarItem.allDay;
        _formController.showEndDateTime = calendarItem.showEndTime;
        _formController.priorityValue = calendarItem.priority.toDouble();
        _formController.initialNotes = calendarItem.comments;

        final startDateTime = HeliumDateTime.toLocal(
          calendarItem.start,
          widget.userSettings!.timeZone,
        );
        _formController.startDate = startDateTime;
        if (!_formController.isAllDay) {
          _formController.startTime = TimeOfDay.fromDateTime(startDateTime);
        }

        final endDateTime = HeliumDateTime.toLocal(
          calendarItem.end,
          widget.userSettings!.timeZone,
        );
        if (_formController.isAllDay) {
          _formController.endDate = endDateTime.subtract(
            const Duration(days: 1),
          );
        } else {
          _formController.endDate = endDateTime;
          _formController.endTime = TimeOfDay.fromDateTime(endDateTime);
        }

        if (calendarItem is HomeworkModel) {
          _formController.selectedCourse = calendarItem.course.id;
          _formController.isCompleted = calendarItem.completed;
          if (calendarItem.currentGrade != null &&
              calendarItem.currentGrade!.isNotEmpty) {
            if (calendarItem.currentGrade == '-1/100') {
              _formController.gradeController.text = '';
            } else {
              _formController.gradeController.text = calendarItem.currentGrade!;
            }
          }

          _formController.selectedCategory = calendarItem.category.id;

          if (calendarItem.materials.isNotEmpty) {
            _formController.selectedMaterials = calendarItem.materials
                .where((e) => _materials.any((m) => m.id == e.id))
                .map((e) => e.id)
                .toList();
          } else {
            _formController.selectedMaterials = [];
          }
        }
      });

      // Update _isEvent based on entity type
      _isEvent = widget.eventId != null;
    } else {
      if (widget.initialDate != null) {
        _formController.startDate = widget.initialDate!;
        _formController.endDate = widget.initialDate!;
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
          _formController.startTime = TimeOfDay.fromDateTime(tzDateTime);
          _formController.endTime = TimeOfDay.fromDateTime(tzDateTime);
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _formController.startDate
          : _formController.endDate,
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

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? _formController.startTime
          : _formController.endTime,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _formController.startTime = picked;
        } else {
          _formController.endTime = picked;
        }
      });
    }
  }

  String _materialTitleById(int id) {
    return _materials.firstWhere((m) => m.id == id).title;
  }

  int _getPriorityValue() {
    return _formController.priorityValue.round();
  }

  Future<void> onSubmit() async {
    if (_formController.validateAndScrollToError()) {
      if (_formController.endDate.isBefore(_formController.startDate)) {
        SnackBarHelper.show(
          context,
          '"End Date" must come after "Start Date"',
          isError: true,
        );
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      final start = HeliumDateTime.formatDateAndTimeForApi(
        _formController.startDate,
        _formController.isAllDay ? null : _formController.startTime,
        widget.userSettings!.timeZone,
      );

      String end;
      if (_formController.showEndDateTime) {
        final endDateForApi = _formController.isAllDay
            ? _formController.endDate.add(const Duration(days: 1))
            : _formController.endDate;
        end = HeliumDateTime.formatDateAndTimeForApi(
          endDateForApi,
          _formController.isAllDay ? null : _formController.endTime,
          widget.userSettings!.timeZone,
        );
      } else {
        if (_formController.isAllDay) {
          final endDate = _formController.startDate.add(
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
          title: _formController.titleController.text.trim(),
          allDay: _formController.isAllDay,
          showEndTime: _formController.showEndDateTime,
          start: start,
          end: end,
          priority: _getPriorityValue(),
          comments: widget.isEdit ? _formController.initialNotes : '',
        );

        if (!mounted) return;
        if (widget.isEdit && widget.eventId != null) {
          context.read<CalendarItemBloc>().add(
            UpdateEventEvent(
              origin: EventOrigin.subScreen,
              id: widget.eventId!,
              request: request,
            ),
          );
        } else {
          context.read<CalendarItemBloc>().add(
            CreateEventEvent(origin: EventOrigin.subScreen, request: request),
          );
        }
      } else {
        final selectedCourse = _courses.firstWhere(
          (c) => c.id == _formController.selectedCourse,
        );

        String gradeValue;
        if (!_formController.isCompleted) {
          gradeValue = '-1/100';
        } else {
          final gradeText = _formController.gradeController.text.trim();
          gradeValue = gradeText.isEmpty ? '-1/100' : gradeText;
        }

        final request = HomeworkRequestModel(
          title: _formController.titleController.text.trim(),
          allDay: _formController.isAllDay,
          showEndTime: _formController.showEndDateTime,
          start: start,
          end: end,
          priority: _getPriorityValue(),
          comments: widget.isEdit ? _formController.initialNotes : '',
          currentGrade: gradeValue,
          completed: _formController.isCompleted,
          category: _formController.selectedCategory,
          materials: _formController.selectedMaterials,
          course: _formController.selectedCourse!,
        );

        if (!mounted) return;
        if (widget.isEdit && widget.homeworkId != null) {
          context.read<CalendarItemBloc>().add(
            UpdateHomeworkEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: selectedCourse.courseGroup,
              courseId: selectedCourse.id,
              homeworkId: widget.homeworkId!,
              request: request,
            ),
          );
        } else {
          context.read<CalendarItemBloc>().add(
            CreateHomeworkEvent(
              origin: EventOrigin.subScreen,
              courseGroupId: selectedCourse.courseGroup,
              courseId: selectedCourse.id,
              request: request,
            ),
          );
        }
      }
    } else {
      SnackBarHelper.show(
        context,
        'Fix the highlighted fields, then try again.',
        isError: true,
      );
    }
  }

  void _selectCourse(int courseId) {
    setState(() {
      if (_preferredCategoryName == null &&
          _formController.selectedCategory != null) {
        _preferredCategoryName = _categories
            .where((c) => c.id == _formController.selectedCategory)
            .firstOrNull
            ?.title;
      }
      if (_preferredMaterialNames.isEmpty &&
          _formController.selectedMaterials.isNotEmpty) {
        _preferredMaterialNames = _formController.selectedMaterials
            .map((id) => _materials.where((m) => m.id == id).firstOrNull?.title)
            .whereType<String>()
            .toList();
      }

      _formController.selectedCourse = courseId;

      if (_categories.isNotEmpty) {
        final categoriesForCourse = _categories
            .where((c) => c.course == _formController.selectedCourse)
            .toList();

        final matchingCategory = _preferredCategoryName != null
            ? categoriesForCourse
                  .where((c) => c.title == _preferredCategoryName)
                  .firstOrNull
            : null;

        _formController.selectedCategory =
            matchingCategory?.id ?? categoriesForCourse.first.id;
      }

      final materialsForCourse = _materials
          .where((m) => m.courses.contains(_formController.selectedCourse))
          .toList();

      _formController.selectedMaterials = materialsForCourse
          .where((m) => _preferredMaterialNames.contains(m.title))
          .map((m) => m.id)
          .toList();

      if (!widget.isEdit) {
        final matchingSchedule = _courseSchedules
            .where((cs) => cs.course == _formController.selectedCourse)
            .firstOrNull;

        if (matchingSchedule != null) {
          _formController.startTime = matchingSchedule.getStartTimeForDay(
            HeliumDateTime.formatDayNameShort(_formController.startDate),
          );
          _formController.endTime = matchingSchedule.getEndTimeForDay(
            HeliumDateTime.formatDayNameShort(_formController.endDate),
          );
        } else {
          const noon = TimeOfDay(hour: 12, minute: 0);
          _formController.startTime = noon;
          _formController.endTime = noon;
        }
      }
    });
  }

  void _selectCategory(int categoryId) {
    setState(() {
      _formController.selectedCategory = categoryId;
      _preferredCategoryName = _categories
          .where((c) => c.id == categoryId)
          .firstOrNull
          ?.title;
    });
  }

  void _updateSelectedMaterials(List<int> materialIds) {
    setState(() {
      _formController.selectedMaterials = materialIds;
      _preferredMaterialNames = materialIds
          .map((id) => _materialTitleById(id))
          .toList();
    });
  }

  void _removeMaterial(int id) {
    final updated = List<int>.from(_formController.selectedMaterials)
      ..remove(id);
    _updateSelectedMaterials(updated);
  }

  void _onDelete() {
    if (_calendarItem == null) return;

    final CourseModel? course;
    if (_calendarItem is HomeworkModel) {
      course = _courses.firstWhere(
        (c) => c.id == (_calendarItem as HomeworkModel).course.id,
      );
    } else {
      course = null;
    }

    final Function(CalendarItemBaseModel) onDelete;
    if (_calendarItem is HomeworkModel) {
      onDelete = (item) {
        widget.onActionStarted?.call();
        context.read<CalendarItemBloc>().add(
          DeleteHomeworkEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: course!.courseGroup,
            courseId: course.id,
            homeworkId: item.id,
          ),
        );
      };
    } else if (_calendarItem is EventModel) {
      onDelete = (item) {
        widget.onActionStarted?.call();
        context.read<CalendarItemBloc>().add(
          DeleteEventEvent(origin: EventOrigin.subScreen, id: item.id),
        );
      };
    } else {
      return;
    }

    showConfirmDeleteDialog(
      parentContext: context,
      item: _calendarItem!,
      onDelete: onDelete,
    );
  }

  Future<void> _onClone() async {
    if (_calendarItem == null) return;

    widget.onActionStarted?.call();
    setState(() {
      isSubmitting = true;
    });

    final clonedTitle = PlannerHelper.generateClonedTitle(_calendarItem!.title);

    final start = HeliumDateTime.formatDateAndTimeForApi(
      _formController.startDate,
      _formController.isAllDay ? null : _formController.startTime,
      widget.userSettings!.timeZone,
    );

    String end;
    if (_formController.showEndDateTime) {
      final endDateForApi = _formController.isAllDay
          ? _formController.endDate.add(const Duration(days: 1))
          : _formController.endDate;
      end = HeliumDateTime.formatDateAndTimeForApi(
        endDateForApi,
        _formController.isAllDay ? null : _formController.endTime,
        widget.userSettings!.timeZone,
      );
    } else {
      if (_formController.isAllDay) {
        final endDate = _formController.startDate.add(const Duration(days: 1));
        end = HeliumDateTime.formatDateAndTimeForApi(
          endDate,
          null,
          widget.userSettings!.timeZone,
        );
      } else {
        end = start;
      }
    }

    if (_calendarItem is EventModel) {
      final request = EventRequestModel(
        title: clonedTitle,
        allDay: _formController.isAllDay,
        showEndTime: _formController.showEndDateTime,
        start: start,
        end: end,
        priority: _getPriorityValue(),
        comments: widget.isEdit ? null : '',
      );

      if (!mounted) return;
      context.read<CalendarItemBloc>().add(
        CreateEventEvent(
          origin: EventOrigin.subScreen,
          request: request,
          isClone: true,
        ),
      );
    } else if (_calendarItem is HomeworkModel) {
      final homework = _calendarItem as HomeworkModel;
      final selectedCourse = _courses.firstWhere(
        (c) => c.id == homework.course.id,
      );

      final request = HomeworkRequestModel(
        title: clonedTitle,
        allDay: _formController.isAllDay,
        showEndTime: _formController.showEndDateTime,
        start: start,
        end: end,
        priority: _getPriorityValue(),
        comments: widget.isEdit ? null : '',
        currentGrade: '-1/100',
        completed: false,
        category: _formController.selectedCategory,
        materials: _formController.selectedMaterials,
        course: homework.course.id,
      );

      if (!mounted) return;
      context.read<CalendarItemBloc>().add(
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
