// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/config/app_routes.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/course_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/course_model.dart';
import 'package:heliumedu/data/models/planner/course_schedule_request_model.dart';
import 'package:heliumedu/data/repositories/course_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_bloc.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_event.dart';
import 'package:heliumedu/presentation/bloc/courseBloc/course_state.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_list.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

class AddClassesScheduleScreen extends StatefulWidget {
  final int courseId;
  final int courseGroupId;
  final bool isEdit;

  const AddClassesScheduleScreen({
    super.key,
    required this.courseId,
    required this.courseGroupId,
    this.isEdit = false,
  });

  @override
  State<AddClassesScheduleScreen> createState() =>
      _AddClassesScheduleScreenState();
}

class _AddClassesScheduleScreenState extends State<AddClassesScheduleScreen> {
  bool isSchedule = false;
  List<int> selectedDays = [];
  TimeOfDay? singleStartTime;
  TimeOfDay? singleEndTime;

  Map<int, TimeOfDay?> startTimes = {};
  Map<int, TimeOfDay?> endTimes = {};

  bool _isCreating = false;
  bool _isLoadingCourse = false;
  int? _existingScheduleId; // Store schedule ID for update
  late CourseBloc _courseBloc;

  @override
  void initState() {
    super.initState();
    _courseBloc = CourseBloc(
      courseRepository: CourseRepositoryImpl(
        remoteDataSource: CourseRemoteDataSourceImpl(dioClient: DioClient()),
      ),
    );

    // Fetch course details (including schedules) if editing
    if (widget.isEdit) {
      _courseBloc.add(
        FetchCourseByIdEvent(
          groupId: widget.courseGroupId,
          courseId: widget.courseId,
        ),
      );
    }
  }

  // Helper to parse time string (HH:MM:SS) to TimeOfDay
  TimeOfDay? _parseTime(String timeString) {
    try {
      if (timeString == '00:00:00' || timeString.isEmpty) {
        return null;
      }
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      print('Error parsing time: $e');
      return null;
    }
  }

