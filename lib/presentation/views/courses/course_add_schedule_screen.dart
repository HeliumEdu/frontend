// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/data/models/planner/course_schedule_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_state.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/course_add_stepper.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class CourseAddScheduleProvidedScreen extends StatefulWidget {
  final int courseGroupId;
  final int courseId;
  final bool isEdit;

  const CourseAddScheduleProvidedScreen({
    super.key,
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
  });

  @override
  State<CourseAddScheduleProvidedScreen> createState() =>
      _CourseAddScheduleScreenState();
}

class _CourseAddScheduleScreenState
    extends BasePageScreenState<CourseAddScheduleProvidedScreen> {
  @override
  String get screenTitle => widget.isEdit ? 'Edit Class' : 'Add Class';

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function get saveAction => _onSubmit;

  // State
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
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CoursesError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is CourseScheduleFetched) {
            _populateInitialStateData(state);
          } else if (state is CourseScheduleUpdated) {
            showSnackBar(context, 'Class schedule saved');

            if (state.advanceNavOnSuccess) {
              context.pushReplacement(
                AppRoutes.courseAddCategoriesScreen,
                extra: CourseAddArgs(
                  courseBloc: context.read<CourseBloc>(),
                  courseGroupId: widget.courseGroupId,
                  courseId: widget.courseId,
                  isEdit: widget.isEdit,
                ),
              );
            }
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return CourseStepper(
      selectedIndex: 1,
      courseGroupId: widget.courseGroupId,
      courseId: widget.courseId,
      isEdit: widget.isEdit,
      onStep: () => _onSubmit(advanceNavOnSuccess: false),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.shadow.withValues(alpha: 0.05),
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
                                _startTimes[0] = _singleStartTime;
                                _endTimes[0] = _singleEndTime;
                                _startTimes[1] = _singleStartTime;
                                _endTimes[1] = _singleEndTime;
                                _startTimes[2] = _singleStartTime;
                                _endTimes[2] = _singleEndTime;
                                _startTimes[3] = _singleStartTime;
                                _endTimes[3] = _singleEndTime;
                                _startTimes[4] = _singleStartTime;
                                _endTimes[4] = _singleEndTime;
                                _startTimes[5] = _singleStartTime;
                                _endTimes[5] = _singleEndTime;
                                _startTimes[6] = _singleStartTime;
                                _endTimes[6] = _singleEndTime;
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
                        value: CalendarConstants.dayNamesAbbrev.indexOf(day),
                        label: Text(day),
                      ),
                    )
                    .toList(),
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    AppStyles.buttonText(context),
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
                        color: context.colorScheme.shadow.withValues(
                          alpha: 0.04,
                        ),
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
                        style: AppStyles.formLabel(context).copyWith(
                          color: context.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Start Time Picker
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(dayIndex, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: scaffoldBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: context.colorScheme.outline
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startTimes[dayIndex] != null
                                          ? HeliumTime.formatForDisplay(
                                              _startTimes[dayIndex]!,
                                            )
                                          : '',
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
                          ),
                          const SizedBox(width: 12),
                          // End Time Picker
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(dayIndex, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: scaffoldBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: context.colorScheme.outline
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _endTimes[dayIndex] != null
                                          ? HeliumTime.formatForDisplay(
                                              _endTimes[dayIndex]!,
                                            )
                                          : '',
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
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Text('Class Time', style: AppStyles.featureText(context)),
              const SizedBox(height: 16),
              Container(
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
                    // Start Time
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectSingleTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scaffoldBgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                HeliumTime.formatForDisplay(_singleStartTime),
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
                    ),
                    const SizedBox(width: 12),
                    // End Time
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectSingleTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scaffoldBgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                HeliumTime.formatForDisplay(_singleEndTime),
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
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _populateInitialStateData(CourseScheduleFetched state) {
    final daysOfWeek = state.schedule.daysOfWeek;
    final Set<int> activeDays = {};

    for (int i = 0; i < daysOfWeek.length; i++) {
      if (daysOfWeek[i] == '1') {
        activeDays.add(i);
      }
    }

    final sunStart = HeliumTime.parse(state.schedule.sunStartTime);
    final sunEnd = HeliumTime.parse(state.schedule.sunEndTime);
    final monStart = HeliumTime.parse(state.schedule.monStartTime);
    final monEnd = HeliumTime.parse(state.schedule.monEndTime);
    final tueStart = HeliumTime.parse(state.schedule.tueStartTime);
    final tueEnd = HeliumTime.parse(state.schedule.tueEndTime);
    final wedStart = HeliumTime.parse(state.schedule.wedStartTime);
    final wedEnd = HeliumTime.parse(state.schedule.wedEndTime);
    final thuStart = HeliumTime.parse(state.schedule.thuStartTime);
    final thuEnd = HeliumTime.parse(state.schedule.thuEndTime);
    final friStart = HeliumTime.parse(state.schedule.friStartTime);
    final friEnd = HeliumTime.parse(state.schedule.friEndTime);
    final satStart = HeliumTime.parse(state.schedule.satStartTime);
    final satEnd = HeliumTime.parse(state.schedule.satEndTime);

    setState(() {
      _scheduleId = state.schedule.id;

      _selectedDays = activeDays;
      _singleStartTime = sunStart ?? _singleStartTime;
      _singleEndTime = sunEnd ?? _singleEndTime;
      _variesByDay = !state.schedule.allDaysSameTime();
      if (_variesByDay) {
        if (activeDays.contains(0)) {
          _startTimes[0] = sunStart;
          _endTimes[0] = sunEnd;
        }
        if (activeDays.contains(1) && monStart != null && monEnd != null) {
          _startTimes[1] = monStart;
          _endTimes[1] = monEnd;
        }
        if (activeDays.contains(2) && tueStart != null && tueEnd != null) {
          _startTimes[2] = tueStart;
          _endTimes[2] = tueEnd;
        }
        if (activeDays.contains(3) && wedStart != null && wedEnd != null) {
          _startTimes[3] = wedStart;
          _endTimes[3] = wedEnd;
        }
        if (activeDays.contains(4) && thuStart != null && thuEnd != null) {
          _startTimes[4] = thuStart;
          _endTimes[4] = thuEnd;
        }
        if (activeDays.contains(5) && friStart != null && friEnd != null) {
          _startTimes[5] = friStart;
          _endTimes[5] = friEnd;
        }
        if (activeDays.contains(6) && satStart != null && satEnd != null) {
          _startTimes[6] = satStart;
          _endTimes[6] = satEnd;
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

  bool _onSubmit({bool advanceNavOnSuccess = true}) {
    // TODO: High Value, Low Effort: only submit if actual changes are made

    if (_variesByDay) {
      if (_selectedDays.isEmpty) {
        showSnackBar(context, 'Select at least one day', isError: true);
        return false;
      }

      for (int dayIndex in _selectedDays) {
        if (_startTimes[dayIndex] == null || _endTimes[dayIndex] == null) {
          showSnackBar(
            context,
            'Set times for all selected days',
            isError: true,
          );
          return false;
        }

        if (_startTimes[dayIndex]!.isAfter(_endTimes[dayIndex]!)) {
          showSnackBar(
            context,
            '"End Time" for "${CalendarConstants.dayNamesAbbrev[dayIndex]}" must come after "Start Time"',
            isError: true,
          );
          return false;
        }
      }
    } else {
      if (_singleStartTime.isAfter(_singleEndTime)) {
        showSnackBar(
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

    // Default time for days that aren't used
    const String defaultTime = '00:00:00';

    String sunStart, sunEnd;
    String monStart, monEnd;
    String tueStart, tueEnd;
    String wedStart, wedEnd;
    String thuStart, thuEnd;
    String friStart, friEnd;
    String satStart, satEnd;

    if (_variesByDay) {
      sunStart = _selectedDays.contains(0) && _startTimes[0] != null
          ? HeliumTime.formatForApi(_startTimes[0]!)
          : defaultTime;
      sunEnd = _selectedDays.contains(0) && _endTimes[0] != null
          ? HeliumTime.formatForApi(_endTimes[0]!)
          : defaultTime;

      monStart = _selectedDays.contains(1) && _startTimes[1] != null
          ? HeliumTime.formatForApi(_startTimes[1]!)
          : defaultTime;
      monEnd = _selectedDays.contains(1) && _endTimes[1] != null
          ? HeliumTime.formatForApi(_endTimes[1]!)
          : defaultTime;

      tueStart = _selectedDays.contains(2) && _startTimes[2] != null
          ? HeliumTime.formatForApi(_startTimes[2]!)
          : defaultTime;
      tueEnd = _selectedDays.contains(2) && _endTimes[2] != null
          ? HeliumTime.formatForApi(_endTimes[2]!)
          : defaultTime;

      wedStart = _selectedDays.contains(3) && _startTimes[3] != null
          ? HeliumTime.formatForApi(_startTimes[3]!)
          : defaultTime;
      wedEnd = _selectedDays.contains(3) && _endTimes[3] != null
          ? HeliumTime.formatForApi(_endTimes[3]!)
          : defaultTime;

      thuStart = _selectedDays.contains(4) && _startTimes[4] != null
          ? HeliumTime.formatForApi(_startTimes[4]!)
          : defaultTime;
      thuEnd = _selectedDays.contains(4) && _endTimes[4] != null
          ? HeliumTime.formatForApi(_endTimes[4]!)
          : defaultTime;

      friStart = _selectedDays.contains(5) && _startTimes[5] != null
          ? HeliumTime.formatForApi(_startTimes[5]!)
          : defaultTime;
      friEnd = _selectedDays.contains(5) && _endTimes[5] != null
          ? HeliumTime.formatForApi(_endTimes[5]!)
          : defaultTime;

      satStart = _selectedDays.contains(6) && _startTimes[6] != null
          ? HeliumTime.formatForApi(_startTimes[6]!)
          : defaultTime;
      satEnd = _selectedDays.contains(6) && _endTimes[6] != null
          ? HeliumTime.formatForApi(_endTimes[6]!)
          : defaultTime;
    } else {
      // Same time for all days
      final startTimeStr = HeliumTime.formatForApi(_singleStartTime);
      final endTimeStr = HeliumTime.formatForApi(_singleEndTime);

      sunStart = startTimeStr;
      sunEnd = endTimeStr;
      monStart = startTimeStr;
      monEnd = endTimeStr;
      tueStart = startTimeStr;
      tueEnd = endTimeStr;
      wedStart = startTimeStr;
      wedEnd = endTimeStr;
      thuStart = startTimeStr;
      thuEnd = endTimeStr;
      friStart = startTimeStr;
      friEnd = endTimeStr;
      satStart = startTimeStr;
      satEnd = endTimeStr;
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
        advanceNavOnSuccess: advanceNavOnSuccess,
      ),
    );

    return true;
  }
}
