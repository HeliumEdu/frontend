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
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
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
import 'package:heliumapp/presentation/dialogs/select_dialog.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_stepper_container.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/calendar_item_add_stepper.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/label_and_html_editor.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:nested/nested.dart';
import 'package:timezone/standalone.dart' as tz;

final _log = Logger('presentation.views');

// TODO: Feature Parity: implement "Clone" button
// TODO: Feature Parity: implement "Delete" button

/// Shows calendar item add as a dialog on desktop, or navigates on mobile.
///
/// Pass [providers] to share Blocs from the parent screen with the calendar item
/// dialog/screen, ensuring state changes are reflected in both.
void showCalendarItemAdd(
  BuildContext context, {
  int? eventId,
  int? homeworkId,
  DateTime? initialDate,
  bool isFromMonthView = false,
  required bool isEdit,
  required bool isNew,
  int initialStep = 0,
  List<SingleChildWidget>? providers,
}) {
  if (Responsive.isMobile(context)) {
    context.push(
      AppRoutes.plannerItemAddScreen,
      extra: CalendarItemAddArgs(
        calendarItemBloc: context.read<CalendarItemBloc>(),
        eventId: eventId,
        homeworkId: homeworkId,
        isEdit: isEdit,
        isNew: isNew,
      ),
    );
  } else {
    showScreenAsDialog(
      context,
      child: CalendarItemStepperContainer(
        eventId: eventId,
        homeworkId: homeworkId,
        initialDate: initialDate,
        isFromMonthView: isFromMonthView,
        isEdit: isEdit,
        isNew: isNew,
        initialStep: initialStep,
      ),
      providers: providers,
      width: 600,
      alignment: Alignment.center,
    );
  }
}

class CalendarItemAddProvidedScreen extends StatefulWidget {
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isEdit;
  final bool isNew;
  final bool isFromMonthView;

  const CalendarItemAddProvidedScreen({
    super.key,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    required this.isEdit,
    required this.isNew,
    this.isFromMonthView = false,
  });

  @override
  State<CalendarItemAddProvidedScreen> createState() =>
      _CalendarItemAddScreenState();
}