  // Helper to pre-fill schedule form with course data
  void _prefillSchedule(CourseModel course) {
    if (course.schedules.isEmpty) {
      // No schedule yet, keep form empty
      return;
    }

    // Get the first schedule (usually only one schedule per course)
    final schedule = course.schedules.first;

    // Store schedule ID for update
    _existingScheduleId = schedule.id;

    // Parse days of week (7-digit string: Sun-Sat)
    final daysOfWeek = schedule.daysOfWeek;
    List<int> activeDays = [];

    // Check which days are active
    // API format: Sun(0), Mon(1), Tue(2), Wed(3), Thu(4), Fri(5), Sat(6)
    // Our format: Mon(0), Tue(1), Wed(2), Thu(3), Fri(4), Sat(5), Sun(6)
    for (int i = 0; i < daysOfWeek.length; i++) {
      if (daysOfWeek[i] == '1') {
        if (i == 0) {
          // Sunday in API → index 6 in our list
          activeDays.add(6);
        } else {
          // Mon-Sat in API (1-6) → index 0-5 in our list
          activeDays.add(i - 1);
        }
      }
    }

    // Parse times
    final sunStart = _parseTime(schedule.sunStartTime);
    final sunEnd = _parseTime(schedule.sunEndTime);
    final monStart = _parseTime(schedule.monStartTime);
    final monEnd = _parseTime(schedule.monEndTime);
    final tueStart = _parseTime(schedule.tueStartTime);
    final tueEnd = _parseTime(schedule.tueEndTime);
    final wedStart = _parseTime(schedule.wedStartTime);
    final wedEnd = _parseTime(schedule.wedEndTime);
    final thuStart = _parseTime(schedule.thuStartTime);
    final thuEnd = _parseTime(schedule.thuEndTime);
    final friStart = _parseTime(schedule.friStartTime);
    final friEnd = _parseTime(schedule.friEndTime);
    final satStart = _parseTime(schedule.satStartTime);
    final satEnd = _parseTime(schedule.satEndTime);

    // Check if all active days have the same time (Same Time mode)
    bool allSameTime = true;
    TimeOfDay? commonStartTime;
    TimeOfDay? commonEndTime;

    if (activeDays.isNotEmpty) {
      // Get first active day's time
      if (activeDays.contains(6)) {
        // Sunday
        commonStartTime = sunStart;
        commonEndTime = sunEnd;
      } else if (activeDays.contains(0)) {
        // Monday
        commonStartTime = monStart;
        commonEndTime = monEnd;
      } else if (activeDays.contains(1)) {
        // Tuesday
        commonStartTime = tueStart;
        commonEndTime = tueEnd;
      } else if (activeDays.contains(2)) {
        // Wednesday
        commonStartTime = wedStart;
        commonEndTime = wedEnd;
      } else if (activeDays.contains(3)) {
        // Thursday
        commonStartTime = thuStart;
        commonEndTime = thuEnd;
      } else if (activeDays.contains(4)) {
        // Friday
        commonStartTime = friStart;
        commonEndTime = friEnd;
      } else if (activeDays.contains(5)) {
        // Saturday
        commonStartTime = satStart;
        commonEndTime = satEnd;
      }

      // Check if all active days have the same time
      for (int dayIndex in activeDays) {
        TimeOfDay? dayStart;
        TimeOfDay? dayEnd;

        if (dayIndex == 6) {
          // Sunday
          dayStart = sunStart;
          dayEnd = sunEnd;
        } else if (dayIndex == 0) {
          // Monday
          dayStart = monStart;
          dayEnd = monEnd;
        } else if (dayIndex == 1) {
          // Tuesday
          dayStart = tueStart;
          dayEnd = tueEnd;
        } else if (dayIndex == 2) {
          // Wednesday
          dayStart = wedStart;
          dayEnd = wedEnd;
        } else if (dayIndex == 3) {
          // Thursday
          dayStart = thuStart;
          dayEnd = thuEnd;
        } else if (dayIndex == 4) {
          // Friday
          dayStart = friStart;
          dayEnd = friEnd;
        } else if (dayIndex == 5) {
          // Saturday
          dayStart = satStart;
          dayEnd = satEnd;
        }

        if (dayStart?.hour != commonStartTime?.hour ||
            dayStart?.minute != commonStartTime?.minute ||
            dayEnd?.hour != commonEndTime?.hour ||
            dayEnd?.minute != commonEndTime?.minute) {
          allSameTime = false;
          break;
        }
      }
    }

    setState(() {
      if (allSameTime && commonStartTime != null && commonEndTime != null) {
        // Use "Same Time" mode
        isSchedule = false;
        singleStartTime = commonStartTime;
        singleEndTime = commonEndTime;
      } else {
        // Use "Varies by Day" mode
        isSchedule = true;
        selectedDays = activeDays;

        // Set individual times for each day
        if (activeDays.contains(6) && sunStart != null && sunEnd != null) {
          startTimes[6] = sunStart;
          endTimes[6] = sunEnd;
        }
        if (activeDays.contains(0) && monStart != null && monEnd != null) {
          startTimes[0] = monStart;
          endTimes[0] = monEnd;
        }
        if (activeDays.contains(1) && tueStart != null && tueEnd != null) {
          startTimes[1] = tueStart;
          endTimes[1] = tueEnd;
        }
        if (activeDays.contains(2) && wedStart != null && wedEnd != null) {
          startTimes[2] = wedStart;
          endTimes[2] = wedEnd;
        }
        if (activeDays.contains(3) && thuStart != null && thuEnd != null) {
          startTimes[3] = thuStart;
          endTimes[3] = thuEnd;
        }
        if (activeDays.contains(4) && friStart != null && friEnd != null) {
          startTimes[4] = friStart;
          endTimes[4] = friEnd;
        }
        if (activeDays.contains(5) && satStart != null && satEnd != null) {
          startTimes[5] = satStart;
          endTimes[5] = satEnd;
        }
      }
    });
  }

