// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/course_schedule_cycle_slot_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/request/course_schedule_request_model.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/courses/constants/schedule_constants.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/components/helium_picker_field.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/feedback/discard_changes_scope.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

Future<void> showScheduleEditor({
  required BuildContext parentContext,
  required int courseGroupId,
  required int courseId,
  DateTime? courseStartDate,
  DateTime? courseEndDate,
  CourseScheduleModel? schedule,
}) {
  final courseBloc = parentContext.read<CourseBloc>();

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<CourseBloc>.value(
        value: courseBloc,
        child: ScheduleEditorScreen(
          courseGroupId: courseGroupId,
          courseId: courseId,
          courseStartDate: courseStartDate,
          courseEndDate: courseEndDate,
          schedule: schedule,
        ),
      );
    },
  );
}

class ScheduleEditorScreen extends StatefulWidget {
  final int courseGroupId;
  final int courseId;
  final DateTime? courseStartDate;
  final DateTime? courseEndDate;
  final CourseScheduleModel? schedule;

  const ScheduleEditorScreen({
    super.key,
    required this.courseGroupId,
    required this.courseId,
    this.courseStartDate,
    this.courseEndDate,
    this.schedule,
  });

  bool get isEdit => schedule != null;

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends BaseDialogState<ScheduleEditorScreen> {
  final BasicFormController _formController = BasicFormController();

  bool _variesByDay = false;
  Set<int> _selectedDays = {};
  TimeOfDay _singleStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _singleEndTime = const TimeOfDay(hour: 12, minute: 50);
  final Map<int, TimeOfDay?> _startTimes = {};
  final Map<int, TimeOfDay?> _endTimes = {};

  bool _overrideDates = false;
  DateTime? _startDate;
  DateTime? _endDate;

  static const TimeOfDay _defaultCycleStart = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay _defaultCycleEnd = TimeOfDay(hour: 9, minute: 50);

  bool _isRotating = false;
  int _template = ScheduleTemplate.abDay;
  bool _customIsWeekBased = false;
  final TextEditingController _cycleLengthController =
      TextEditingController(text: '6');
  final TextEditingController _weekIntervalController =
      TextEditingController(text: '2');
  int _weekOffset = 0;
  DateTime? _anchorDate;
  final Set<int> _cycleMeets = {1};
  final Map<int, TimeOfDay> _cycleStartTimes = {};
  final Map<int, TimeOfDay> _cycleEndTimes = {};

  int get _effectiveCycleLength {
    if (ScheduleTemplate.isDayCyclePreset(_template)) {
      return ScheduleTemplate.presetCycleLength[_template]!;
    }
    return (int.tryParse(_cycleLengthController.text) ?? 2)
        .clamp(2, ScheduleTemplate.maxCycleLength);
  }

  int get _effectiveWeekInterval {
    if (_template == ScheduleTemplate.weekAb) return 2;
    return (int.tryParse(_weekIntervalController.text) ?? 2)
        .clamp(2, ScheduleTemplate.maxWeekInterval);
  }

  bool get _isWeekBased =>
      _isRotating &&
      (_template == ScheduleTemplate.weekAb ||
          (_template == ScheduleTemplate.custom && _customIsWeekBased));

  bool get _isDayCycle => _isRotating && !_isWeekBased;

  @override
  String get dialogTitle => 'Schedule';

  @override
  BasicFormController get formController => _formController;

  @override
  Widget buildDialogHeader() {
    final secondary = context.colorScheme.secondary;
    return Column(
      children: [
        Row(
          children: [
            Semantics(
              label: 'Close',
              button: true,
              child: IconButton(
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: isSubmitting ? null : _handleClose,
                icon: Icon(
                  Icons.close,
                  color: isSubmitting
                      ? secondary.withValues(alpha: 0.3)
                      : secondary,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(dialogTitle, style: AppStyles.pageTitle(context)),
              ),
            ),
            Semantics(
              label: 'Learn more',
              button: true,
              child: IconButton(
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    UrlHelpers.launchWebUrl(AppConstants.supportSchedulesUrl),
                tooltip: 'Learn more',
                icon: Icon(
                  Icons.menu_book_outlined,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
            Semantics(
              label: 'Save',
              button: true,
              child: IconButton(
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: isSubmitting ? null : handleSubmit,
                icon: isSubmitting
                    ? const LoadingIndicator(
                        size: 20,
                        expanded: false,
                        strokeWidth: 2.5,
                      )
                    : Icon(Icons.check, color: context.colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Actions live in the fixed header, not the base dialog's scrollable body.
  @override
  Widget buildButtonArea() => const SizedBox.shrink();

  Future<void> _handleClose() async {
    if (!_formController.isUserDirty) {
      Navigator.of(context).pop();
      return;
    }
    final shouldDiscard = await confirmDiscardChanges(context);
    if (shouldDiscard && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    if (schedule != null) {
      _populateFrom(schedule);
    }
    if (_selectedDays.isEmpty) {
      // A schedule needs at least one day; default to Mon/Wed/Fri.
      _selectedDays = {1, 3, 5};
    }
    _anchorDate ??= widget.courseStartDate;
  }

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _weekIntervalController.dispose();
    super.dispose();
  }

  void _populateFrom(CourseScheduleModel schedule) {
    _selectedDays = schedule.getActiveDayIndices();
    _variesByDay = !schedule.allDaysSameTime();

    _singleStartTime = schedule.representativeStartTime ?? _singleStartTime;
    _singleEndTime = schedule.representativeEndTime ?? _singleEndTime;

    if (_variesByDay) {
      for (final dayIndex in _selectedDays) {
        _startTimes[dayIndex] = schedule.getStartTimeForDayIndex(dayIndex);
        _endTimes[dayIndex] = schedule.getEndTimeForDayIndex(dayIndex);
      }
    }

    if (schedule.startDate != null || schedule.endDate != null) {
      _overrideDates = true;
      _startDate = schedule.startDate ?? widget.courseStartDate;
      _endDate = schedule.endDate ?? widget.courseEndDate;
    }

    if (schedule.cycleLength != null) {
      _isRotating = true;
      _template = schedule.template ?? ScheduleTemplate.custom;
      _cycleLengthController.text = schedule.cycleLength.toString();
      _anchorDate = schedule.anchorDate;
      _cycleMeets.clear();
      for (final slot in schedule.cycleSlots) {
        for (final index in slot.indices) {
          _cycleMeets.add(index);
          _cycleStartTimes[index] = slot.startTime;
          _cycleEndTimes[index] = slot.endTime;
        }
      }
    } else if (schedule.weekInterval != null) {
      _isRotating = true;
      _template = schedule.template ?? ScheduleTemplate.custom;
      _customIsWeekBased = true;
      _weekIntervalController.text = schedule.weekInterval.toString();
      _weekOffset = schedule.weekOffset ?? 0;
      _anchorDate = schedule.anchorDate;
    }
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CourseScheduleCreated ||
              state is CourseScheduleUpdated) {
            Navigator.of(context).pop();
          } else if (state is CoursesError &&
              state.origin == EventOrigin.dialog) {
            setState(() {
              errorMessage = state.message;
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Dialog buildDialog(BuildContext context) {
    final useCompact = Responsive.useCompactLayout(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: useCompact ? EdgeInsets.zero : const EdgeInsets.all(16),
      child: SizedBox(
        width: useCompact ? double.infinity : AppConstants.centeredDialogWidth,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Material(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formController.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDialogHeader(),
                    buildMainArea(context),
                    if (errorMessage != null) buildErrorArea(),
                    const SizedBox(height: 12),
                    buildButtonArea(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void handleSubmit() {
    super.handleSubmit();
    if (!isSubmitting) return;

    final validationError = _validate();
    if (validationError != null) {
      setState(() {
        errorMessage = validationError;
        isSubmitting = false;
      });
      return;
    }

    final request = _buildRequest();
    if (widget.isEdit) {
      context.read<CourseBloc>().add(
        UpdateCourseScheduleEvent(
          origin: EventOrigin.dialog,
          courseGroupId: widget.courseGroupId,
          courseId: widget.courseId,
          scheduleId: widget.schedule!.id,
          request: request,
        ),
      );
    } else {
      context.read<CourseBloc>().add(
        CreateCourseScheduleEvent(
          origin: EventOrigin.dialog,
          courseGroupId: widget.courseGroupId,
          courseId: widget.courseId,
          request: request,
        ),
      );
    }
  }

  /// Guards the backend's rules client-side: a rotating schedule needs an anchor
  /// date, and a day cycle needs at least one meeting day.
  String? _validate() {
    if (_isRotating && _anchorDate == null) {
      return _isWeekBased
          ? 'Select the date the first week begins.'
          : 'Select the date cycle Day 1 falls on.';
    }
    if (_isDayCycle && _cycleMeets.isEmpty) {
      return 'Select at least one meeting day for the cycle.';
    }
    return null;
  }

  @override
  Widget buildMainArea(BuildContext context) {
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModeSelector(context),
        const SizedBox(height: 25),
        if (_isRotating)
          _buildRotatingConfig(context, scaffoldBgColor)
        else
          _buildWeeklyEditor(context, scaffoldBgColor),
        _buildDatesOverride(context, scaffoldBgColor),
      ],
    );
  }

  ButtonStyle _segmentedStyle(BuildContext context) {
    return ButtonStyle(
      textStyle: WidgetStateProperty.all(AppStyles.buttonText(context)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return context.colorScheme.primary;
        }
        return Colors.transparent;
      }),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Center(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(value: false, label: Text('Weekly')),
          ButtonSegment<bool>(value: true, label: Text('Rotating')),
        ],
        style: _segmentedStyle(context),
        selected: {_isRotating},
        onSelectionChanged: (selection) {
          // Switching mode isn't itself a change, so it doesn't mark dirty.
          setState(() => _isRotating = selection.first);
        },
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildWeeklyEditor(BuildContext context, Color scaffoldBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Class Days', style: AppStyles.featureText(context)),
        const SizedBox(height: 16),
        Center(child: _buildDaySelector(context)),
        if (_selectedDays.isNotEmpty) ...[
          const SizedBox(height: 25),
          Text(
            _variesByDay ? 'Class Times' : 'Class Time',
            style: AppStyles.featureText(context),
          ),
          const SizedBox(height: 12),
          HeliumCheckboxListTile(
            title: Text('Varies by day', style: AppStyles.formLabel(context)),
            value: _variesByDay,
            onChanged: _onVariesByDayChanged,
            controlAffinity: ListTileControlAffinity.leading,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          if (_variesByDay)
            ...(_selectedDays.toList()..sort()).map(
              (dayIndex) =>
                  _buildDayTimeContainer(context, dayIndex, scaffoldBgColor),
            )
          else
            _buildSingleTimeContainer(context, scaffoldBgColor),
        ],
      ],
    );
  }

  Widget _buildRotatingConfig(BuildContext context, Color scaffoldBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rotation', style: AppStyles.featureText(context)),
        const SizedBox(height: 12),
        DropDown<int>(
          initialValue: ScheduleTemplate.items.firstWhere(
            (item) => item.id == _template,
            orElse: () => ScheduleTemplate.items.first,
          ),
          items: ScheduleTemplate.items,
          onChanged: (item) {
            if (item == null) return;
            _formController.markChanged();
            setState(() => _template = item.id);
          },
        ),
        if (_template == ScheduleTemplate.custom) ...[
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Day cycle')),
              ButtonSegment<bool>(value: true, label: Text('Week cycle')),
            ],
            style: _segmentedStyle(context),
            selected: {_customIsWeekBased},
            onSelectionChanged: (selection) {
              _formController.markChanged();
              setState(() => _customIsWeekBased = selection.first);
            },
            showSelectedIcon: false,
          ),
        ],
        const SizedBox(height: 20),
        if (_isWeekBased)
          _buildWeekBasedConfig(context, scaffoldBgColor)
        else
          _buildDayCycleConfig(context, scaffoldBgColor),
      ],
    );
  }

  Widget _buildDayCycleConfig(BuildContext context, Color scaffoldBgColor) {
    final cycleLength = _effectiveCycleLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_template == ScheduleTemplate.custom) ...[
          SizedBox(
            width: 170,
            child: SpinnerField(
              label: 'Cycle length (days)',
              controller: _cycleLengthController,
              minValue: 2,
              maxValue: ScheduleTemplate.maxCycleLength.toDouble(),
              onChanged: (_) {
                _formController.markChanged();
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        _buildAnchorField(context, 'Cycle Day 1 falls on', scaffoldBgColor),
        const SizedBox(height: 20),
        Text('Class Days', style: AppStyles.featureText(context)),
        const SizedBox(height: 12),
        for (int day = 1; day <= cycleLength; day++)
          _buildCycleDayRow(context, day, scaffoldBgColor),
      ],
    );
  }

  Widget _cardShell({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool clip = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }

  Widget _buildCycleDayRow(BuildContext context, int day, Color bgColor) {
    final meets = _cycleMeets.contains(day);
    return _cardShell(
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The whole row toggles the day; the checkbox is display-only.
          InkWell(
            onTap: () {
              Feedback.forTap(context);
              _onCycleDayChanged(day, !meets);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IgnorePointer(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: meets,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Day $day',
                    style: AppStyles.formLabel(context)
                        .copyWith(color: context.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          if (meets)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCycleTimeField(context, bgColor, day, true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCycleTimeField(context, bgColor, day, false),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onCycleDayChanged(int day, bool meets) {
    _formController.markChanged();
    setState(() {
      if (meets) {
        _cycleMeets.add(day);
        _cycleStartTimes[day] ??= _defaultCycleStart;
        _cycleEndTimes[day] ??= _defaultCycleEnd;
      } else {
        _cycleMeets.remove(day);
      }
    });
  }

  Widget _buildCycleTimeField(
    BuildContext context,
    Color bgColor,
    int day,
    bool isStart,
  ) {
    final time = isStart
        ? (_cycleStartTimes[day] ?? _defaultCycleStart)
        : (_cycleEndTimes[day] ?? _defaultCycleEnd);
    return HeliumTimeField(
      time: time,
      backgroundColor: bgColor,
      semanticsLabel: isStart ? 'Pick start time' : 'Pick end time',
      onTap: () => _selectCycleTime(day, isStart),
    );
  }

  Future<void> _selectCycleTime(int day, bool isStart) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_cycleStartTimes[day] ?? _defaultCycleStart)
          : (_cycleEndTimes[day] ?? _defaultCycleEnd),
      initialEntryMode: Responsive.isTouchDevice(context)
          ? TimePickerEntryMode.dial
          : TimePickerEntryMode.input,
      confirmText: 'Select',
    );
    if (pickedTime != null) {
      _formController.markChanged();
      setState(() {
        if (isStart) {
          _cycleStartTimes[day] = pickedTime;
          final end = _cycleEndTimes[day];
          if (end != null) {
            _cycleEndTimes[day] =
                DateRangeEnforcer.adjustEndTime(pickedTime, end);
          }
        } else {
          _cycleEndTimes[day] = pickedTime;
          final start = _cycleStartTimes[day];
          if (start != null) {
            _cycleStartTimes[day] =
                DateRangeEnforcer.adjustStartTime(start, pickedTime);
          }
        }
      });
    }
  }

  Widget _buildWeekBasedConfig(BuildContext context, Color scaffoldBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_template == ScheduleTemplate.custom) ...[
          SizedBox(
            width: 190,
            child: SpinnerField(
              label: 'Repeats every (weeks)',
              controller: _weekIntervalController,
              minValue: 2,
              maxValue: ScheduleTemplate.maxWeekInterval.toDouble(),
              onChanged: (_) {
                _formController.markChanged();
                setState(() {
                  if (_weekOffset >= _effectiveWeekInterval) _weekOffset = 0;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        _buildWeekOffsetSelector(context),
        const SizedBox(height: 20),
        _buildAnchorField(
          context,
          'Week ${_weekOffsetLabel(0)} begins on',
          scaffoldBgColor,
        ),
        const SizedBox(height: 20),
        _buildWeeklyEditor(context, scaffoldBgColor),
      ],
    );
  }

  Widget _buildWeekOffsetSelector(BuildContext context) {
    final interval = _effectiveWeekInterval;
    final selected = _weekOffset.clamp(0, interval - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Which week', style: AppStyles.formLabel(context)),
        const SizedBox(height: 4),
        Text(
          'The week of the rotation this class meets on; it repeats every '
          '$interval weeks.',
          style: AppStyles.smallSecondaryText(context),
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < interval; i++)
                ChoiceChip(
                  label: Text('Week ${_weekOffsetLabel(i)}'),
                  selected: selected == i,
                  showCheckmark: false,
                  onSelected: (_) {
                    _formController.markChanged();
                    setState(() => _weekOffset = i);
                  },
                  selectedColor: context.colorScheme.primary,
                  backgroundColor: Colors.transparent,
                  labelStyle: AppStyles.buttonText(context).copyWith(
                    color: selected == i
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: context.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _weekOffsetLabel(int offset) {
    if (_effectiveWeekInterval == 2) {
      return offset == 0 ? 'A' : 'B';
    }
    return '${offset + 1}';
  }

  Widget _buildAnchorField(BuildContext context, String label, Color bgColor) {
    return HeliumDateField(
      label: label,
      date: _anchorDate,
      backgroundColor: bgColor,
      onTap: () => _selectAnchorDate(context),
    );
  }

  Future<void> _selectAnchorDate(BuildContext context) async {
    // The anchor is bounded by the override range when set, else the course dates.
    final windowStart =
        (_overrideDates ? _startDate : null) ?? widget.courseStartDate;
    final windowEnd =
        (_overrideDates ? _endDate : null) ?? widget.courseEndDate;

    var initial = _anchorDate ?? windowStart ?? DateTime.now();
    final firstDate = windowStart ?? DateTime(initial.year - 5);
    final lastDate = windowEnd ?? DateTime(initial.year + 5);
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      confirmText: 'Select',
    );
    if (pickedDate != null) {
      _formController.markChanged();
      setState(() => _anchorDate = pickedDate);
    }
  }

  Widget _buildDatesOverride(BuildContext context, Color scaffoldBgColor) {
    if (widget.courseStartDate == null || widget.courseEndDate == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text('Class Dates', style: AppStyles.featureText(context)),
        const SizedBox(height: 12),
        HeliumCheckboxListTile(
          title: Text('Custom range', style: AppStyles.formLabel(context)),
          value: _overrideDates,
          onChanged: _onOverrideDatesChanged,
          controlAffinity: ListTileControlAffinity.leading,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.zero,
        ),
        if (_overrideDates) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HeliumDateField(
                  label: 'From',
                  date: _startDate,
                  backgroundColor: scaffoldBgColor,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumDateField(
                  label: 'To',
                  date: _endDate,
                  backgroundColor: scaffoldBgColor,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _onVariesByDayChanged(bool? value) {
    _formController.markChanged();
    setState(() {
      _variesByDay = value!;
      if (_variesByDay) {
        for (int i = 0; i < 7; i++) {
          _startTimes[i] = _singleStartTime;
          _endTimes[i] = _singleEndTime;
        }
      } else {
        final firstDay = _selectedDays.firstOrNull;
        if (firstDay != null) {
          _singleStartTime = _startTimes[firstDay] ?? _singleStartTime;
          _singleEndTime = _endTimes[firstDay] ?? _singleEndTime;
        }
      }
    });
  }

  Widget _buildDaySelector(BuildContext context) {
    return SegmentedButton<int>(
      segments: CalendarConstants.dayNamesAbbrev
          .map(
            (day) => ButtonSegment<int>(
              value: CalendarConstants.dayNamesAbbrev.indexOf(day),
              label: Text(day),
            ),
          )
          .toList(),
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Responsive.isSlimMobile(context) ? 6 : 8),
        ),
        textStyle: WidgetStateProperty.all(
          AppStyles.buttonText(context).copyWith(
            fontSize: Responsive.getFontSize(
              context,
              slimMobile: 12,
              mobile: 13,
              desktop: 14,
            ),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return context.colorScheme.primary;
          }
          return Colors.transparent;
        }),
      ),
      selected: _selectedDays,
      onSelectionChanged: _onDaysChanged,
      emptySelectionAllowed: false,
      multiSelectionEnabled: true,
      showSelectedIcon: false,
    );
  }

  void _onDaysChanged(Set<int> newSelection) {
    _formController.markChanged();
    setState(() {
      for (final dayIndex in newSelection) {
        if (!_selectedDays.contains(dayIndex)) {
          _startTimes[dayIndex] ??= _singleStartTime;
          _endTimes[dayIndex] ??= _singleEndTime;
        }
      }
      _selectedDays
        ..clear()
        ..addAll(newSelection);
    });
  }

  Widget _buildDayTimeContainer(BuildContext context, int dayIndex, Color bgColor) {
    return _cardShell(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CalendarConstants.dayNames[dayIndex],
            style: AppStyles.formLabel(context).copyWith(color: context.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _timePickerField(context, bgColor, dayIndex, true)),
              const SizedBox(width: 12),
              Expanded(child: _timePickerField(context, bgColor, dayIndex, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTimeContainer(BuildContext context, Color bgColor) {
    return _cardShell(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: _timePickerField(context, bgColor, null, true)),
          const SizedBox(width: 12),
          Expanded(child: _timePickerField(context, bgColor, null, false)),
        ],
      ),
    );
  }

  Widget _timePickerField(BuildContext context, Color bgColor, int? dayIndex, bool isStart) {
    final TimeOfDay? time = dayIndex == null
        ? (isStart ? _singleStartTime : _singleEndTime)
        : (isStart ? _startTimes[dayIndex] : _endTimes[dayIndex]);

    return HeliumTimeField(
      time: time,
      backgroundColor: bgColor,
      semanticsLabel: isStart ? 'Pick start time' : 'Pick end time',
      onTap: () {
        if (dayIndex == null) {
          _selectSingleTime(isStart);
        } else {
          _selectTime(dayIndex, isStart);
        }
      },
    );
  }

  Future<void> _selectTime(int dayIndex, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTimes[dayIndex] ?? _singleStartTime)
          : (_endTimes[dayIndex] ?? _singleEndTime),
      initialEntryMode: Responsive.isTouchDevice(context)
          ? TimePickerEntryMode.dial
          : TimePickerEntryMode.input,
      confirmText: 'Select',
    );
    if (pickedTime != null) {
      _formController.markChanged();
      setState(() {
        if (isStartTime) {
          _startTimes[dayIndex] = pickedTime;
          if (_endTimes[dayIndex] != null) {
            _endTimes[dayIndex] =
                DateRangeEnforcer.adjustEndTime(pickedTime, _endTimes[dayIndex]!);
          }
        } else {
          _endTimes[dayIndex] = pickedTime;
          if (_startTimes[dayIndex] != null) {
            _startTimes[dayIndex] =
                DateRangeEnforcer.adjustStartTime(_startTimes[dayIndex]!, pickedTime);
          }
        }
      });
    }
  }

  Future<void> _selectSingleTime(bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _singleStartTime : _singleEndTime,
      initialEntryMode: Responsive.isTouchDevice(context)
          ? TimePickerEntryMode.dial
          : TimePickerEntryMode.input,
      confirmText: 'Select',
    );
    if (pickedTime != null) {
      _formController.markChanged();
      setState(() {
        if (isStartTime) {
          _singleStartTime = pickedTime;
          _singleEndTime = DateRangeEnforcer.adjustEndTime(pickedTime, _singleEndTime);
        } else {
          _singleEndTime = pickedTime;
          _singleStartTime = DateRangeEnforcer.adjustStartTime(_singleStartTime, pickedTime);
        }
      });
    }
  }

  String _generateDaysOfWeek() {
    final List<String> daysString = ['0', '0', '0', '0', '0', '0', '0'];
    for (final dayIndex in _selectedDays) {
      daysString[dayIndex] = '1';
    }
    return daysString.join('');
  }

  TimeOfDay _startTimeForDay(int day) {
    const TimeOfDay offDay = TimeOfDay(hour: 0, minute: 0);
    if (!_variesByDay) return _singleStartTime;
    return _selectedDays.contains(day) ? (_startTimes[day] ?? offDay) : offDay;
  }

  TimeOfDay _endTimeForDay(int day) {
    const TimeOfDay offDay = TimeOfDay(hour: 0, minute: 0);
    if (!_variesByDay) return _singleEndTime;
    return _selectedDays.contains(day) ? (_endTimes[day] ?? offDay) : offDay;
  }

  void _onOverrideDatesChanged(bool? value) {
    _formController.markChanged();
    setState(() {
      _overrideDates = value ?? false;
      if (_overrideDates) {
        _startDate ??= widget.courseStartDate;
        _endDate ??= widget.courseEndDate;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final courseStart = widget.courseStartDate;
    final courseEnd = widget.courseEndDate;
    if (courseStart == null || courseEnd == null) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? courseStart)
          : (_endDate ?? courseEnd),
      firstDate: courseStart,
      lastDate: courseEnd,
      confirmText: 'Select',
    );
    if (pickedDate != null) {
      _formController.markChanged();
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
          if (_endDate != null) {
            _endDate = DateRangeEnforcer.adjustEndDate(pickedDate, _endDate!);
          }
        } else {
          _endDate = pickedDate;
          if (_startDate != null) {
            _startDate =
                DateRangeEnforcer.adjustStartDate(_startDate!, pickedDate);
          }
        }
      });
    }
  }

  CourseScheduleRequestModel _buildRequest() {
    final startDate = _overrideDates ? _startDate : null;
    final endDate = _overrideDates ? _endDate : null;
    final isPreset = _template != ScheduleTemplate.custom;

    if (_isDayCycle) {
      // A day cycle carries no weekly days; send an empty grid so the backend
      // identifies it as a cycle, not a weekly schedule.
      return _buildRequestModel(
        emitWeekly: false,
        startDate: startDate,
        endDate: endDate,
        template: isPreset ? _template : null,
        cycleLength: isPreset ? null : _effectiveCycleLength,
        anchorDate: _anchorDate,
        cycleSlots: _buildCycleSlots(),
      );
    }

    if (_isWeekBased) {
      // Week-based reuses the weekly day/time grid, plus the offset + anchor.
      return _buildRequestModel(
        emitWeekly: true,
        startDate: startDate,
        endDate: endDate,
        template: isPreset ? _template : null,
        weekInterval: isPreset ? null : _effectiveWeekInterval,
        weekOffset: _weekOffset,
        anchorDate: _anchorDate,
      );
    }

    return _buildRequestModel(
      emitWeekly: true,
      startDate: startDate,
      endDate: endDate,
    );
  }

  CourseScheduleRequestModel _buildRequestModel({
    required bool emitWeekly,
    DateTime? startDate,
    DateTime? endDate,
    int? template,
    int? cycleLength,
    DateTime? anchorDate,
    List<CourseScheduleCycleSlotModel>? cycleSlots,
    int? weekInterval,
    int? weekOffset,
  }) {
    const off = TimeOfDay(hour: 0, minute: 0);
    TimeOfDay startFor(int day) => emitWeekly ? _startTimeForDay(day) : off;
    TimeOfDay endFor(int day) => emitWeekly ? _endTimeForDay(day) : off;

    return CourseScheduleRequestModel(
      daysOfWeek: emitWeekly ? _generateDaysOfWeek() : '0000000',
      sunStartTime: startFor(0),
      sunEndTime: endFor(0),
      monStartTime: startFor(1),
      monEndTime: endFor(1),
      tueStartTime: startFor(2),
      tueEndTime: endFor(2),
      wedStartTime: startFor(3),
      wedEndTime: endFor(3),
      thuStartTime: startFor(4),
      thuEndTime: endFor(4),
      friStartTime: startFor(5),
      friEndTime: endFor(5),
      satStartTime: startFor(6),
      satEndTime: endFor(6),
      startDate: startDate,
      endDate: endDate,
      template: template,
      cycleLength: cycleLength,
      anchorDate: anchorDate,
      cycleSlots: cycleSlots,
      weekInterval: weekInterval,
      weekOffset: weekOffset,
    );
  }

  List<CourseScheduleCycleSlotModel> _buildCycleSlots() {
    final cycleLength = _effectiveCycleLength;
    final grouped = <String, List<int>>{};
    final times = <String, ({TimeOfDay start, TimeOfDay end})>{};
    for (int day = 1; day <= cycleLength; day++) {
      if (!_cycleMeets.contains(day)) continue;
      final start = _cycleStartTimes[day] ?? _defaultCycleStart;
      final end = _cycleEndTimes[day] ?? _defaultCycleEnd;
      final key = '${start.hour}:${start.minute}-${end.hour}:${end.minute}';
      grouped.putIfAbsent(key, () => []).add(day);
      times[key] = (start: start, end: end);
    }
    return grouped.entries
        .map(
          (entry) => CourseScheduleCycleSlotModel(
            indices: entry.value,
            startTime: times[entry.key]!.start,
            endTime: times[entry.key]!.end,
          ),
        )
        .toList();
  }
}
