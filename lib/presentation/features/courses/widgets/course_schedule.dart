// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/request/course_schedule_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class CourseSchedule extends StatefulWidget {
  final int courseGroupId;
  final int courseId;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel? userSettings;

  const CourseSchedule({
    super.key,
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
    required this.isNew,
    this.userSettings,
  });

  @override
  State<CourseSchedule> createState() => CourseScheduleState();
}

class CourseScheduleState extends State<CourseSchedule> {
  // State
  bool isLoading = true;
  bool isSubmitting = false;
  int? _scheduleId;
  bool _variesByDay = false;
  Set<int> _selectedDays = {};
  TimeOfDay _singleStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _singleEndTime = const TimeOfDay(hour: 12, minute: 50);
  final Map<int, TimeOfDay?> _startTimes = {};
  final Map<int, TimeOfDay?> _endTimes = {};

  @override
  void initState() {
    super.initState();

    context.read<CourseBloc>().add(
      FetchCourseScheduleEvent(
        origin: EventOrigin.subScreen,
        courseGroupId: widget.courseGroupId,
        courseId: widget.courseId,
      ),
    );
  }

  Future<void> _selectTime(int dayIndex, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTimes[dayIndex] ?? _singleStartTime)
          : (_endTimes[dayIndex] ?? _singleEndTime),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTimes[dayIndex] = pickedTime;
        } else {
          _endTimes[dayIndex] = pickedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Navigation and save success are handled by the parent screen's buildListeners().
    // This widget only handles data fetching.
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseScheduleFetched) {
          _populateInitialStateData(state);
        }

        if (state is! CoursesLoading) {
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

    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule', style: AppStyles.featureText(context)),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colorScheme.shadow.withValues(
                          alpha: 0.05,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text(
                                'Varies by day',
                                style: AppStyles.formLabel(context),
                              ),
                              value: _variesByDay,
                              onChanged: (value) {
                                setState(() {
                                  _variesByDay = value!;
                                  if (_variesByDay) {
                                    for (int i = 0; i < 7; i++) {
                                      _startTimes[i] = _singleStartTime;
                                      _endTimes[i] = _singleEndTime;
                                    }
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                Text('Class Days', style: AppStyles.featureText(context)),
                const SizedBox(height: 16),
                Center(
                  child: SegmentedButton<int>(
                    segments: CalendarConstants.dayNamesAbbrev
                        .map(
                          (day) => ButtonSegment<int>(
                            value: CalendarConstants.dayNamesAbbrev.indexOf(
                              day,
                            ),
                            label: Text(day),
                          ),
                        )
                        .toList(),
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        AppStyles.buttonText(context).copyWith(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 12,
                            desktop: 13,
                          ),
                          color: context.colorScheme.onPrimaryFixed,
                        ),
                      ),
                    ),
                    selected: _selectedDays,
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _selectedDays.clear();
                        _selectedDays.addAll(newSelection);
                      });
                    },
                    emptySelectionAllowed: true,
                    multiSelectionEnabled: true,
                    showSelectedIcon: false,
                  ),
                ),
                const SizedBox(height: 25),
                if (_variesByDay) ...[
                  Text('Class Times', style: AppStyles.featureText(context)),
                  const SizedBox(height: 16),
                  ..._selectedDays.map((dayIndex) {
                    return _buildDayTimeContainer(
                      context,
                      dayIndex,
                      scaffoldBgColor,
                    );
                  }),
                ] else ...[
                  Text('Class Time', style: AppStyles.featureText(context)),
                  const SizedBox(height: 16),
                  _buildSingleTimeContainer(context, scaffoldBgColor),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayTimeContainer(
    BuildContext context,
    int dayIndex,
    Color bgColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CalendarConstants.dayNames[dayIndex],
            style: AppStyles.formLabel(
              context,
            ).copyWith(color: context.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(dayIndex, true),
                  child: _buildTimeField(
                    context,
                    bgColor,
                    _startTimes[dayIndex] != null
                        ? HeliumTime.format(_startTimes[dayIndex]!)
                        : '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(dayIndex, false),
                  child: _buildTimeField(
                    context,
                    bgColor,
                    _endTimes[dayIndex] != null
                        ? HeliumTime.format(_endTimes[dayIndex]!)
                        : '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTimeContainer(BuildContext context, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectSingleTime(true),
              child: _buildTimeField(
                context,
                bgColor,
                HeliumTime.format(_singleStartTime),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectSingleTime(false),
              child: _buildTimeField(
                context,
                bgColor,
                HeliumTime.format(_singleEndTime),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(BuildContext context, Color bgColor, String timeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(timeText, style: AppStyles.formText(context)),
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
    );
  }

  void _populateInitialStateData(CourseScheduleFetched state) {
    final schedule = state.schedule;
    final activeDays = schedule.getActiveDayIndices();

    setState(() {
      _scheduleId = schedule.id;
      _selectedDays = activeDays;
      _singleStartTime = schedule.sunStartTime;
      _singleEndTime = schedule.sunEndTime;
      _variesByDay = !schedule.allDaysSameTime();

      if (_variesByDay) {
        for (final dayIndex in activeDays) {
          _startTimes[dayIndex] = schedule.getStartTimeForDayIndex(dayIndex);
          _endTimes[dayIndex] = schedule.getEndTimeForDayIndex(dayIndex);
        }
      }

      isLoading = false;
    });
  }

  Future<void> _selectSingleTime(bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _singleStartTime : _singleEndTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _singleStartTime = pickedTime;
        } else {
          _singleEndTime = pickedTime;
        }
      });
    }
  }

  String _generateDaysOfWeek() {
    final List<String> daysString = ['0', '0', '0', '0', '0', '0', '0'];
    for (int dayIndex in _selectedDays) {
      daysString[dayIndex] = '1';
    }
    return daysString.join('');
  }

  /// Submit the form. Called by parent screen when header save is pressed.
  bool onSubmit() {
    if (isLoading || isSubmitting) return false;
    if (_scheduleId == null) {
      return false;
    }

    if (_variesByDay) {
      if (_selectedDays.isEmpty) {
        SnackBarHelper.show(context, 'Select at least one day', isError: true);
        return false;
      }

      for (int dayIndex in _selectedDays) {
        if (_startTimes[dayIndex] == null || _endTimes[dayIndex] == null) {
          SnackBarHelper.show(
            context,
            'Set times for all selected days',
            isError: true,
          );
          return false;
        }

        if (_startTimes[dayIndex]!.isAfter(_endTimes[dayIndex]!)) {
          SnackBarHelper.show(
            context,
            '"End Time" for "${CalendarConstants.dayNamesAbbrev[dayIndex]}" must come after "Start Time"',
            isError: true,
          );
          return false;
        }
      }
    } else {
      if (_singleStartTime.isAfter(_singleEndTime)) {
        SnackBarHelper.show(
          context,
          '"End Time" must come after "Start Time"',
          isError: true,
        );
        return false;
      }
    }

    setState(() {
      isSubmitting = true;
    });

    final String daysOfWeek = _generateDaysOfWeek();
    const TimeOfDay defaultTime = TimeOfDay(hour: 0, minute: 0);

    TimeOfDay sunStart, sunEnd;
    TimeOfDay monStart, monEnd;
    TimeOfDay tueStart, tueEnd;
    TimeOfDay wedStart, wedEnd;
    TimeOfDay thuStart, thuEnd;
    TimeOfDay friStart, friEnd;
    TimeOfDay satStart, satEnd;

    if (_variesByDay) {
      sunStart = _selectedDays.contains(0) && _startTimes[0] != null
          ? _startTimes[0]!
          : defaultTime;
      sunEnd = _selectedDays.contains(0) && _endTimes[0] != null
          ? _endTimes[0]!
          : defaultTime;
      monStart = _selectedDays.contains(1) && _startTimes[1] != null
          ? _startTimes[1]!
          : defaultTime;
      monEnd = _selectedDays.contains(1) && _endTimes[1] != null
          ? _endTimes[1]!
          : defaultTime;
      tueStart = _selectedDays.contains(2) && _startTimes[2] != null
          ? _startTimes[2]!
          : defaultTime;
      tueEnd = _selectedDays.contains(2) && _endTimes[2] != null
          ? _endTimes[2]!
          : defaultTime;
      wedStart = _selectedDays.contains(3) && _startTimes[3] != null
          ? _startTimes[3]!
          : defaultTime;
      wedEnd = _selectedDays.contains(3) && _endTimes[3] != null
          ? _endTimes[3]!
          : defaultTime;
      thuStart = _selectedDays.contains(4) && _startTimes[4] != null
          ? _startTimes[4]!
          : defaultTime;
      thuEnd = _selectedDays.contains(4) && _endTimes[4] != null
          ? _endTimes[4]!
          : defaultTime;
      friStart = _selectedDays.contains(5) && _startTimes[5] != null
          ? _startTimes[5]!
          : defaultTime;
      friEnd = _selectedDays.contains(5) && _endTimes[5] != null
          ? _endTimes[5]!
          : defaultTime;
      satStart = _selectedDays.contains(6) && _startTimes[6] != null
          ? _startTimes[6]!
          : defaultTime;
      satEnd = _selectedDays.contains(6) && _endTimes[6] != null
          ? _endTimes[6]!
          : defaultTime;
    } else {
      sunStart = _singleStartTime;
      sunEnd = _singleEndTime;
      monStart = _singleStartTime;
      monEnd = _singleEndTime;
      tueStart = _singleStartTime;
      tueEnd = _singleEndTime;
      wedStart = _singleStartTime;
      wedEnd = _singleEndTime;
      thuStart = _singleStartTime;
      thuEnd = _singleEndTime;
      friStart = _singleStartTime;
      friEnd = _singleEndTime;
      satStart = _singleStartTime;
      satEnd = _singleEndTime;
    }

    final request = CourseScheduleRequestModel(
      daysOfWeek: daysOfWeek,
      sunStartTime: sunStart,
      sunEndTime: sunEnd,
      monStartTime: monStart,
      monEndTime: monEnd,
      tueStartTime: tueStart,
      tueEndTime: tueEnd,
      wedStartTime: wedStart,
      wedEndTime: wedEnd,
      thuStartTime: thuStart,
      thuEndTime: thuEnd,
      friStartTime: friStart,
      friEndTime: friEnd,
      satStartTime: satStart,
      satEndTime: satEnd,
    );

    context.read<CourseBloc>().add(
      UpdateCourseScheduleEvent(
        origin: EventOrigin.subScreen,
        courseGroupId: widget.courseGroupId,
        courseId: widget.courseId,
        scheduleId: _scheduleId!,
        request: request,
      ),
    );

    return true;
  }
}
