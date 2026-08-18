// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_cycle_slot_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_recurrence_group_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class CourseScheduleModel extends BaseModel {
  final String daysOfWeek;
  final TimeOfDay sunStartTime;
  final TimeOfDay sunEndTime;
  final TimeOfDay monStartTime;
  final TimeOfDay monEndTime;
  final TimeOfDay tueStartTime;
  final TimeOfDay tueEndTime;
  final TimeOfDay wedStartTime;
  final TimeOfDay wedEndTime;
  final TimeOfDay thuStartTime;
  final TimeOfDay thuEndTime;
  final TimeOfDay friStartTime;
  final TimeOfDay friEndTime;
  final TimeOfDay satStartTime;
  final TimeOfDay satEndTime;
  final int course;

  /// Optional per-schedule date window. Null means the schedule inherits the
  /// parent course's dates.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Rotating-schedule config, mutually exclusive by shape: a day cycle sets
  /// `cycleLength`/`anchorDate`/`cycleSlots`, a week-based rotation sets
  /// `isWeekBased`/`weekOffset`/`anchorDate`. `template` is the preset (null for
  /// plain weekly or Custom).
  final int? template;
  final int? cycleLength;
  final DateTime? anchorDate;
  final List<CourseScheduleCycleSlotModel> cycleSlots;
  final bool isWeekBased;
  final int? weekOffset;

  final List<CourseScheduleRecurrenceGroupModel> recurrenceGroups;

  CourseScheduleModel({
    required super.id,
    required this.daysOfWeek,
    required this.sunStartTime,
    required this.sunEndTime,
    required this.monStartTime,
    required this.monEndTime,
    required this.tueStartTime,
    required this.tueEndTime,
    required this.wedStartTime,
    required this.wedEndTime,
    required this.thuStartTime,
    required this.thuEndTime,
    required this.friStartTime,
    required this.friEndTime,
    required this.satStartTime,
    required this.satEndTime,
    required this.course,
    this.startDate,
    this.endDate,
    this.template,
    this.cycleLength,
    this.anchorDate,
    this.cycleSlots = const [],
    this.isWeekBased = false,
    this.weekOffset,
    this.recurrenceGroups = const [],
  });

  factory CourseScheduleModel.fromJson(Map<String, dynamic> json) {
    return CourseScheduleModel(
      id: json['id'],
      daysOfWeek: json['days_of_week'],
      sunStartTime: HeliumTime.parse(json['sun_start_time'] as String)!,
      sunEndTime: HeliumTime.parse(json['sun_end_time'] as String)!,
      monStartTime: HeliumTime.parse(json['mon_start_time'] as String)!,
      monEndTime: HeliumTime.parse(json['mon_end_time'] as String)!,
      tueStartTime: HeliumTime.parse(json['tue_start_time'] as String)!,
      tueEndTime: HeliumTime.parse(json['tue_end_time'] as String)!,
      wedStartTime: HeliumTime.parse(json['wed_start_time'] as String)!,
      wedEndTime: HeliumTime.parse(json['wed_end_time'] as String)!,
      thuStartTime: HeliumTime.parse(json['thu_start_time'] as String)!,
      thuEndTime: HeliumTime.parse(json['thu_end_time'] as String)!,
      friStartTime: HeliumTime.parse(json['fri_start_time'] as String)!,
      friEndTime: HeliumTime.parse(json['fri_end_time'] as String)!,
      satStartTime: HeliumTime.parse(json['sat_start_time'] as String)!,
      satEndTime: HeliumTime.parse(json['sat_end_time'] as String)!,
      course: json['course'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      template: json['template'] as int?,
      cycleLength: json['cycle_length'] as int?,
      anchorDate: json['anchor_date'] != null
          ? DateTime.parse(json['anchor_date'] as String)
          : null,
      cycleSlots: (json['cycle_slots'] as List<dynamic>? ?? const [])
          .map(
            (slot) => CourseScheduleCycleSlotModel.fromJson(
              slot as Map<String, dynamic>,
            ),
          )
          .toList(),
      isWeekBased: json['is_week_based'] as bool? ?? false,
      weekOffset: json['week_offset'] as int?,
      recurrenceGroups:
          (json['recurrence_groups'] as List<dynamic>? ?? const [])
              .map(
                (group) => CourseScheduleRecurrenceGroupModel.fromJson(
                  group as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'days_of_week': daysOfWeek,
      'sun_start_time': HeliumTime.formatForApi(sunStartTime),
      'sun_end_time': HeliumTime.formatForApi(sunEndTime),
      'mon_start_time': HeliumTime.formatForApi(monStartTime),
      'mon_end_time': HeliumTime.formatForApi(monEndTime),
      'tue_start_time': HeliumTime.formatForApi(tueStartTime),
      'tue_end_time': HeliumTime.formatForApi(tueEndTime),
      'wed_start_time': HeliumTime.formatForApi(wedStartTime),
      'wed_end_time': HeliumTime.formatForApi(wedEndTime),
      'thu_start_time': HeliumTime.formatForApi(thuStartTime),
      'thu_end_time': HeliumTime.formatForApi(thuEndTime),
      'fri_start_time': HeliumTime.formatForApi(friStartTime),
      'fri_end_time': HeliumTime.formatForApi(friEndTime),
      'sat_start_time': HeliumTime.formatForApi(satStartTime),
      'sat_end_time': HeliumTime.formatForApi(satEndTime),
      'course': course,
      'start_date':
          startDate != null ? HeliumDateTime.formatDateForApi(startDate!) : null,
      'end_date':
          endDate != null ? HeliumDateTime.formatDateForApi(endDate!) : null,
      'template': template,
      'cycle_length': cycleLength,
      'anchor_date': anchorDate != null
          ? HeliumDateTime.formatDateForApi(anchorDate!)
          : null,
      'cycle_slots': cycleSlots.map((slot) => slot.toJson()).toList(),
      'is_week_based': isWeekBased,
      'week_offset': weekOffset,
    };
  }

  /// Whether every active day shares one start/end time. Inactive days are
  /// ignored: their `00:00` is a placeholder, not a meeting time.
  bool allDaysSameTime() {
    final activeDays = getActiveDayIndices().toList();
    if (activeDays.length <= 1) return true;

    final firstStart = getStartTimeForDayIndex(activeDays.first);
    final firstEnd = getEndTimeForDayIndex(activeDays.first);
    return activeDays.every(
      (day) =>
          _timeEquals(getStartTimeForDayIndex(day), firstStart) &&
          _timeEquals(getEndTimeForDayIndex(day), firstEnd),
    );
  }

  bool _timeEquals(TimeOfDay a, TimeOfDay b) {
    return a.hour == b.hour && a.minute == b.minute;
  }

  /// The earliest active day's start/end — the single time to show for a uniform
  /// schedule. Reads the first active day rather than a fixed column (whose
  /// `00:00` placeholder would mislead), and is null when no day is active.
  TimeOfDay? get representativeStartTime {
    final firstDay = getActiveDayIndices().firstOrNull;
    return firstDay == null ? null : getStartTimeForDayIndex(firstDay);
  }

  TimeOfDay? get representativeEndTime {
    final firstDay = getActiveDayIndices().firstOrNull;
    return firstDay == null ? null : getEndTimeForDayIndex(firstDay);
  }

  /// Checks if the given day index (0=Sun, 6=Sat) is active in the schedule
  bool isDayActive(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= daysOfWeek.length) {
      return false;
    }
    return daysOfWeek[dayIndex] == '1';
  }

  /// Gets the list of active day indices (0=Sun, 6=Sat)
  Set<int> getActiveDayIndices() {
    final Set<int> indices = {};
    for (int i = 0; i < daysOfWeek.length; i++) {
      if (daysOfWeek[i] == '1') {
        indices.add(i);
      }
    }
    return indices;
  }

  String? overrideDateRangeLabel() {
    if (startDate == null && endDate == null) {
      return null;
    }
    if (startDate != null && endDate != null) {
      return '${HeliumDateTime.formatDate(startDate!)} to ${HeliumDateTime.formatDate(endDate!)}';
    }
    if (startDate != null) {
      return 'From ${HeliumDateTime.formatDate(startDate!)}';
    }
    return 'Until ${HeliumDateTime.formatDate(endDate!)}';
  }

  bool get isDayCycle => cycleLength != null;
  bool get isRotating => isDayCycle || isWeekBased;

  /// Cycle-day labels ("Day 1") grouped by shared meeting-time range.
  Map<String, List<String>> cycleGroupsByTime() {
    final Map<String, List<String>> byTime = {};
    for (final slot in cycleSlots) {
      final timeRange = HeliumTime.formatTimeRange(slot.startTime, slot.endTime);
      final sortedIndices = slot.indices.toList()..sort();
      for (final index in sortedIndices) {
        byTime.putIfAbsent(timeRange, () => []).add('Day $index');
      }
    }
    return byTime;
  }

  /// Active weekdays grouped by shared meeting-time range.
  Map<String, List<String>> weeklyGroupsByTime() {
    final Map<String, List<String>> byTime = {};
    for (final day in getActiveDays()) {
      final timeRange = HeliumTime.formatTimeRange(
        getStartTimeForDay(day),
        getEndTimeForDay(day),
      );
      byTime.putIfAbsent(timeRange, () => []).add(day);
    }
    return byTime;
  }

  /// Meeting-day labels grouped by shared time: cycle days if rotating, else weekdays.
  Map<String, List<String>> groupsByTime() =>
      isDayCycle ? cycleGroupsByTime() : weeklyGroupsByTime();

  // Helper method to get active days as abbreviated names
  List<String> getActiveDays() {
    final List<String> activeDays = [];

    for (
      int i = 0;
      i < daysOfWeek.length && i < CalendarConstants.dayNamesAbbrev.length;
      i++
    ) {
      if (isDayActive(i)) {
        activeDays.add(CalendarConstants.dayNamesAbbrev[i]);
      }
    }

    return activeDays;
  }

  TimeOfDay getStartTimeForDay(String day) {
    TimeOfDay startTime;

    switch (day.toLowerCase()) {
      case 'sun':
      case 'sunday':
        startTime = sunStartTime;
        break;
      case 'mon':
      case 'monday':
        startTime = monStartTime;
        break;
      case 'tue':
      case 'tuesday':
        startTime = tueStartTime;
        break;
      case 'wed':
      case 'wednesday':
        startTime = wedStartTime;
        break;
      case 'thu':
      case 'thursday':
        startTime = thuStartTime;
        break;
      case 'fri':
      case 'friday':
        startTime = friStartTime;
        break;
      case 'sat':
      case 'saturday':
        startTime = satStartTime;
        break;
      default:
        startTime = sunStartTime;
    }

    return startTime;
  }

  TimeOfDay getEndTimeForDay(String day) {
    TimeOfDay endTime;

    switch (day.toLowerCase()) {
      case 'sun':
      case 'sunday':
        endTime = sunEndTime;
        break;
      case 'mon':
      case 'monday':
        endTime = monEndTime;
        break;
      case 'tue':
      case 'tuesday':
        endTime = tueEndTime;
        break;
      case 'wed':
      case 'wednesday':
        endTime = wedEndTime;
        break;
      case 'thu':
      case 'thursday':
        endTime = thuEndTime;
        break;
      case 'fri':
      case 'friday':
        endTime = friEndTime;
        break;
      case 'sat':
      case 'saturday':
        endTime = satEndTime;
        break;
      default:
        endTime = sunEndTime;
    }

    return endTime;
  }

  /// Gets the start time for a specific day index (0=Sun, 6=Sat)
  TimeOfDay getStartTimeForDayIndex(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return sunStartTime;
      case 1:
        return monStartTime;
      case 2:
        return tueStartTime;
      case 3:
        return wedStartTime;
      case 4:
        return thuStartTime;
      case 5:
        return friStartTime;
      case 6:
        return satStartTime;
      default:
        return sunStartTime;
    }
  }

  /// Gets the end time for a specific day index (0=Sun, 6=Sat)
  TimeOfDay getEndTimeForDayIndex(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return sunEndTime;
      case 1:
        return monEndTime;
      case 2:
        return tueEndTime;
      case 3:
        return wedEndTime;
      case 4:
        return thuEndTime;
      case 5:
        return friEndTime;
      case 6:
        return satEndTime;
      default:
        return sunEndTime;
    }
  }
}
