// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';
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
    };
  }

  bool allDaysSameTime() {
    return (_timeEquals(sunStartTime, monStartTime) &&
            _timeEquals(sunStartTime, tueStartTime) &&
            _timeEquals(sunStartTime, wedStartTime) &&
            _timeEquals(sunStartTime, thuStartTime) &&
            _timeEquals(sunStartTime, friStartTime) &&
            _timeEquals(sunStartTime, satStartTime)) &&
        (_timeEquals(sunEndTime, monEndTime) &&
            _timeEquals(sunEndTime, tueEndTime) &&
            _timeEquals(sunEndTime, wedEndTime) &&
            _timeEquals(sunEndTime, thuEndTime) &&
            _timeEquals(sunEndTime, friEndTime) &&
            _timeEquals(sunEndTime, satEndTime));
  }

  bool _timeEquals(TimeOfDay a, TimeOfDay b) {
    return a.hour == b.hour && a.minute == b.minute;
  }

  /// Checks if the given day index (0=Sun, 6=Sat) is active in the schedule.
  bool isDayActive(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= daysOfWeek.length) {
      return false;
    }
    return daysOfWeek[dayIndex] == '1';
  }

  /// Gets the list of active day indices (0=Sun, 6=Sat).
  Set<int> getActiveDayIndices() {
    final Set<int> indices = {};
    for (int i = 0; i < daysOfWeek.length; i++) {
      if (daysOfWeek[i] == '1') {
        indices.add(i);
      }
    }
    return indices;
  }

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

  /// Gets the start time for a specific day index (0=Sun, 6=Sat).
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

  /// Gets the end time for a specific day index (0=Sun, 6=Sat).
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
