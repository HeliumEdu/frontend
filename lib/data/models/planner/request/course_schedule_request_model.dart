// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class CourseScheduleRequestModel {
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

  CourseScheduleRequestModel({
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
  });

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}