class _CalendarItemAddScreenState
    extends BasePageScreenState<CalendarItemAddProvidedScreen> {
  @override
  String get screenTitle => isLoading
      ? ''
      : (!widget.isNew ? 'Edit ' : 'Add ') +
            (_isEvent ? 'Event' : 'Assignment');

  @override
  IconData? get icon => isLoading ? null : Icons.calendar_month;

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function get saveAction => _onSubmit;

  ValueChanged<bool>? get calendarItemToggleCallback =>
      !widget.isEdit && _courses.isNotEmpty
      ? (toEvent) {
          setState(() {
            _isEvent = toEvent;
          });
        }
      : null;

  bool get initialSelectEvent => _isEvent;

  final CalendarItemFormController _formController =
      CalendarItemFormController();

  // State
  bool _isEvent = false;
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

    context.read<CalendarItemBloc>().add(
      FetchCalendarItemScreenDataEvent(
        origin: EventOrigin.subScreen,
        eventId: widget.eventId,
        homeworkId: widget.homeworkId,
      ),
    );
  }

  @override
  void dispose() {
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CalendarItemBloc, CalendarItemState>(
        listener: (context, state) {
          if (state is CalendarItemsError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is CalendarItemScreenDataFetched) {
            _populateInitialCalendarItemStateData(state);
          } else if (state is HomeworkCreated ||
              state is HomeworkUpdated ||
              state is EventCreated ||
              state is EventUpdated) {
            state as BaseEntityState;

            showSnackBar(
              context,
              '${state.isEvent ? 'Event' : 'Assignment'} saved',
            );

            if (state.advanceNavOnSuccess) {
              if (DialogModeProvider.isDialogMode(context)) {
                // Close current dialog and reopen with new entityId
                Navigator.of(context).pop();
                showCalendarItemAdd(
                  context,
                  eventId: state.isEvent ? state.entityId : null,
                  homeworkId: !state.isEvent ? state.entityId : null,
                  isEdit: true,
                  isNew: state is HomeworkCreated || state is EventCreated,
                  initialStep: 1,
                  providers: [
                    BlocProvider<CalendarItemBloc>.value(
                      value: context.read<CalendarItemBloc>(),
                    ),
                  ],
                );
              } else {
                // Fall back to router navigation for non-dialog mode
                context.pushReplacement(
                  AppRoutes.plannerItemAddRemindersScreen,
                  extra: CalendarItemReminderArgs(
                    calendarItemBloc: context.read<CalendarItemBloc>(),
                    isEvent: state.isEvent,
                    entityId: state.entityId,
                    isEdit: true,
                    isNew: state is HomeworkCreated || state is EventCreated,
                  ),
                );
              }
            }
          }

          if (state is! CalendarItemsLoading) {
            setState(() {
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
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
                selected: {initialSelectEvent},
                onSelectionChanged: (Set<bool> selected) {
                  calendarItemToggleCallback!(selected.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        CalendarItemStepper(
          selectedIndex: 0,
          eventId: widget.eventId,
          homeworkId: widget.homeworkId,
          isEdit: widget.isEdit,
          isNew: widget.isEdit,
          onStep: () => _onSubmit(advanceNavOnSuccess: false),
        ),
      ],
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    final List<MaterialModel> filteredMaterials = _materials.where((material) {
      return material.courses.isNotEmpty &&
          material.courses.any((c) {
            return c == _formController.selectedCourse;
          });
    }).toList();

    return Expanded(
      child: SingleChildScrollView(
        child: Form(
          key: _formController.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Details', style: AppStyles.featureText(context)),
              const SizedBox(height: 14),
              LabelAndTextFormField(
                label: 'Title',
                autofocus: kIsWeb || !widget.isEdit,
                controller: _formController.titleController,
                validator: BasicFormController.validateRequiredField,
                fieldKey: _formController.getFieldKey('title'),
                onFieldSubmitted: (value) => _onSubmit(),
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
                          () =>
                              _formController.showEndDateTime = value ?? false,
                        );
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date', style: AppStyles.formLabel(context)),
                        const SizedBox(height: 9),
                        GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: context.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              color: context.colorScheme.surface,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  HeliumDateTime.formatDate(
                                    _formController.startDate,
                                  ),
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
                    ),
                  ),
                  if (_formController.showEndDateTime) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End Date', style: AppStyles.formLabel(context)),
                          const SizedBox(height: 9),
                          GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: context.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                color: context.colorScheme.surface,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    HeliumDateTime.formatDate(
                                      _formController.endDate,
                                    ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: AppStyles.formLabel(context),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectTime(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: context.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                color: context.colorScheme.surface,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    HeliumTime.format(
                                      _formController.startTime,
                                    ),
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
                      ),
                    ),
                    if (_formController.showEndDateTime) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Time',
                              style: AppStyles.formLabel(context),
                            ),
                            const SizedBox(height: 9),
                            GestureDetector(
                              onTap: () => _selectTime(context, false),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      HeliumTime.format(
                                        _formController.endTime,
                                      ),
                                      style: AppStyles.formText(context),
                                    ),
                                    Icon(
                                      Icons.access_time,
                                      color: context.colorScheme.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              if (!_isEvent) ...[
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
                            category.value?.course ==
                            _formController.selectedCourse,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                            return Chip(
                              backgroundColor: userSettings!.materialColor,
                              deleteIconColor: context.colorScheme.surface,
                              label: Text(
                                _materialTitleById(id),
                                style: AppStyles.formText(
                                  context,
                                ).copyWith(color: context.colorScheme.surface),
                              ),
                              onDeleted: () => _removeMaterial(id),
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
                                initialSelected: _formController
                                    .selectedMaterials
                                    .toSet(),
                                onConfirm: (selected) =>
                                    _updateSelectedMaterials(selected.toList()),
                              ),
                              icon: Icon(
                                Icons.add,
                                color: context.colorScheme.primary,
                              ),
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

              // TODO: Enhancement: add location field to Event's
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Priority', style: AppStyles.formLabel(context)),
                ],
              ),
              const SizedBox(height: 9),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: HeliumColors.getColorForPriority(
                    _formController.priorityValue,
                  ),
                  thumbColor: HeliumColors.getColorForPriority(
                    _formController.priorityValue,
                  ),
                  overlayColor: (HeliumColors.getColorForPriority(
                    _formController.priorityValue,
                  )).withValues(alpha: 0.2),
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

              if (!_isEvent) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(
                          'Completed',
                          style: AppStyles.formLabel(context),
                        ),
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
                  ],
                ),
              ],
              if (!_isEvent && _formController.isCompleted) ...[
                LabelAndTextFormField(
                  label: 'Grade',
                  controller: _formController.gradeController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\./]')),
                  ],
                  focusNode: _formController.gradeFocusNode,
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 14),

              LabelAndHtmlEditor(
                label: 'Notes',
                controller: _formController.detailsController,
                initialText: _formController.initialNotes,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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

      setState(() {
        _formController.titleController.text = calendarItem.title;
        _formController.isAllDay = calendarItem.allDay;
        _formController.showEndDateTime = calendarItem.showEndTime;
        _formController.priorityValue = calendarItem.priority.toDouble();
        _formController.initialNotes = calendarItem.comments;

        final startDateTime = HeliumDateTime.toLocal(
          calendarItem.start,
          userSettings!.timeZone,
        );
        _formController.startDate = startDateTime;
        if (!_formController.isAllDay) {
          _formController.startTime = TimeOfDay.fromDateTime(startDateTime);
        }

        final endDateTime = HeliumDateTime.toLocal(
          calendarItem.end,
          userSettings!.timeZone,
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
          _log.info('Category ID set: $_formController.selectedCategory');

          if (calendarItem.materials.isNotEmpty) {
            _formController.selectedMaterials = calendarItem.materials
                .where((e) {
                  return _materials.any((m) {
                    return m.id == e.id;
                  });
                })
                .map((e) => e.id)
                .toList();
            _log.info('Material IDs set: $_formController.selectedMaterials');
          } else {
            _formController.selectedMaterials = [];
            _log.info('No materials in homework data');
          }
        }
      });
    } else {
      if (widget.initialDate != null) {
        _formController.startDate = widget.initialDate!;
        _formController.endDate = widget.initialDate!;
      }

      if (!_isEvent) {
        _selectCourse(_courses.first.id);
      }

      // Override time with initialDate if provided, but only when not from
      // month view. Month view only selects a day without a specific time, so
      // we keep the course schedule time set by _selectCourse() instead.
      if (widget.initialDate != null && !widget.isFromMonthView) {
        final tzDateTime = tz.TZDateTime.from(
          widget.initialDate!,
          userSettings!.timeZone,
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
          ? (_formController.startTime)
          : (_formController.endTime),
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

  Future<void> _onSubmit({bool advanceNavOnSuccess = true}) async {
    if (_formController.validateAndScrollToError()) {
      if (_formController.endDate.isBefore(_formController.startDate)) {
        showSnackBar(
          context,
          '"End Date" must come after "Start Date"',
          isError: true,
        );

        return;
      }

      final startDateTimeUnaware = DateTime(
        _formController.startDate.year,
        _formController.startDate.month,
        _formController.startDate.day,
        _formController.isAllDay ? 0 : _formController.startTime.hour,
        _formController.isAllDay ? 0 : _formController.startTime.minute,
      );
      final endDateTimeUnaware = DateTime(
        _formController.startDate.year,
        _formController.startDate.month,
        _formController.startDate.day,
        _formController.isAllDay ? 0 : _formController.startTime.hour,
        _formController.isAllDay ? 0 : _formController.startTime.minute,
      );

      // TODO: Feature Parity: evaluate if the "add 30 minutes" logic that was on the legacy frontend is still necessary, SfCalendar might resolve this issue for us

      if (endDateTimeUnaware.isAfter(startDateTimeUnaware)) {
        showSnackBar(
          context,
          '"End Time" must come after "Start Time"',
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
        userSettings!.timeZone,
      );

      String end;
      if (_formController.showEndDateTime) {
        final endDateForApi = _formController.isAllDay
            ? _formController.endDate.add(const Duration(days: 1))
            : _formController.endDate;
        end = HeliumDateTime.formatDateAndTimeForApi(
          endDateForApi,
          _formController.isAllDay ? null : _formController.endTime,
          userSettings!.timeZone,
        );
      } else {
        if (_formController.isAllDay) {
          final endDate = _formController.startDate.add(
            const Duration(days: 1),
          );
          end = HeliumDateTime.formatDateAndTimeForApi(
            endDate,
            null,
            userSettings!.timeZone,
          );
        } else {
          end = start;
        }
      }

      final notes = await _formController.detailsController.getText();

      if (_isEvent) {
        final request = EventRequestModel(
          title: _formController.titleController.text.trim(),
          allDay: _formController.isAllDay,
          showEndTime: _formController.showEndDateTime,
          start: start,
          end: end,
          priority: _getPriorityValue(),
          comments: notes.trim().isEmpty ? '' : notes.trim(),
        );

        if (mounted) {
          if (widget.isEdit) {
            // TODO: High Value, Low Effort: only submit if actual changes are made

            context.read<CalendarItemBloc>().add(
              UpdateEventEvent(
                origin: EventOrigin.subScreen,
                id: widget.eventId!,
                request: request,
                advanceNavOnSuccess: false,
              ),
            );
          } else {
            context.read<CalendarItemBloc>().add(
              CreateEventEvent(origin: EventOrigin.subScreen, request: request),
            );
          }
        }
      } else {
        final selectedCourse = _courses.firstWhere(
          (c) => c.id == _formController.selectedCourse,
        );

        // Determine grade value: -1/100 when not completed, user input when completed
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
          comments: notes.trim().isEmpty ? '' : notes.trim(),
          currentGrade: gradeValue,
          completed: _formController.isCompleted,
          category: _formController.selectedCategory,
          materials: _formController.selectedMaterials,
          course: _formController.selectedCourse!,
        );

        if (mounted) {
          if (widget.isEdit) {
            // TODO: High Value, Low Effort: only submit if actual changes are made
            context.read<CalendarItemBloc>().add(
              UpdateHomeworkEvent(
                origin: EventOrigin.subScreen,
                courseGroupId: selectedCourse.courseGroup,
                courseId: selectedCourse.id,
                homeworkId: widget.homeworkId!,
                request: request,
                advanceNavOnSuccess: false,
              ),
            );
          } else {
            context.read<CalendarItemBloc>().add(
              CreateHomeworkEvent(
                origin: EventOrigin.subScreen,
                courseGroupId: selectedCourse.courseGroup,
                courseId: selectedCourse.id,
                request: request,
                advanceNavOnSuccess: advanceNavOnSuccess,
              ),
            );
          }
        }
      }
    } else {
      showSnackBar(
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

      // Try to match category by preferred name, otherwise fallback to first
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

      // Try to match materials by preferred names, otherwise clear
      final materialsForCourse = _materials
          .where((m) => m.courses.contains(_formController.selectedCourse))
          .toList();

      _formController.selectedMaterials = materialsForCourse
          .where((m) => _preferredMaterialNames.contains(m.title))
          .map((m) => m.id)
          .toList();

      // Only try to auto-populate dates and times for new calendar items
      if (!widget.isEdit) {
        // Use course schedule time for the selected day, fall back to noon
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
      // Update preference when user explicitly selects a category
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
}
