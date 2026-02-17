// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';

class NotificationModel extends BaseModel {
  final String title;
  final String body;
  final String timestamp;
  final bool isRead;
  final ReminderModel reminder;
  final CourseModel? course;
  final Color? color;

  NotificationModel({
    required super.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.reminder,
    this.course,
    this.color,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'is_read': isRead,
      'color': color,
      'reminder': reminder.toJson(),
    };

    if (course != null) data['course'] = course!.toJson();

    return data;
  }
}