  @override
  void dispose() {
    _courseBloc.close();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(int dayIndex, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (startTimes[dayIndex] ?? TimeOfDay.now())
          : (endTimes[dayIndex] ?? TimeOfDay.now()),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          startTimes[dayIndex] = pickedTime;
        } else {
          endTimes[dayIndex] = pickedTime;
        }
      });
    }
  }

  Future<void> _selectSingleTime(bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          singleStartTime = pickedTime;
        } else {
          singleEndTime = pickedTime;
        }
      });
    }
  }

  // Format TimeOfDay to HH:MM:SS format for API
  String _formatTimeForAPI(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  // Generate days_of_week string (7 digits: Sun-Sat, 1 = active, 0 = inactive)
  String _generateDaysOfWeek() {
    if (!isSchedule || selectedDays.isEmpty) {
      // No specific days selected, all days are active
      return '1111111';
    }

    // Days in API: Sun(0), Mon(1), Tue(2), Wed(3), Thu(4), Fri(5), Sat(6)
    // selectedDays uses: Mon(0), Tue(1), Wed(2), Thu(3), Fri(4), Sat(5), Sun(6)
    List<String> daysString = ['0', '0', '0', '0', '0', '0', '0'];

    for (int dayIndex in selectedDays) {
      // Convert from Mon-first to Sun-first
      if (dayIndex == 6) {
        // Sunday in our list → index 0 in API
        daysString[0] = '1';
      } else {
        // Mon-Sat in our list → index 1-6 in API
        daysString[dayIndex + 1] = '1';
      }
    }

    return daysString.join('');
  }

  void _validateAndCreateSchedule() {
    // Validation
    if (isSchedule) {
      // Varies by day - need at least one day selected
      if (selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select at least one day',
              style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
            ),
            backgroundColor: redColor,
          ),
        );
        return;
      }

      // Check if all selected days have start and end times
      for (int dayIndex in selectedDays) {
        if (startTimes[dayIndex] == null || endTimes[dayIndex] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please set times for all selected days',
                style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
              ),
              backgroundColor: redColor,
            ),
          );
          return;
        }
      }
    } else {
      // Same time for all days
      if (singleStartTime == null || singleEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please set start and end times',
              style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
            ),
            backgroundColor: redColor,
          ),
        );
        return;
      }
    }

    // Build request
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

    if (isSchedule) {
      // Varies by day - set times based on selectedDays
      // Map selectedDays indices to API day indices
      sunStart = selectedDays.contains(6) && startTimes[6] != null
          ? _formatTimeForAPI(startTimes[6]!)
          : defaultTime;
      sunEnd = selectedDays.contains(6) && endTimes[6] != null
          ? _formatTimeForAPI(endTimes[6]!)
          : defaultTime;

      monStart = selectedDays.contains(0) && startTimes[0] != null
          ? _formatTimeForAPI(startTimes[0]!)
          : defaultTime;
      monEnd = selectedDays.contains(0) && endTimes[0] != null
          ? _formatTimeForAPI(endTimes[0]!)
          : defaultTime;

      tueStart = selectedDays.contains(1) && startTimes[1] != null
          ? _formatTimeForAPI(startTimes[1]!)
          : defaultTime;
      tueEnd = selectedDays.contains(1) && endTimes[1] != null
          ? _formatTimeForAPI(endTimes[1]!)
          : defaultTime;

      wedStart = selectedDays.contains(2) && startTimes[2] != null
          ? _formatTimeForAPI(startTimes[2]!)
          : defaultTime;
      wedEnd = selectedDays.contains(2) && endTimes[2] != null
          ? _formatTimeForAPI(endTimes[2]!)
          : defaultTime;

      thuStart = selectedDays.contains(3) && startTimes[3] != null
          ? _formatTimeForAPI(startTimes[3]!)
          : defaultTime;
      thuEnd = selectedDays.contains(3) && endTimes[3] != null
          ? _formatTimeForAPI(endTimes[3]!)
          : defaultTime;

      friStart = selectedDays.contains(4) && startTimes[4] != null
          ? _formatTimeForAPI(startTimes[4]!)
          : defaultTime;
      friEnd = selectedDays.contains(4) && endTimes[4] != null
          ? _formatTimeForAPI(endTimes[4]!)
          : defaultTime;

      satStart = selectedDays.contains(5) && startTimes[5] != null
          ? _formatTimeForAPI(startTimes[5]!)
          : defaultTime;
      satEnd = selectedDays.contains(5) && endTimes[5] != null
          ? _formatTimeForAPI(endTimes[5]!)
          : defaultTime;
    } else {
      // Same time for all days
      final startTimeStr = _formatTimeForAPI(singleStartTime!);
      final endTimeStr = _formatTimeForAPI(singleEndTime!);

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

    // Trigger BLoC event - Create or Update based on mode
    if (widget.isEdit && _existingScheduleId != null) {
      _courseBloc.add(
        UpdateCourseScheduleEvent(
          groupId: widget.courseGroupId,
          courseId: widget.courseId,
          scheduleId: _existingScheduleId!,
          request: request,
        ),
      );
    } else {
      _courseBloc.add(
        CreateCourseScheduleEvent(
          groupId: widget.courseGroupId,
          courseId: widget.courseId,
          request: request,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _courseBloc,
      child: BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          // Handle course detail loading for edit mode
          if (state is CourseDetailLoading) {
            setState(() {
              _isLoadingCourse = true;
            });
          } else if (state is CourseDetailLoaded) {
            setState(() {
              _isLoadingCourse = false;
            });
            // Pre-fill form with schedule data
            _prefillSchedule(state.course);
          } else if (state is CourseDetailError) {
            setState(() {
              _isLoadingCourse = false;
            });
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load schedule: ${state.message}',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: redColor,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is CourseScheduleCreating ||
              state is CourseScheduleUpdating) {
            setState(() {
              _isCreating = true;
            });
          } else if (state is CourseScheduleCreated) {
            setState(() {
              _isCreating = false;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Schedule created successfully!',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: greenColor,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate to categories screen with course data
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.categoriesAddClass,
              arguments: {
                'courseId': widget.courseId,
                'courseGroupId': widget.courseGroupId,
                'isEdit':
                    false, // After creating schedule, go to create categories
              },
            );
          } else if (state is CourseScheduleUpdated) {
            setState(() {
              _isCreating = false;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Schedule updated successfully!',
                  style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                ),
                backgroundColor: greenColor,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate to categories screen with course data
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.categoriesAddClass,
              arguments: {
                'courseId': widget.courseId,
                'courseGroupId': widget.courseGroupId,
                'isEdit': true, // Stay in edit mode
              },
            );
          } else if (state is CourseScheduleCreateError ||
              state is CourseScheduleUpdateError) {
            setState(() {
              _isCreating = false;
            });

            // Get error message based on state type
            final errorTitle = state is CourseScheduleCreateError
                ? 'Failed to create schedule'
                : 'Failed to update schedule';
            final errorMessage = state is CourseScheduleCreateError
                ? state.message
                : (state as CourseScheduleUpdateError).message;

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorTitle,
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      errorMessage,
                      style: AppTextStyle.iTextStyle.copyWith(
                        color: whiteColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                backgroundColor: redColor,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: softGrey,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.v,
                      horizontal: 12.h,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(color: whiteColor),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.keyboard_arrow_left,
                            color: blackColor,
                          ),
                        ),
                        Text(
                          widget.isEdit ? 'Edit Class' : 'Add Class',
                          style: AppTextStyle.aTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.import_contacts, color: transparentColor),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.h,
                      vertical: 12.v,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 20.v,
                      ),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(16.adaptSize),
                        boxShadow: [
                          BoxShadow(
                            color: blackColor.withOpacity(0.06),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: EasyStepper(
                        activeStep: 1,
                        lineStyle: LineStyle(
                          lineLength: 60.h,
                          lineThickness: 3,
                          lineSpace: 4,
                          lineType: LineType.normal,
                          defaultLineColor: greyColor.withOpacity(0.3),
                          finishedLineColor: primaryColor,
                          activeLineColor: primaryColor,
                        ),
                        activeStepBorderColor: primaryColor,
                        activeStepIconColor: whiteColor,
                        activeStepBackgroundColor: primaryColor,
                        activeStepTextColor: primaryColor,
                        finishedStepBorderColor: primaryColor,
                        finishedStepBackgroundColor: primaryColor.withOpacity(
                          0.1,
                        ),
                        finishedStepIconColor: primaryColor,
                        finishedStepTextColor: blackColor,
                        unreachedStepBorderColor: greyColor.withOpacity(0.3),
                        unreachedStepBackgroundColor: softGrey,
                        unreachedStepIconColor: greyColor,
                        unreachedStepTextColor: textColor.withOpacity(0.5),
                        borderThickness: 2,
                        internalPadding: 12,
                        showLoadingAnimation: false,
                        stepRadius: 28.adaptSize,
                        showStepBorder: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.h,
                          vertical: 8.v,
                        ),
                        stepShape: StepShape.circle,
                        stepBorderRadius: 15,
                        steppingEnabled: true,
                        disableScroll: true,
                        onStepReached: (index) {
                          if (index == 0) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.addClassesScreen,
                              arguments: {
                                'courseGroupId': widget.courseGroupId,
                                'courseId': widget.courseId,
                                'isEdit': true,
                              },
                            );
                            return;
                          }

                          if (index == 1) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.scheduleAddClass,
                              arguments: {
                                'courseId': widget.courseId,
                                'courseGroupId': widget.courseGroupId,
                                'isEdit': true,
                              },
                            );
                            return;
                          }

                          if (index == 2) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.categoriesAddClass,
                              arguments: {
                                'courseId': widget.courseId,
                                'courseGroupId': widget.courseGroupId,
                                'isEdit': true,
                              },
                            );
                          }
                        },
                        steps: [
                          EasyStep(
                            customStep: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.1),
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.menu_book,
                                  color: primaryColor,
                                  size: 20.adaptSize,
                                ),
                              ),
                            ),
                            customTitle: Padding(
                              padding: EdgeInsets.only(top: 8.v),
                              child: Text(
                                'Details',
                                style: AppTextStyle.iTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.fSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            topTitle: false,
                          ),
                          EasyStep(
                            customStep: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.calendar_month,
                                  color: whiteColor,
                                  size: 20.adaptSize,
                                ),
                              ),
                            ),
                            customTitle: Padding(
                              padding: EdgeInsets.only(top: 8.v),
                              child: Text(
                                'Schedule',
                                style: AppTextStyle.iTextStyle.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.fSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            topTitle: false,
                          ),
                          EasyStep(
                            customStep: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.1),
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.category_outlined,
                                  color: primaryColor,
                                  size: 20.adaptSize,
                                ),
                              ),
                            ),
                            customTitle: Padding(
                              padding: EdgeInsets.only(top: 8.v),
                              child: Text(
                                'Categories',
                                style: AppTextStyle.iTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.fSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            topTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.h),
                    child: _isLoadingCourse
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 100.v),
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                    whiteColor,
                                  ),
                                  color: primaryColor,
                                ),
                                SizedBox(height: 16.v),
                                Text(
                                  'Loading schedule details...',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Schedule Toggle Card
                              Container(
                                padding: EdgeInsets.all(16.h),
                                decoration: BoxDecoration(
                                  color: whiteColor,
                                  borderRadius: BorderRadius.circular(
                                    12.adaptSize,
                                  ),
                                  border: Border.all(color: softGrey, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: blackColor.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: isSchedule,
                                        onChanged: (bool? newValue) {
                                          setState(() {
                                            isSchedule = newValue ?? false;
                                            if (!isSchedule) {
                                              selectedDays.clear();
                                              startTimes.clear();
                                              endTimes.clear();
                                            }
                                          });
                                        },
                                        activeColor: primaryColor,
                                        side: BorderSide(
                                          color: primaryColor,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.h),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Varies by day',
                                            style: AppTextStyle.cTextStyle
                                                .copyWith(
                                                  color: blackColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 28.v),
                              if (isSchedule) ...[
                                // Day Selection Section
                                Text(
                                  'Class Days',
                                  style: AppTextStyle.bTextStyle.copyWith(
                                    color: blackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.v),
                                SizedBox(
                                  height: 40.v,
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: listOfClassesSchedule.length,
                                    itemBuilder: (context, index) {
                                      bool isSelected = selectedDays.contains(
                                        index,
                                      );
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedDays.remove(index);
                                              startTimes.remove(index);
                                              endTimes.remove(index);
                                            } else {
                                              selectedDays.add(index);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.h,
                                            vertical: 8.v,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? primaryColor
                                                : softGrey,
                                            borderRadius: BorderRadius.circular(
                                              8.adaptSize,
                                            ),
                                            border: isSelected
                                                ? Border.all(
                                                    color: primaryColor,
                                                    width: 1.5,
                                                  )
                                                : Border.all(
                                                    color: greyColor
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: primaryColor
                                                          .withOpacity(0.2),
                                                      blurRadius: 6,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              listOfClassesSchedule[index],
                                              style: AppTextStyle.cTextStyle
                                                  .copyWith(
                                                    color: isSelected
                                                        ? whiteColor
                                                        : textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        SizedBox(width: 10.h),
                                  ),
                                ),
                                SizedBox(height: 28.v),
                                // Class Times Section
                                Text(
                                  'Class Times',
                                  style: AppTextStyle.bTextStyle.copyWith(
                                    color: blackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 16.v),
                                ...selectedDays.map((dayIndex) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12.v),
                                    padding: EdgeInsets.all(16.h),
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      borderRadius: BorderRadius.circular(
                                        10.adaptSize,
                                      ),
                                      border: Border.all(
                                        color: softGrey,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: blackColor.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getDayName(dayIndex),
                                          style: AppTextStyle.cTextStyle
                                              .copyWith(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(height: 12.v),
                                        Row(
                                          children: [
                                            // Start Time Picker
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _selectTime(dayIndex, true),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.h,
                                                    vertical: 10.v,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: softGrey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.adaptSize,
                                                        ),
                                                    border: Border.all(
                                                      color: greyColor
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        startTimes[dayIndex] !=
                                                                null
                                                            ? _formatTime(
                                                                startTimes[dayIndex]!,
                                                              )
                                                            : 'Start Time',
                                                        style: AppTextStyle
                                                            .iTextStyle
                                                            .copyWith(
                                                              color:
                                                                  startTimes[dayIndex] !=
                                                                      null
                                                                  ? blackColor
                                                                  : textColor
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                      Icon(
                                                        Icons.access_time,
                                                        color: primaryColor,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12.h),
                                            // End Time Picker
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => _selectTime(
                                                  dayIndex,
                                                  false,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.h,
                                                    vertical: 10.v,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: softGrey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.adaptSize,
                                                        ),
                                                    border: Border.all(
                                                      color: greyColor
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        endTimes[dayIndex] !=
                                                                null
                                                            ? _formatTime(
                                                                endTimes[dayIndex]!,
                                                              )
                                                            : 'End Time',
                                                        style: AppTextStyle
                                                            .iTextStyle
                                                            .copyWith(
                                                              color:
                                                                  endTimes[dayIndex] !=
                                                                      null
                                                                  ? blackColor
                                                                  : textColor
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                      Icon(
                                                        Icons.access_time,
                                                        color: primaryColor,
                                                        size: 18,
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
                                // Single Time Section
                                Text(
                                  'Class Time',
                                  style: AppTextStyle.bTextStyle.copyWith(
                                    color: blackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 16.v),
                                Container(
                                  padding: EdgeInsets.all(16.h),
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(
                                      10.adaptSize,
                                    ),
                                    border: Border.all(
                                      color: softGrey,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: blackColor.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: Offset(0, 1),
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
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.h,
                                              vertical: 10.v,
                                            ),
                                            decoration: BoxDecoration(
                                              color: softGrey,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    8.adaptSize,
                                                  ),
                                              border: Border.all(
                                                color: greyColor.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  singleStartTime != null
                                                      ? _formatTime(
                                                          singleStartTime!,
                                                        )
                                                      : 'Start Time',
                                                  style: AppTextStyle.iTextStyle
                                                      .copyWith(
                                                        color:
                                                            singleStartTime !=
                                                                null
                                                            ? blackColor
                                                            : textColor
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                Icon(
                                                  Icons.access_time,
                                                  color: primaryColor,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.h),
                                      // End Time
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _selectSingleTime(false),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.h,
                                              vertical: 10.v,
                                            ),
                                            decoration: BoxDecoration(
                                              color: softGrey,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    8.adaptSize,
                                                  ),
                                              border: Border.all(
                                                color: greyColor.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  singleEndTime != null
                                                      ? _formatTime(
                                                          singleEndTime!,
                                                        )
                                                      : 'End Time',
                                                  style: AppTextStyle.iTextStyle
                                                      .copyWith(
                                                        color:
                                                            singleEndTime !=
                                                                null
                                                            ? blackColor
                                                            : textColor
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                Icon(
                                                  Icons.access_time,
                                                  color: primaryColor,
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
                              SizedBox(height: 32.v),
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _isCreating
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    whiteColor,
                                                  ),
                                              color: primaryColor,
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed:
                                                _validateAndCreateSchedule,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12.v,
                                              ),
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      8.adaptSize,
                                                    ),
                                              ),
                                            ),
                                            child: Text(
                                              'Save',
                                              style: AppTextStyle.cTextStyle
                                                  .copyWith(
                                                    color: whiteColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.v),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _getDayName(int index) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[index];
}
