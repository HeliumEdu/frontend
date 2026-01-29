// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:intl/intl.dart';

class CourseScheduleModel {
  final int id;
  final String daysOfWeek;
  final String sunStartTime;
  final String sunEndTime;
  final String monStartTime;
  final String monEndTime;
  final String tueStartTime;
  final String tueEndTime;
  final String wedStartTime;
  final String wedEndTime;
  final String thuStartTime;
  final String thuEndTime;
  final String friStartTime;
  final String friEndTime;
  final String satStartTime;
  final String satEndTime;
  final int course;
  final serverTimeFormat = DateFormat('HH:mm:ss');

  CourseScheduleModel({
    required this.id,
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
      sunStartTime: json['sun_start_time'],
      sunEndTime: json['sun_end_time'],
      monStartTime: json['mon_start_time'],
      monEndTime: json['mon_end_time'],
      tueStartTime: json['tue_start_time'],
      tueEndTime: json['tue_end_time'],
      wedStartTime: json['wed_start_time'],
      wedEndTime: json['wed_end_time'],
      thuStartTime: json['thu_start_time'],
      thuEndTime: json['thu_end_time'],
      friStartTime: json['fri_start_time'],
      friEndTime: json['fri_end_time'],
      satStartTime: json['sat_start_time'],
      satEndTime: json['sat_end_time'],
      course: json['course'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'days_of_week': daysOfWeek,
      'sun_start_time': sunStartTime,
      'sun_end_time': sunEndTime,
      'mon_start_time': monStartTime,
      'mon_end_time': monEndTime,
      'tue_start_time': tueStartTime,
      'tue_end_time': tueEndTime,
      'wed_start_time': wedStartTime,
      'wed_end_time': wedEndTime,
      'thu_start_time': thuStartTime,
      'thu_end_time': thuEndTime,
      'fri_start_time': friStartTime,
      'fri_end_time': friEndTime,
      'sat_start_time': satStartTime,
      'sat_end_time': satEndTime,
      'course': course,
    };
  }

  bool allDaysSameTime() {
    return (sunStartTime == monStartTime &&
            sunStartTime == tueStartTime &&
            sunStartTime == wedStartTime &&
            sunStartTime == thuStartTime &&
            sunStartTime == friStartTime &&
            sunStartTime == satStartTime) &&
        (sunEndTime == monEndTime &&
            sunEndTime == tueEndTime &&
            sunEndTime == wedEndTime &&
            sunEndTime == thuEndTime &&
            sunEndTime == friEndTime &&
            sunEndTime == satEndTime);
  }

  // Helper method to get active days
  List<String> getActiveDays() {
    final List<String> activeDays = [];

    for (
      int i = 0;
      i < daysOfWeek.length && i < CalendarConstants.dayNamesAbbrev.length;
      i++
    ) {
      if (daysOfWeek[i] == '1') {
        activeDays.add(CalendarConstants.dayNamesAbbrev[i]);
      }
    }

    return activeDays;
  }

  DateTime getStartTimeForDay(String day) {
    String startTime = '';

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
    }

    return serverTimeFormat.parse(startTime);
  }

  DateTime getEndTimeForDay(String day) {
    String endTime = '';

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
    }

    return serverTimeFormat.parse(endTime);
  }

  String getDateTimeRangeForDisplay(String day) {
    final startTime = HeliumDateTime.formatTimeForDisplay(getStartTimeForDay(day));
    final endTime = HeliumDateTime.formatTimeForDisplay(getEndTimeForDay(day));

    return '$startTime - $endTime';
  }
}
