// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
  final serverDateFormat = DateFormat('HH:mm:ss');

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
      id: json['id'] ?? 0,
      daysOfWeek: json['days_of_week'] ?? '',
      sunStartTime: json['sun_start_time'] ?? '',
      sunEndTime: json['sun_end_time'] ?? '',
      monStartTime: json['mon_start_time'] ?? '',
      monEndTime: json['mon_end_time'] ?? '',
      tueStartTime: json['tue_start_time'] ?? '',
      tueEndTime: json['tue_end_time'] ?? '',
      wedStartTime: json['wed_start_time'] ?? '',
      wedEndTime: json['wed_end_time'] ?? '',
      thuStartTime: json['thu_start_time'] ?? '',
      thuEndTime: json['thu_end_time'] ?? '',
      friStartTime: json['fri_start_time'] ?? '',
      friEndTime: json['fri_end_time'] ?? '',
      satStartTime: json['sat_start_time'] ?? '',
      satEndTime: json['sat_end_time'] ?? '',
      course: json['course'] ?? 0,
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

  // Helper method to get active days
  List<String> getActiveDays() {
    List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<String> activeDays = [];

    for (int i = 0; i < daysOfWeek.length && i < days.length; i++) {
      if (daysOfWeek[i] == '1') {
        activeDays.add(days[i]);
      }
    }

    return activeDays;
  }

  // Helper method to get time for a specific day
  String getTimeForDay(String day) {
    String startTime = '';
    String endTime = '';

    switch (day.toLowerCase()) {
      case 'sun':
      case 'sunday':
        startTime = sunStartTime;
        endTime = sunEndTime;
        break;
      case 'mon':
      case 'monday':
        startTime = monStartTime;
        endTime = monEndTime;
        break;
      case 'tue':
      case 'tuesday':
        startTime = tueStartTime;
        endTime = tueEndTime;
        break;
      case 'wed':
      case 'wednesday':
        startTime = wedStartTime;
        endTime = wedEndTime;
        break;
      case 'thu':
      case 'thursday':
        startTime = thuStartTime;
        endTime = thuEndTime;
        break;
      case 'fri':
      case 'friday':
        startTime = friStartTime;
        endTime = friEndTime;
        break;
      case 'sat':
      case 'saturday':
        startTime = satStartTime;
        endTime = satEndTime;
        break;
    }

    startTime = DateFormat('hh:mm a').format(serverDateFormat.parse(startTime));
    endTime = DateFormat('hh:mm a').format(serverDateFormat.parse(endTime));

    return '$startTime - $endTime';
  }
}
