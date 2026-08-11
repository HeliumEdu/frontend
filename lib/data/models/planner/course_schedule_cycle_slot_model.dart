// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

/// One `cycle_slots` entry on a day-cycle [CourseScheduleModel]: the 1-based
/// cycle-day indices that share a meeting time, plus that time.
class CourseScheduleCycleSlotModel {
  final List<int> indices;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  CourseScheduleCycleSlotModel({
    required this.indices,
    required this.startTime,
    required this.endTime,
  });

  factory CourseScheduleCycleSlotModel.fromJson(Map<String, dynamic> json) {
    return CourseScheduleCycleSlotModel(
      indices: (json['indices'] as List<dynamic>)
          .map((index) => index as int)
          .toList(),
      startTime: HeliumTime.parse(json['start_time'] as String)!,
      endTime: HeliumTime.parse(json['end_time'] as String)!,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'indices': indices,
      'start_time': HeliumTime.formatForApi(startTime),
      'end_time': HeliumTime.formatForApi(endTime),
    };
  }
}
